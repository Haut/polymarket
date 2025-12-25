(** Live demo of the Polymarket CLOB API client.

    This example calls all read-only CLOB API endpoints and prints the results.
    Run with: dune exec examples/clob_api_demo.exe

    The demo first fetches markets from the Gamma API to discover valid token
    IDs, then uses those to test CLOB endpoints.

    To test authenticated endpoints, set these environment variables:
    - POLY_PRIVATE_KEY: Your Ethereum private key (hex, without 0x prefix)
    - POLY_ADDRESS: Your Ethereum address (hex, with 0x prefix)

    Or use derive_api_key/create_api_key to get credentials from a private key.
*)

open Polymarket

(** {1 Helper Functions} *)

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name err.Http_client.Client.error

let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name err.Http_client.Client.error

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

let extract_markets_with_tokens (markets : Gamma_api.Types.market list) =
  List.filter_map
    (fun (m : Gamma_api.Types.market) ->
      match m.clob_token_ids with
      | Some ids when String.length ids > 2 ->
          let token_ids = parse_token_ids_json ids in
          if List.length token_ids > 0 then Some (m, token_ids) else None
      | _ -> None)
    markets

let find_market_with_orderbook clob_client markets_with_tokens =
  List.find_map
    (fun ((m : Gamma_api.Types.market), token_ids) ->
      match token_ids with
      | token_id :: _ -> (
          match Clob_api.Client.get_order_book clob_client ~token_id () with
          | Ok ob when List.length ob.bids > 0 || List.length ob.asks > 0 ->
              Some (m, token_ids, ob)
          | Ok _ -> None (* Empty order book *)
          | Error _ -> None)
      | [] -> None)
    markets_with_tokens

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Common.Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in

  Logger.info "START"
    [ ("demo", "CLOB API"); ("base_url", Clob_api.Client.default_base_url) ];

  let clob_client = Clob_api.Client.create ~sw ~net () in

  (* First, get markets from Gamma API to find token IDs with active order books *)
  Logger.header "Setup: Finding Active Markets";
  let gamma_client = Gamma_api.Client.create ~sw ~net () in
  (* Filter for active, non-closed markets with volume to find ones with order books *)
  let markets =
    Gamma_api.Client.get_markets gamma_client ~limit:50 ~active:true
      ~closed:false ~volume_num_min:1000.0 ()
  in

  let markets_with_tokens =
    match markets with
    | Ok m ->
        let mwt = extract_markets_with_tokens m in
        Logger.ok "fetch_markets"
          (Printf.sprintf "found %d markets with token IDs" (List.length mwt));
        mwt
    | Error err ->
        Logger.error "fetch_markets" err.Http_client.Client.error;
        []
  in

  (* Find a market that actually has an order book with liquidity *)
  Logger.info "SEARCH"
    [ ("action", "looking for market with active order book") ];
  let active_market =
    find_market_with_orderbook clob_client markets_with_tokens
  in

  match active_market with
  | None ->
      Logger.error "ABORT" "No markets with active order books found";
      (* Still test batch endpoints with whatever tokens we have *)
      let all_token_ids =
        List.concat_map (fun (_, tids) -> tids) markets_with_tokens
      in
      if List.length all_token_ids > 0 then (
        Logger.header "Batch Endpoints (with inactive tokens)";
        let token_ids_subset = List.filteri (fun i _ -> i < 3) all_token_ids in
        let order_books =
          Clob_api.Client.get_order_books clob_client
            ~token_ids:token_ids_subset ()
        in
        print_result_count "get_order_books" order_books;

        let spreads =
          Clob_api.Client.get_spreads clob_client ~token_ids:token_ids_subset ()
        in
        print_result "get_spreads" spreads ~on_ok:(fun s ->
            Printf.sprintf "%d spread entries" (List.length s)))
  | Some (market, token_ids, initial_ob) ->
      let token_id = List.hd token_ids in
      Logger.ok "found_market"
        (Printf.sprintf "market with %d bids, %d asks"
           (List.length initial_ob.bids)
           (List.length initial_ob.asks));
      Logger.info "MARKET"
        [
          ("question", Option.value ~default:"(unknown)" market.question);
          ( "token_id",
            String.sub token_id 0 (min 20 (String.length token_id)) ^ "..." );
        ];

      (* ===== Order Book ===== *)
      Logger.header "Order Book";
      let order_book =
        Clob_api.Client.get_order_book clob_client ~token_id ()
      in
      print_result "get_order_book" order_book
        ~on_ok:(fun (ob : Clob_api.Types.order_book_summary) ->
          Printf.sprintf "%d bids, %d asks" (List.length ob.bids)
            (List.length ob.asks));

      (* Test with multiple token IDs *)
      let all_token_ids =
        List.concat_map (fun (_, tids) -> tids) markets_with_tokens
      in
      let token_ids_subset = List.filteri (fun i _ -> i < 5) all_token_ids in
      if List.length token_ids_subset > 1 then
        let order_books =
          Clob_api.Client.get_order_books clob_client
            ~token_ids:token_ids_subset ()
        in
        print_result_count "get_order_books" order_books
      else Logger.skip "get_order_books" "need multiple token IDs";

      (* ===== Pricing ===== *)
      Logger.header "Pricing";
      let price_buy =
        Clob_api.Client.get_price clob_client ~token_id ~side:Clob_api.Types.BUY
          ()
      in
      print_result "get_price (BUY)" price_buy
        ~on_ok:(fun (p : Clob_api.Types.price_response) ->
          Option.value ~default:"(no price)" p.price);

      let price_sell =
        Clob_api.Client.get_price clob_client ~token_id
          ~side:Clob_api.Types.SELL ()
      in
      print_result "get_price (SELL)" price_sell
        ~on_ok:(fun (p : Clob_api.Types.price_response) ->
          Option.value ~default:"(no price)" p.price);

      let midpoint = Clob_api.Client.get_midpoint clob_client ~token_id () in
      print_result "get_midpoint" midpoint
        ~on_ok:(fun (m : Clob_api.Types.midpoint_response) ->
          Option.value ~default:"(no mid)" m.mid);

      (* Batch prices *)
      let requests =
        List.filteri (fun i _ -> i < 3) all_token_ids
        |> List.map (fun tid -> (tid, Clob_api.Types.BUY))
      in
      if List.length requests > 0 then
        let prices = Clob_api.Client.get_prices clob_client ~requests () in
        print_result "get_prices" prices ~on_ok:(fun p ->
            Printf.sprintf "%d price entries" (List.length p))
      else Logger.skip "get_prices" "no token IDs for batch request";

      (* Spreads *)
      if List.length token_ids_subset > 0 then
        let spreads =
          Clob_api.Client.get_spreads clob_client ~token_ids:token_ids_subset ()
        in
        print_result "get_spreads" spreads ~on_ok:(fun s ->
            Printf.sprintf "%d spread entries" (List.length s))
      else Logger.skip "get_spreads" "no token IDs available";

      (* ===== Timeseries ===== *)
      Logger.header "Timeseries";
      (match market.condition_id with
      | Some cond_id ->
          let history =
            Clob_api.Client.get_price_history clob_client ~market:cond_id
              ~interval:Clob_api.Params.DAY_1 ()
          in
          print_result "get_price_history" history
            ~on_ok:(fun (h : Clob_api.Types.price_history) ->
              Printf.sprintf "%d price points" (List.length h.history))
      | None ->
          Logger.skip "get_price_history" "no market condition ID available");

      (* ===== Authenticated Endpoints ===== *)
      Logger.header "Authenticated Endpoints";
      (* Use test private key or env var *)
      let private_key =
        match Sys.getenv_opt "POLY_PRIVATE_KEY" with
        | Some pk -> pk
        (* Well-known Foundry/Hardhat test account #0 - DO NOT use with real funds *)
        | None ->
            "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
      in
      let address = Clob_api.Crypto.private_key_to_address private_key in
      Logger.info "AUTH" [ ("address", address) ];
      (* Derive API key from private key *)
      let nonce = int_of_float (Unix.gettimeofday () *. 1000.0) mod 1000000 in
      (match Clob_api.Client.derive_api_key clob_client ~private_key ~nonce with
      | Ok resp ->
          Logger.ok "derive_api_key"
            (Printf.sprintf "api_key=%s..." (String.sub resp.api_key 0 8));
          (* Create authenticated client *)
          let credentials =
            Clob_api.Auth_types.credentials_of_derive_response resp
          in
          let auth_client =
            Clob_api.Client.with_credentials clob_client ~credentials ~address
          in
          (* Test authenticated endpoints *)
          let orders = Clob_api.Client.get_orders auth_client () in
          print_result "get_orders" orders ~on_ok:(fun o ->
              Printf.sprintf "%d orders" (List.length o));
          let trades = Clob_api.Client.get_trades auth_client () in
          print_result "get_trades" trades ~on_ok:(fun t ->
              Printf.sprintf "%d trades" (List.length t))
      | Error err ->
          Logger.error "derive_api_key" err.Http_client.Client.error;
          Logger.skip "get_orders" "could not derive API key";
          Logger.skip "get_trades" "could not derive API key");
      Logger.skip "create_order" "requires signed order";
      Logger.skip "cancel_order" "requires order ID";

      (* ===== Summary ===== *)
      Logger.header "Summary";
      Logger.info "COMPLETE" [ ("status", "demo finished") ]

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
