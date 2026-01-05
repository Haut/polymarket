(** Live demo of the Polymarket WebSocket client.

    This example demonstrates the WebSocket client for both Market and User
    channels, including dynamic subscribe/unsubscribe. Run with: dune exec
    examples/wss_demo.exe

    Note: This connects to ws-subscriptions-clob.polymarket.com and requires
    valid asset IDs. The demo uses a popular market to ensure data is flowing.

    To test the User channel, set this environment variable:
    - POLY_PRIVATE_KEY: Your Ethereum private key (hex, without 0x prefix)

    Or the demo will use a well-known test key (do not use with real funds). *)

open Polymarket

(** {1 Message Handlers} *)

let handle_market_message (msg : Wss.Types.message) =
  match msg with
  | Market (Book book) ->
      Logger.ok "BOOK"
        (Printf.sprintf "asset=%s bids=%d asks=%d" book.asset_id
           (List.length book.bids) (List.length book.asks))
  | Market (Price_change change) ->
      let n = List.length change.price_changes in
      Logger.ok "PRICE" (Printf.sprintf "market=%s changes=%d" change.market n)
  | Market (Last_trade_price trade) ->
      Logger.ok "TRADE"
        (Printf.sprintf "asset=%s price=%s" trade.asset_id trade.price)
  | Market (Tick_size_change _) -> Logger.ok "TICK_SIZE" "tick size changed"
  | Market (Best_bid_ask bba) ->
      Logger.ok "BBA"
        (Printf.sprintf "asset=%s bid=%s ask=%s" bba.asset_id bba.best_bid
           bba.best_ask)
  | User (Trade trade) ->
      Logger.ok "USER_TRADE"
        (Printf.sprintf "id=%s price=%s size=%s" trade.id trade.price trade.size)
  | User (Order order) ->
      Logger.ok "USER_ORDER"
        (Printf.sprintf "id=%s side=%s price=%s" order.id order.side order.price)
  | Unknown raw ->
      if String.length raw > 80 then
        Logger.skip "MSG" (String.sub raw 0 80 ^ "...")
      else Logger.skip "MSG" raw

(** {1 Demo Helpers} *)

(** Parse comma-separated token IDs from clob_token_ids string *)
let parse_token_ids s =
  (* Format is typically "[\"token1\",\"token2\"]" - a JSON array *)
  try
    match Yojson.Safe.from_string s with
    | `List items ->
        List.filter_map (function `String id -> Some id | _ -> None) items
    | _ -> []
  with _ -> []

(** Get some active token IDs from the Gamma API *)
let get_active_tokens env sw =
  Logger.info "Fetching active markets from Gamma API";
  let clock = Eio.Stdenv.clock env in
  let routes =
    match Rate_limit_presets.all ~behavior:Rate_limiter.Delay with
    | Ok r -> r
    | Error msg -> failwith ("Rate limit preset error: " ^ msg)
  in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in
  let client =
    match Gamma.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter () with
    | Ok c -> c
    | Error e -> failwith ("Gamma client error: " ^ Gamma.string_of_init_error e)
  in
  match Gamma.get_markets client ~limit:3 ~closed:false () with
  | Ok markets ->
      let token_ids =
        List.concat_map
          (fun (m : Gamma.market) ->
            match m.clob_token_ids with
            | Some s -> (
                let ids = parse_token_ids s in
                (* Take just the first token ID (YES outcome) *)
                match ids with
                | id :: _ -> [ id ]
                | [] -> [])
            | None -> [])
          markets
      in
      if List.length token_ids > 0 then begin
        Logger.ok "TOKENS"
          (Printf.sprintf "%d token IDs" (List.length token_ids));
        Some token_ids
      end
      else begin
        Logger.error "TOKENS" "No active markets with token IDs found";
        None
      end
  | Error err ->
      Logger.error "GAMMA" (Gamma.error_to_string err);
      None

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  Logger.info "Starting WebSocket demo (ws-subscriptions-clob.polymarket.com)";

  (* Get active token IDs to subscribe to *)
  match get_active_tokens env sw with
  | None ->
      Logger.error "DEMO" "Cannot run demo without active token IDs";
      Logger.info
        "Tip: Make sure you have network access to gamma-api.polymarket.com"
  | Some asset_ids ->
      Logger.info
        (Printf.sprintf "Connecting to market channel (%d assets)"
           (List.length asset_ids));

      (* Connect to market channel *)
      let client = Wss.Market.connect ~sw ~net ~clock ~asset_ids () in
      let stream = Wss.Market.stream client in

      Logger.ok "CONNECTED" "Waiting for messages...";
      Logger.info "Press Ctrl+C to stop";

      (* Read some initial messages *)
      let message_count = ref 0 in
      let max_messages = 10 in

      (try
         while !message_count < max_messages do
           match
             Eio.Time.with_timeout clock 30.0 (fun () ->
                 Ok (Eio.Stream.take stream))
           with
           | Ok msg ->
               incr message_count;
               handle_market_message msg
           | Error `Timeout ->
               Logger.skip "TIMEOUT" "No message in 30s";
               message_count := max_messages
         done
       with
      | Eio.Cancel.Cancelled _ -> Logger.info "Cancelled"
      | exn -> Logger.error "EXCEPTION" (Printexc.to_string exn));

      (* ===== Dynamic Subscribe/Unsubscribe ===== *)

      (* Unsubscribe from first asset *)
      let first_asset = List.hd asset_ids in
      Wss.Market.unsubscribe client ~asset_ids:[ first_asset ];
      Logger.ok "unsubscribe"
        (Printf.sprintf "unsubscribed from %s..." (String.sub first_asset 0 20));

      (* Subscribe to same asset again *)
      Wss.Market.subscribe client ~asset_ids:[ first_asset ];
      Logger.ok "subscribe"
        (Printf.sprintf "re-subscribed to %s..." (String.sub first_asset 0 20));

      (* Read a few more messages to confirm subscription works *)
      let extra_count = ref 0 in
      (try
         while !extra_count < 5 do
           match
             Eio.Time.with_timeout clock 10.0 (fun () ->
                 Ok (Eio.Stream.take stream))
           with
           | Ok msg ->
               incr extra_count;
               incr message_count;
               handle_market_message msg
           | Error `Timeout -> extra_count := 5
         done
       with _ -> ());

      (* Close market client *)
      Wss.Market.close client;
      Logger.ok "CLOSED" "Market channel closed";

      (* ===== User Channel ===== *)

      (* Get credentials for User channel *)
      let private_key =
        let pk_str =
          match Sys.getenv_opt "POLY_PRIVATE_KEY" with
          | Some pk -> pk
          | None ->
              "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        in
        Clob.private_key_of_string pk_str
      in

      (* Create rate limiter for CLOB API *)
      let routes =
        match Rate_limit_presets.all ~behavior:Rate_limiter.Delay with
        | Ok r -> r
        | Error msg -> failwith ("Rate limit preset error: " ^ msg)
      in
      let rate_limiter = Rate_limiter.create ~routes ~clock () in

      (* Derive API credentials via CLOB API *)
      let unauthed_client =
        match Clob.Unauthed.create ~sw ~net ~rate_limiter () with
        | Ok c -> c
        | Error e ->
            failwith ("CLOB client error: " ^ Clob.init_error_to_string e)
      in
      let l1_client = Clob.upgrade_to_l1 unauthed_client ~private_key in
      let nonce = int_of_float (Unix.gettimeofday () *. 1000.0) mod 1000000 in

      (match Clob.L1.derive_api_key l1_client ~nonce with
      | Ok (_l2_client, resp) ->
          Logger.ok "derive_api_key"
            (Printf.sprintf "api_key=%s..." (String.sub resp.api_key 0 8));

          let credentials : Clob.credentials =
            {
              api_key = resp.api_key;
              secret = resp.secret;
              passphrase = resp.passphrase;
            }
          in

          (* Get condition IDs for markets (User channel uses markets, not assets) *)
          let gamma_client =
            match Gamma.create ~sw ~net ~rate_limiter () with
            | Ok c -> c
            | Error e ->
                failwith ("Gamma client error: " ^ Gamma.string_of_init_error e)
          in
          let market_ids =
            match Gamma.get_markets gamma_client ~limit:2 ~closed:false () with
            | Ok markets ->
                List.filter_map
                  (fun (m : Gamma.market) -> m.condition_id)
                  markets
            | Error _ -> []
          in

          if List.length market_ids > 0 then begin
            Logger.info
              (Printf.sprintf "Connecting to user channel (%d markets)"
                 (List.length market_ids));

            let user_client =
              Wss.User.connect ~sw ~net ~clock ~credentials ~markets:market_ids
                ()
            in
            let user_stream = Wss.User.stream user_client in

            Logger.ok "CONNECTED" "User channel connected";

            (* Listen briefly for user events (likely none for test account) *)
            let user_msg_count = ref 0 in
            (try
               while !user_msg_count < 3 do
                 match
                   Eio.Time.with_timeout clock 5.0 (fun () ->
                       Ok (Eio.Stream.take user_stream))
                 with
                 | Ok msg ->
                     incr user_msg_count;
                     handle_market_message msg
                 | Error `Timeout ->
                     Logger.ok "USER_TIMEOUT"
                       "no user events (expected for test account)";
                     user_msg_count := 3
               done
             with _ -> ());

            Wss.User.close user_client;
            Logger.ok "CLOSED" "User channel closed"
          end
          else Logger.skip "User.connect" "no market IDs available"
      | Error err ->
          Logger.error "derive_api_key" (Clob.error_to_string err);
          Logger.skip "User.connect" "could not derive API key");

      (* Summary *)
      Logger.info
        (Printf.sprintf "Demo complete: %d messages received" !message_count)

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
