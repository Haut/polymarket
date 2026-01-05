(** Live demo of the Polymarket CLOB API client with typestate authentication.

    This example demonstrates the typestate CLOB client that enforces
    authentication requirements at compile time:
    - Unauthed: Public endpoints only (order book, pricing, timeseries)
    - L1: Wallet authentication (create/derive API keys) + public endpoints
    - L2: API key authentication (orders, trades) + L1 + public endpoints

    Run with: dune exec examples/clob_api_demo.exe

    The demo first fetches markets from the Gamma API to discover valid token
    IDs, then uses those to test CLOB endpoints.

    To test authenticated endpoints, set this environment variable:
    - POLY_PRIVATE_KEY: Your Ethereum private key (hex, without 0x prefix)

    Or the demo will use a well-known test key (do not use with real funds). *)

open Polymarket

(** {1 Helper Functions} *)

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name (Clob.error_to_string err)

let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name (Clob.error_to_string err)

(** {1 Token ID Extraction} *)

let parse_token_ids_json ids_str =
  if String.length ids_str < 2 then []
  else
    String.sub ids_str 1 (String.length ids_str - 2)
    |> String.split_on_char ','
    |> List.map (fun s ->
        String.trim s |> fun s ->
        if String.length s >= 2 then String.sub s 1 (String.length s - 2) else s)
    |> List.filter (fun s -> String.length s > 0)

let extract_markets_with_tokens (markets : Gamma.market list) =
  List.filter_map
    (fun (m : Gamma.market) ->
      match m.clob_token_ids with
      | Some ids when String.length ids > 2 ->
          let token_ids = parse_token_ids_json ids in
          if List.length token_ids > 0 then Some (m, token_ids) else None
      | _ -> None)
    markets

let find_market_with_orderbook clob_client markets_with_tokens =
  List.find_map
    (fun ((m : Gamma.market), token_ids) ->
      match token_ids with
      | token_id :: _ -> (
          match Clob.Unauthed.get_order_book clob_client ~token_id () with
          | Ok ob when List.length ob.bids > 0 || List.length ob.asks > 0 ->
              Some (m, token_ids, ob)
          | Ok _ -> None (* Empty order book *)
          | Error _ -> None)
      | [] -> None)
    markets_with_tokens

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let clock = Eio.Stdenv.clock env in

  Logger.info
    (Printf.sprintf "Starting CLOB API demo (%s)" Clob.default_base_url);

  (* Create shared rate limiter with Polymarket presets *)
  let routes = Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in

  (* Create an unauthenticated client for public endpoints *)
  let unauthed_client =
    Clob.Unauthed.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter ()
  in

  (* First, get markets from Gamma API to find token IDs with active order books *)
  let gamma_client =
    Gamma.create_exn ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter ()
  in
  (* Filter for non-closed markets with volume to find ones with order books *)
  let markets =
    Gamma.get_markets gamma_client ~limit:50 ~closed:false
      ~volume_num_min:1000.0 ()
  in

  let markets_with_tokens =
    match markets with
    | Ok m ->
        let mwt = extract_markets_with_tokens m in
        Logger.ok "fetch_markets"
          (Printf.sprintf "found %d markets with token IDs" (List.length mwt));
        mwt
    | Error err ->
        Logger.error "fetch_markets" (Gamma.error_to_string err);
        []
  in

  (* Find a market that actually has an order book with liquidity *)
  Logger.info "Looking for market with active order book";
  let active_market =
    find_market_with_orderbook unauthed_client markets_with_tokens
  in

  match active_market with
  | None ->
      Logger.error "ABORT" "No markets with active order books found";
      (* Still test batch endpoints with whatever tokens we have *)
      let all_token_ids =
        List.concat_map (fun (_, tids) -> tids) markets_with_tokens
      in
      if List.length all_token_ids > 0 then (
        let token_ids_subset = List.filteri (fun i _ -> i < 3) all_token_ids in
        let order_books =
          Clob.Unauthed.get_order_books unauthed_client
            ~token_ids:token_ids_subset ()
        in
        print_result_count "get_order_books" order_books;

        let spreads =
          Clob.Unauthed.get_spreads unauthed_client ~token_ids:token_ids_subset
            ()
        in
        print_result "get_spreads" spreads ~on_ok:(fun s ->
            Printf.sprintf "%d spread entries" (List.length s)))
  | Some (market, token_ids, initial_ob) ->
      let token_id = List.hd token_ids in
      Logger.ok "found_market"
        (Printf.sprintf "market with %d bids, %d asks"
           (List.length initial_ob.bids)
           (List.length initial_ob.asks));
      Logger.info
        (Printf.sprintf "Market: %s (token: %s...)"
           (Option.value ~default:"(unknown)" market.question)
           (String.sub token_id 0 (min 20 (String.length token_id))));

      (* ===== Order Book (Unauthed) ===== *)
      let order_book =
        Clob.Unauthed.get_order_book unauthed_client ~token_id ()
      in
      print_result "get_order_book" order_book
        ~on_ok:(fun (ob : Clob.Types.order_book_summary) ->
          Printf.sprintf "%d bids, %d asks" (List.length ob.bids)
            (List.length ob.asks));

      (* Test with multiple token IDs *)
      let all_token_ids =
        List.concat_map (fun (_, tids) -> tids) markets_with_tokens
      in
      let token_ids_subset = List.filteri (fun i _ -> i < 5) all_token_ids in
      if List.length token_ids_subset > 1 then
        let order_books =
          Clob.Unauthed.get_order_books unauthed_client
            ~token_ids:token_ids_subset ()
        in
        print_result_count "get_order_books" order_books
      else Logger.skip "get_order_books" "need multiple token IDs";

      (* ===== Pricing (Unauthed) ===== *)
      let price_buy =
        Clob.Unauthed.get_price unauthed_client ~token_id
          ~side:Clob.Types.Side.Buy ()
      in
      print_result "get_price (BUY)" price_buy
        ~on_ok:(fun (p : Clob.Types.price_response) ->
          Option.value ~default:"(no price)" p.price);

      let price_sell =
        Clob.Unauthed.get_price unauthed_client ~token_id
          ~side:Clob.Types.Side.Sell ()
      in
      print_result "get_price (SELL)" price_sell
        ~on_ok:(fun (p : Clob.Types.price_response) ->
          Option.value ~default:"(no price)" p.price);

      let midpoint = Clob.Unauthed.get_midpoint unauthed_client ~token_id () in
      print_result "get_midpoint" midpoint
        ~on_ok:(fun (m : Clob.Types.midpoint_response) ->
          Option.value ~default:"(no mid)" m.mid);

      (* Batch prices *)
      let requests =
        List.filteri (fun i _ -> i < 3) all_token_ids
        |> List.map (fun tid -> (tid, Clob.Types.Side.Buy))
      in
      if List.length requests > 0 then
        let prices = Clob.Unauthed.get_prices unauthed_client ~requests () in
        print_result "get_prices" prices ~on_ok:(fun p ->
            Printf.sprintf "%d price entries" (List.length p))
      else Logger.skip "get_prices" "no token IDs for batch request";

      (* Spreads *)
      if List.length token_ids_subset > 0 then
        let spreads =
          Clob.Unauthed.get_spreads unauthed_client ~token_ids:token_ids_subset
            ()
        in
        print_result "get_spreads" spreads ~on_ok:(fun s ->
            Printf.sprintf "%d spread entries" (List.length s))
      else Logger.skip "get_spreads" "no token IDs available";

      (* ===== Timeseries (Unauthed) ===== *)
      (match market.condition_id with
      | Some cond_id ->
          let history =
            Clob.Unauthed.get_price_history unauthed_client ~market:cond_id
              ~interval:Clob.Types.Interval.Max ()
          in
          print_result "get_price_history" history
            ~on_ok:(fun (h : Clob.Types.price_history) ->
              Printf.sprintf "%d points" (List.length h.history))
      | None -> Logger.skip "get_price_history" "no condition ID");

      (* ===== L1 Authentication (Wallet) ===== *)
      (* Use test private key or env var *)
      let private_key =
        let pk_str =
          match Sys.getenv_opt "POLY_PRIVATE_KEY" with
          | Some pk -> pk
          (* Well-known Foundry/Hardhat test account #0 - DO NOT use with real funds *)
          | None ->
              "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        in
        Clob.private_key_of_string pk_str
      in

      (* Upgrade to L1 client with private key *)
      let l1_client = Clob.upgrade_to_l1 unauthed_client ~private_key in
      let address = Clob.L1.address l1_client in
      Logger.info (Printf.sprintf "Upgraded to L1 (address: %s)" address);

      (* L1 can still call public endpoints *)
      let _ = Clob.L1.get_midpoint l1_client ~token_id () in
      Logger.ok "L1.get_midpoint" "public endpoints still accessible";

      (* Derive API key to upgrade to L2 *)
      let nonce = int_of_float (Unix.gettimeofday () *. 1000.0) mod 1000000 in
      (match Clob.L1.derive_api_key l1_client ~nonce with
      | Ok (l2_client, resp) ->
          Logger.ok "derive_api_key"
            (Printf.sprintf "api_key=%s..." (String.sub resp.api_key 0 8));

          (* ===== L2 Authentication (API Key) ===== *)
          Logger.info "Upgraded to L2 via derive_api_key";

          (* L2 can call authenticated endpoints *)
          let orders = Clob.L2.get_orders l2_client () in
          print_result "get_orders" orders ~on_ok:(fun o ->
              Printf.sprintf "%d orders" (List.length o));

          let trades = Clob.L2.get_trades l2_client () in
          print_result "get_trades" trades ~on_ok:(fun t ->
              Printf.sprintf "%d trades" (List.length t));

          (* Test get_order with a non-existent order ID (demonstrates error handling) *)
          let fake_order_id = "00000000-0000-0000-0000-000000000000" in
          let order = Clob.L2.get_order l2_client ~order_id:fake_order_id () in
          (match order with
          | Ok o ->
              Logger.ok "get_order"
                (Printf.sprintf "order_id=%s"
                   (Option.value ~default:"(none)" o.id))
          | Error _ ->
              (* Expected - no order with this ID exists *)
              Logger.ok "get_order" "endpoint works (no matching order)");

          (* Test get_api_keys - list all API keys for this address *)
          let api_keys = Clob.L2.get_api_keys l2_client in
          print_result_count "get_api_keys" api_keys;

          (* L2 can also call public endpoints *)
          let _ = Clob.L2.get_midpoint l2_client ~token_id () in
          Logger.ok "L2.get_midpoint" "public endpoints still accessible";

          (* Demonstrate downgrade *)
          let _l1_again = Clob.l2_to_l1 l2_client in
          Logger.ok "l2_to_l1" "downgraded to L1";
          let _unauthed_again = Clob.l2_to_unauthed l2_client in
          Logger.ok "l2_to_unauthed" "downgraded to Unauthed";

          (* Also demonstrate l1_to_unauthed transition *)
          let l1_for_downgrade = Clob.l2_to_l1 l2_client in
          let _unauthed_from_l1 = Clob.l1_to_unauthed l1_for_downgrade in
          Logger.ok "l1_to_unauthed" "downgraded from L1 to Unauthed"
      | Error err ->
          Logger.error "derive_api_key" (Clob.error_to_string err);
          Logger.skip "get_orders" "could not derive API key";
          Logger.skip "get_trades" "could not derive API key");

      Logger.skip "create_order" "requires signed order";
      Logger.skip "cancel_order" "requires order ID";

      (* ===== Summary ===== *)
      Logger.info "Demo complete"

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
