(** Live demo of the Polymarket WebSocket client.

    This example connects to the Market WebSocket channel and watches for
    real-time price updates on the BTC 15-minute up/down market. Run with: dune
    exec examples/wss_demo.exe

    Set POLYMARKET_LOG_LEVEL=debug for verbose output. *)

open Polymarket

(** BTC 15-minute up/down market token IDs (11:30AM-11:45AM ET) *)
let btc_15m_tokens =
  [
    "90537656988681332190152553956251798703285617329864967215099855163235832712503";
    "17777926850952096189805690713073409186209077885446432345429015819936583971311";
  ]

(** Log a market message with structured format *)
let log_message n = function
  | Wss.Types.Market (Book msg) ->
      Logger.info "BOOK"
        [
          ("n", string_of_int n);
          ( "asset",
            String.sub msg.asset_id 0 (min 16 (String.length msg.asset_id)) );
          ("bids", string_of_int (List.length msg.bids));
          ("asks", string_of_int (List.length msg.asks));
        ]
  | Wss.Types.Market (Price_change msg) ->
      Logger.info "PRICE"
        [
          ("n", string_of_int n);
          ("market", String.sub msg.market 0 (min 16 (String.length msg.market)));
          ("changes", string_of_int (List.length msg.price_changes));
        ]
  | Wss.Types.Market (Last_trade_price msg) ->
      Logger.info "TRADE"
        [
          ("n", string_of_int n);
          ("price", msg.price);
          ("size", msg.size);
          ("side", msg.side);
        ]
  | Wss.Types.Market (Tick_size_change msg) ->
      Logger.info "TICK"
        [
          ("n", string_of_int n);
          ("old", msg.old_tick_size);
          ("new", msg.new_tick_size);
        ]
  | Wss.Types.Market (Best_bid_ask msg) ->
      Logger.info "BBA"
        [ ("n", string_of_int n); ("bid", msg.best_bid); ("ask", msg.best_ask) ]
  | Wss.Types.User _ -> Logger.info "USER" [ ("n", string_of_int n) ]
  | Wss.Types.Unknown raw ->
      Logger.info "UNKNOWN"
        [
          ("n", string_of_int n);
          ("raw", String.sub raw 0 (min 50 (String.length raw)));
        ]

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in

  Logger.info "START" [ ("demo", "WebSocket Market Stream") ];
  Logger.header "BTC 15-minute Up/Down Market";

  (* Connect to market channel with BTC 15m tokens *)
  let market_client =
    Wss.Market.connect ~sw ~net ~asset_ids:btc_15m_tokens ()
  in
  let stream = Wss.Market.stream market_client in

  Logger.header "Watching Messages (Ctrl+C to stop)";

  (* Watch for messages *)
  let count = ref 0 in
  (try
     while true do
       let msg = Eio.Stream.take stream in
       incr count;
       log_message !count msg;
       (* Stop after 50 messages for demo purposes *)
       if !count >= 50 then begin
         Logger.info "LIMIT" [ ("message", "reached 50 messages, stopping") ];
         raise Exit
       end
     done
   with
  | Exit -> ()
  | Eio.Cancel.Cancelled _ -> Logger.info "CANCELLED" []);

  (* Cleanup *)
  Wss.Market.close market_client;
  Logger.header "Summary";
  Logger.info "COMPLETE" [ ("messages_received", string_of_int !count) ]

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
