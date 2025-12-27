(** Live demo of the Polymarket WebSocket client.

    This example connects to the Market WebSocket channel and watches for
    real-time price updates on the BTC 15-minute up/down market. Run with: dune
    exec examples/wss_demo.exe

    Set POLYMARKET_LOG_LEVEL=debug for verbose output. *)

open Polymarket

(** BTC 15-minute up/down market token IDs (11:15AM-11:30AM ET) *)
let btc_15m_tokens =
  [
    "26060244286464519668811473204271758681039108505277070711042957949579613021410";
    "82687937324480524188563760165060496550572104948772493241341448161316962449821";
  ]

(** Format a market message for display *)
let format_message = function
  | Wss.Types.Market (Book msg) ->
      Printf.sprintf "[BOOK] asset=%s bids=%d asks=%d"
        (String.sub msg.asset_id 0 (min 16 (String.length msg.asset_id)))
        (List.length msg.bids) (List.length msg.asks)
  | Wss.Types.Market (Price_change msg) ->
      Printf.sprintf "[PRICE] market=%s changes=%d"
        (String.sub msg.market 0 (min 16 (String.length msg.market)))
        (List.length msg.price_changes)
  | Wss.Types.Market (Last_trade_price msg) ->
      Printf.sprintf "[TRADE] price=%s size=%s side=%s" msg.price msg.size
        msg.side
  | Wss.Types.Market (Tick_size_change msg) ->
      Printf.sprintf "[TICK] old=%s new=%s" msg.old_tick_size msg.new_tick_size
  | Wss.Types.Market (Best_bid_ask msg) ->
      Printf.sprintf "[BBA] bid=%s ask=%s" msg.best_bid msg.best_ask
  | Wss.Types.User _ -> "[USER] (unexpected)"
  | Wss.Types.Unknown raw ->
      Printf.sprintf "[UNKNOWN] %s"
        (String.sub raw 0 (min 50 (String.length raw)))

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
       let formatted = format_message msg in
       Logger.info "MSG" [ ("n", string_of_int !count); ("data", formatted) ];
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
