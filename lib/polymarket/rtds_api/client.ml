(** High-level WebSocket client for Polymarket Real-Time Data Socket (RTDS).

    Provides typed streaming access to crypto prices and comments. *)

module Connection = Websocket.Connection

let section = "RTDS"

(** RTDS WebSocket host *)
let default_host = "ws-live-data.polymarket.com"

(** Recommended ping interval (5 seconds per documentation) *)
let ping_interval = 5.0

(** {1 Unified RTDS Client} *)

type t = {
  conn : Connection.t;
  message_stream : Types.message Eio.Stream.t;
  mutable subscriptions : Types.subscription list;
}

let connect ~sw ~net ~clock () =
  let conn =
    Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws" ()
  in
  let message_stream = Eio.Stream.create 1000 in

  (* Start the connection *)
  Connection.start conn;

  (* Start ping loop for connection maintenance *)
  Eio.Fiber.fork ~sw (fun () ->
      try
        while not (Connection.is_closed conn) do
          Eio.Time.sleep clock ping_interval;
          if Connection.is_connected conn then Connection.send_ping conn
        done
      with Eio.Cancel.Cancelled _ ->
        Logger.log_debug ~section ~event:"PING_CANCELLED" []);

  (* Start message parsing fiber *)
  Eio.Fiber.fork ~sw (fun () ->
      try
        let raw_stream = Connection.message_stream conn in
        while not (Connection.is_closed conn) do
          let raw = Eio.Stream.take raw_stream in
          let msgs = Types.parse_message raw in
          List.iter (fun msg -> Eio.Stream.add message_stream msg) msgs
        done;
        Logger.log_debug ~section ~event:"PARSER_STOPPED" []
      with
      | Eio.Cancel.Cancelled _ ->
          Logger.log_debug ~section ~event:"PARSER_CANCELLED" []
      | exn ->
          Logger.log_err ~section ~event:"PARSER_ERROR"
            [ ("error", Printexc.to_string exn) ]);

  { conn; message_stream; subscriptions = [] }

let stream t = t.message_stream

let subscribe t ~subscriptions =
  t.subscriptions <- t.subscriptions @ subscriptions;
  let msg = Types.subscribe_json ~subscriptions in
  Connection.send t.conn msg;
  (* Update stored subscription for reconnect *)
  let full_msg = Types.subscribe_json ~subscriptions:t.subscriptions in
  Connection.set_subscription t.conn full_msg

let unsubscribe t ~subscriptions =
  t.subscriptions <-
    List.filter
      (fun s ->
        not (List.exists (fun u -> Types.equal_subscription s u) subscriptions))
      t.subscriptions;
  let msg = Types.unsubscribe_json ~subscriptions in
  Connection.send t.conn msg;
  (* Update stored subscription for reconnect *)
  let full_msg = Types.subscribe_json ~subscriptions:t.subscriptions in
  Connection.set_subscription t.conn full_msg

let close t = Connection.close t.conn

(** {1 Convenience Clients} *)

module Crypto_prices = struct
  (** Specialized client for crypto price streams *)

  type source = Binance | Chainlink

  type t = {
    conn : Connection.t;
    message_stream : Types.crypto_message Eio.Stream.t;
    symbols : string list option;
    source : source;
  }

  let connect_binance ~sw ~net ~clock ?symbols () =
    let conn =
      Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws" ()
    in
    let message_stream = Eio.Stream.create 1000 in

    let subscription =
      let filters = Option.map Types.binance_symbol_filter symbols in
      Types.crypto_prices_subscription ?filters ()
    in
    let subscribe_msg = Types.subscribe_json ~subscriptions:[ subscription ] in
    Connection.set_subscription conn subscribe_msg;

    (* Start the connection *)
    Connection.start conn;

    (* Start ping loop *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          while not (Connection.is_closed conn) do
            Eio.Time.sleep clock ping_interval;
            if Connection.is_connected conn then Connection.send_ping conn
          done
        with Eio.Cancel.Cancelled _ -> ());

    (* Start message parsing fiber *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          let raw_stream = Connection.message_stream conn in
          while not (Connection.is_closed conn) do
            let raw = Eio.Stream.take raw_stream in
            let msgs = Types.parse_message raw in
            List.iter
              (fun msg ->
                match msg with
                | `Crypto m -> Eio.Stream.add message_stream m
                | _ -> ())
              msgs
          done
        with
        | Eio.Cancel.Cancelled _ -> ()
        | exn ->
            Logger.log_err ~section ~event:"CRYPTO_PARSER_ERROR"
              [ ("error", Printexc.to_string exn) ]);

    { conn; message_stream; symbols; source = Binance }

  let connect_chainlink ~sw ~net ~clock ?symbol () =
    let conn =
      Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws" ()
    in
    let message_stream = Eio.Stream.create 1000 in

    let subscription =
      let filters = Option.map Types.chainlink_symbol_filter symbol in
      Types.crypto_prices_chainlink_subscription ?filters ()
    in
    let subscribe_msg = Types.subscribe_json ~subscriptions:[ subscription ] in
    Connection.set_subscription conn subscribe_msg;

    (* Start the connection *)
    Connection.start conn;

    (* Start ping loop *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          while not (Connection.is_closed conn) do
            Eio.Time.sleep clock ping_interval;
            if Connection.is_connected conn then Connection.send_ping conn
          done
        with Eio.Cancel.Cancelled _ -> ());

    (* Start message parsing fiber *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          let raw_stream = Connection.message_stream conn in
          while not (Connection.is_closed conn) do
            let raw = Eio.Stream.take raw_stream in
            let msgs = Types.parse_message raw in
            List.iter
              (fun msg ->
                match msg with
                | `Crypto m -> Eio.Stream.add message_stream m
                | _ -> ())
              msgs
          done
        with
        | Eio.Cancel.Cancelled _ -> ()
        | exn ->
            Logger.log_err ~section ~event:"CRYPTO_PARSER_ERROR"
              [ ("error", Printexc.to_string exn) ]);

    {
      conn;
      message_stream;
      symbols = Option.map (fun s -> [ s ]) symbol;
      source = Chainlink;
    }

  let stream t = t.message_stream
  let symbols t = t.symbols
  let source t = t.source
  let close t = Connection.close t.conn
end

module Comments = struct
  (** Specialized client for comment streams *)

  type t = {
    conn : Connection.t;
    message_stream : Types.comment Eio.Stream.t;
    gamma_auth : Types.gamma_auth option;
  }

  let connect ~sw ~net ~clock ?gamma_auth () =
    let conn =
      Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws" ()
    in
    let message_stream = Eio.Stream.create 1000 in

    let subscription = Types.comments_subscription ?gamma_auth () in
    let subscribe_msg = Types.subscribe_json ~subscriptions:[ subscription ] in
    Connection.set_subscription conn subscribe_msg;

    (* Start the connection *)
    Connection.start conn;

    (* Start ping loop *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          while not (Connection.is_closed conn) do
            Eio.Time.sleep clock ping_interval;
            if Connection.is_connected conn then Connection.send_ping conn
          done
        with Eio.Cancel.Cancelled _ -> ());

    (* Start message parsing fiber *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          let raw_stream = Connection.message_stream conn in
          while not (Connection.is_closed conn) do
            let raw = Eio.Stream.take raw_stream in
            let msgs = Types.parse_message raw in
            List.iter
              (fun msg ->
                match msg with
                | `Comment m -> Eio.Stream.add message_stream m
                | _ -> ())
              msgs
          done
        with
        | Eio.Cancel.Cancelled _ -> ()
        | exn ->
            Logger.log_err ~section ~event:"COMMENTS_PARSER_ERROR"
              [ ("error", Printexc.to_string exn) ]);

    { conn; message_stream; gamma_auth }

  let stream t = t.message_stream
  let gamma_auth t = t.gamma_auth
  let close t = Connection.close t.conn
end
