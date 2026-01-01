(** Live demo of the Polymarket WebSocket client.

    This example connects to the Market channel and streams real-time orderbook
    updates. Run with: dune exec examples/wss_demo.exe

    Note: This connects to ws-subscriptions-clob.polymarket.com and requires
    valid asset IDs. The demo uses a popular market to ensure data is flowing.
*)

open Polymarket

(** {1 Message Handlers} *)

let handle_market_message (msg : Wss.Types.message) =
  match msg with
  | `Market (`Book book) ->
      Logger.ok "BOOK"
        (Printf.sprintf "asset=%s bids=%d asks=%d" book.asset_id
           (List.length book.bids) (List.length book.asks))
  | `Market (`Price_change change) ->
      let n = List.length change.price_changes in
      Logger.ok "PRICE" (Printf.sprintf "market=%s changes=%d" change.market n)
  | `Market (`Last_trade_price trade) ->
      Logger.ok "TRADE"
        (Printf.sprintf "asset=%s price=%s" trade.asset_id trade.price)
  | `Market (`Tick_size_change _) -> Logger.ok "TICK_SIZE" "tick size changed"
  | `Market (`Best_bid_ask bba) ->
      Logger.ok "BBA"
        (Printf.sprintf "asset=%s bid=%s ask=%s" bba.asset_id bba.best_bid
           bba.best_ask)
  | `User (`Trade trade) ->
      Logger.ok "USER_TRADE"
        (Printf.sprintf "id=%s price=%s size=%s" trade.id trade.price trade.size)
  | `User (`Order order) ->
      Logger.ok "USER_ORDER"
        (Printf.sprintf "id=%s side=%s price=%s" order.id order.side order.price)
  | `Unknown raw ->
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
  Logger.info "FETCHING" [ ("source", "Gamma API") ];
  let clock = Eio.Stdenv.clock env in
  let routes =
    Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Delay
  in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in
  let client = Gamma.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter () in
  match
    Gamma.get_markets client ~limit:(Nonneg_int.of_int_exn 3) ~closed:false ()
  with
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
      Logger.error "GAMMA" (Http.error_to_string err);
      None

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  Logger.info "START"
    [
      ("demo", "WebSocket Client");
      ("host", "ws-subscriptions-clob.polymarket.com");
    ];

  (* Get active token IDs to subscribe to *)
  match get_active_tokens env sw with
  | None ->
      Logger.error "DEMO" "Cannot run demo without active token IDs";
      Logger.info "TIP"
        [
          ( "message",
            "Make sure you have network access to gamma-api.polymarket.com" );
        ]
  | Some asset_ids ->
      Logger.header "Market Channel";
      Logger.info "CONNECTING"
        [
          ("channel", "market");
          ("assets", string_of_int (List.length asset_ids));
        ];

      (* Connect to market channel *)
      let client = Wss.Market.connect ~sw ~net ~clock ~asset_ids () in
      let stream = Wss.Market.stream client in

      Logger.ok "CONNECTED" "Waiting for messages...";
      Logger.info "NOTE" [ ("message", "Press Ctrl+C to stop") ];

      (* Read messages for a while *)
      let message_count = ref 0 in
      let max_messages = 20 in

      (try
         while !message_count < max_messages do
           (* Use Eio.Time.with_timeout for bounded wait *)
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
      | Eio.Cancel.Cancelled _ -> Logger.info "CANCELLED" []
      | exn -> Logger.error "EXCEPTION" (Printexc.to_string exn));

      (* Cleanup *)
      Logger.header "Cleanup";
      Wss.Market.close client;
      Logger.ok "CLOSED" "Connection closed";

      (* Summary *)
      Logger.header "Summary";
      Logger.info "COMPLETE"
        [
          ("messages_received", string_of_int !message_count);
          ("status", "demo finished");
        ]

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
