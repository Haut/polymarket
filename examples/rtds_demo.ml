(** Live demo of the Polymarket Real-Time Data Socket (RTDS) client.

    This example connects to the RTDS WebSocket and streams real-time crypto
    prices and comments. Run with: dune exec examples/rtds_demo.exe

    Note: This connects to ws-live-data.polymarket.com for streaming data. *)

open Polymarket

(** {1 Message Handlers} *)

let handle_crypto_message (msg : Rtds.Types.crypto_message) =
  match msg with
  | `Binance m ->
      Logger.ok "BINANCE"
        (Printf.sprintf "symbol=%s price=%.2f" m.payload.symbol m.payload.value)
  | `Chainlink m ->
      Logger.ok "CHAINLINK"
        (Printf.sprintf "symbol=%s price=%.2f" m.payload.symbol m.payload.value)

let handle_comment (msg : Rtds.Types.comment) =
  match msg with
  | `Comment_created m ->
      let body_preview =
        if String.length m.payload.body > 50 then
          String.sub m.payload.body 0 50 ^ "..."
        else m.payload.body
      in
      Logger.ok "COMMENT"
        (Printf.sprintf "id=%s user=%s body=\"%s\"" m.payload.id
           m.payload.profile.name body_preview)
  | `Comment_removed m ->
      Logger.ok "REMOVED" (Printf.sprintf "id=%s" m.payload.id)
  | `Reaction_created m ->
      Logger.ok "REACTION+" (Printf.sprintf "comment_id=%s" m.payload.id)
  | `Reaction_removed m ->
      Logger.ok "REACTION-" (Printf.sprintf "comment_id=%s" m.payload.id)

let handle_message (msg : Rtds.Types.message) =
  match msg with
  | `Crypto m -> handle_crypto_message m
  | `Comment m -> handle_comment m
  | `Unknown raw ->
      if String.length raw > 80 then
        Logger.skip "MSG" (String.sub raw 0 80 ^ "...")
      else Logger.skip "MSG" raw

(** {1 Demo: Crypto Prices (Binance)} *)

let run_crypto_binance_demo env sw =
  Logger.header "Crypto Prices (Binance)";
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  Logger.info "CONNECTING"
    [ ("source", "Binance"); ("symbols", "btcusdt,ethusdt,solusdt") ];

  let client =
    Rtds.Crypto_prices.connect_binance ~sw ~net ~clock
      ~symbols:[ "btcusdt"; "ethusdt"; "solusdt" ]
      ()
  in
  let stream = Rtds.Crypto_prices.stream client in

  Logger.ok "CONNECTED" "Waiting for price updates...";

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
           handle_crypto_message msg
       | Error `Timeout ->
           Logger.skip "TIMEOUT" "No message in 30s";
           message_count := max_messages
     done
   with
  | Eio.Cancel.Cancelled _ -> Logger.info "CANCELLED" []
  | exn -> Logger.error "EXCEPTION" (Printexc.to_string exn));

  Rtds.Crypto_prices.close client;
  Logger.ok "CLOSED" "Binance stream closed";
  !message_count

(** {1 Demo: Crypto Prices (Chainlink)} *)

let run_crypto_chainlink_demo env sw =
  Logger.header "Crypto Prices (Chainlink)";
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  Logger.info "CONNECTING" [ ("source", "Chainlink"); ("symbol", "eth/usd") ];

  let client =
    Rtds.Crypto_prices.connect_chainlink ~sw ~net ~clock ~symbol:"eth/usd" ()
  in
  let stream = Rtds.Crypto_prices.stream client in

  Logger.ok "CONNECTED" "Waiting for price updates...";

  let message_count = ref 0 in
  let max_messages = 5 in

  (try
     while !message_count < max_messages do
       match
         Eio.Time.with_timeout clock 30.0 (fun () ->
             Ok (Eio.Stream.take stream))
       with
       | Ok msg ->
           incr message_count;
           handle_crypto_message msg
       | Error `Timeout ->
           Logger.skip "TIMEOUT" "No message in 30s";
           message_count := max_messages
     done
   with
  | Eio.Cancel.Cancelled _ -> Logger.info "CANCELLED" []
  | exn -> Logger.error "EXCEPTION" (Printexc.to_string exn));

  Rtds.Crypto_prices.close client;
  Logger.ok "CLOSED" "Chainlink stream closed";
  !message_count

(** {1 Demo: Comments}

    Note: This demo is available but skipped by default since comments are
    infrequent. Uncomment in run_demo to enable. *)

let[@warning "-32"] run_comments_demo env sw =
  Logger.header "Comments Stream";
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  Logger.info "CONNECTING" [ ("topic", "comments") ];

  let client = Rtds.Comments.connect ~sw ~net ~clock () in
  let stream = Rtds.Comments.stream client in

  Logger.ok "CONNECTED" "Waiting for comments...";
  Logger.info "NOTE" [ ("message", "Comments may be infrequent") ];

  let message_count = ref 0 in
  let max_messages = 3 in
  let timeout_seconds = 60.0 in

  (try
     while !message_count < max_messages do
       match
         Eio.Time.with_timeout clock timeout_seconds (fun () ->
             Ok (Eio.Stream.take stream))
       with
       | Ok msg ->
           incr message_count;
           handle_comment msg
       | Error `Timeout ->
           Logger.skip "TIMEOUT"
             (Printf.sprintf "No comment in %.0fs" timeout_seconds);
           message_count := max_messages
     done
   with
  | Eio.Cancel.Cancelled _ -> Logger.info "CANCELLED" []
  | exn -> Logger.error "EXCEPTION" (Printexc.to_string exn));

  Rtds.Comments.close client;
  Logger.ok "CLOSED" "Comments stream closed";
  !message_count

(** {1 Demo: Unified Client} *)

let run_unified_demo env sw =
  Logger.header "Unified RTDS Client";
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  Logger.info "CONNECTING" [ ("topics", "crypto_prices, comments") ];

  let client = Rtds.connect ~sw ~net ~clock () in
  let stream = Rtds.stream client in

  (* Subscribe to multiple topics *)
  let subscriptions =
    [
      Rtds.Types.crypto_prices_subscription
        ~filters:(Rtds.Types.binance_symbol_filter [ "btcusdt" ])
        ();
      Rtds.Types.comments_subscription ();
    ]
  in
  Rtds.subscribe client ~subscriptions;

  Logger.ok "SUBSCRIBED" "Waiting for messages...";

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
           handle_message msg
       | Error `Timeout ->
           Logger.skip "TIMEOUT" "No message in 30s";
           message_count := max_messages
     done
   with
  | Eio.Cancel.Cancelled _ -> Logger.info "CANCELLED" []
  | exn -> Logger.error "EXCEPTION" (Printexc.to_string exn));

  Rtds.close client;
  Logger.ok "CLOSED" "Unified client closed";
  !message_count

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  Logger.info "START"
    [ ("demo", "RTDS Client"); ("host", "ws-live-data.polymarket.com") ];

  (* Run crypto prices demo (Binance) *)
  let binance_count = run_crypto_binance_demo env sw in

  (* Run crypto prices demo (Chainlink) *)
  let chainlink_count = run_crypto_chainlink_demo env sw in

  (* Run unified demo *)
  let unified_count = run_unified_demo env sw in

  (* Skip comments demo by default as they're infrequent *)
  Logger.info "NOTE"
    [ ("message", "Skipping comments demo (comments are infrequent)") ];

  (* Summary *)
  Logger.header "Summary";
  Logger.info "COMPLETE"
    [
      ("binance_messages", string_of_int binance_count);
      ("chainlink_messages", string_of_int chainlink_count);
      ("unified_messages", string_of_int unified_count);
      ("status", "demo finished");
    ]

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
