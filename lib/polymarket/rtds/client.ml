(** High-level WebSocket client for Polymarket Real-Time Data Socket (RTDS).

    Provides typed streaming access to crypto prices and comments. *)

module Connection = Websocket.Connection

let src = Logs.Src.create "polymarket.rtds" ~doc:"Polymarket RTDS client"

module Log = (val Logs.src_log src : Logs.LOG)

(** RTDS WebSocket host *)
let default_host = "ws-live-data.polymarket.com"

module Constants = Polymarket_common.Constants

(** {1 Internal Helpers} *)

(** Create a WebSocket client with filtering for specialized message types. Used
    by Crypto_prices and Comments clients that need type-specific streams. *)
let make_filtered_client (type a) ~sw ~net ~clock ~subscription
    ~(filter : Types.message -> a option) ~channel_name :
    Connection.t * a Eio.Stream.t =
  let conn =
    Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws"
      ~ping_interval:Constants.rtds_ping_interval
      ~buffer_size:Constants.message_buffer_size ()
  in
  let message_stream = Eio.Stream.create Constants.message_buffer_size in
  let subscribe_msg = Types.subscribe_json ~subscriptions:[ subscription ] in
  Connection.set_subscription conn subscribe_msg;
  Connection.start conn;
  Connection.start_ping conn;
  (* Parsing with filter *)
  let parse raw = Types.parse_message raw |> List.filter_map filter in
  Connection.start_parsing_fiber ~sw ~channel_name ~conn ~parse
    ~output_stream:message_stream;
  (conn, message_stream)

(** {1 Unified RTDS Client} *)

type t = {
  conn : Connection.t;
  message_stream : Types.message Eio.Stream.t;
  mutable subscriptions : Types.subscription list;
}

let connect ~sw ~net ~clock () =
  Log.debug (fun m -> m "Unified: connecting");
  let conn =
    Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws"
      ~ping_interval:Constants.rtds_ping_interval
      ~buffer_size:Constants.message_buffer_size ()
  in
  let message_stream = Eio.Stream.create Constants.message_buffer_size in
  Connection.start conn;
  Connection.start_ping conn;
  Connection.start_parsing_fiber ~sw ~channel_name:"unified" ~conn
    ~parse:Types.parse_message ~output_stream:message_stream;
  { conn; message_stream; subscriptions = [] }

let stream t = t.message_stream

let subscribe t ~subscriptions =
  Log.debug (fun m ->
      m "Unified: subscribing to %d channels (total: %d)"
        (List.length subscriptions)
        (List.length t.subscriptions + List.length subscriptions));
  t.subscriptions <- t.subscriptions @ subscriptions;
  let msg = Types.subscribe_json ~subscriptions in
  Connection.send t.conn msg;
  (* Update stored subscription for reconnect *)
  let full_msg = Types.subscribe_json ~subscriptions:t.subscriptions in
  Connection.set_subscription t.conn full_msg

let unsubscribe t ~subscriptions =
  let new_subs =
    List.filter
      (fun s ->
        not (List.exists (fun u -> Types.equal_subscription s u) subscriptions))
      t.subscriptions
  in
  Log.debug (fun m ->
      m "Unified: unsubscribing from %d channels (remaining: %d)"
        (List.length subscriptions)
        (List.length new_subs));
  t.subscriptions <- new_subs;
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

  let crypto_filter = function `Crypto m -> Some m | _ -> None

  let connect_binance ~sw ~net ~clock ?symbols () =
    Log.debug (fun m ->
        m "Crypto: connecting to Binance%s"
          (match symbols with
          | Some s -> Printf.sprintf " (%d symbols)" (List.length s)
          | None -> ""));
    let subscription =
      let filters = Option.map Types.binance_symbol_filter symbols in
      Types.crypto_prices_subscription ?filters ()
    in
    let conn, message_stream =
      make_filtered_client ~sw ~net ~clock ~subscription ~filter:crypto_filter
        ~channel_name:"crypto_binance"
    in
    { conn; message_stream; symbols; source = Binance }

  let connect_chainlink ~sw ~net ~clock ?symbol () =
    Log.debug (fun m ->
        m "Crypto: connecting to Chainlink%s"
          (match symbol with Some s -> Printf.sprintf " (%s)" s | None -> ""));
    let subscription =
      let filters = Option.map Types.chainlink_symbol_filter symbol in
      Types.crypto_prices_chainlink_subscription ?filters ()
    in
    let conn, message_stream =
      make_filtered_client ~sw ~net ~clock ~subscription ~filter:crypto_filter
        ~channel_name:"crypto_chainlink"
    in
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

  let comment_filter = function `Comment m -> Some m | _ -> None

  let connect ~sw ~net ~clock ?gamma_auth () =
    Log.debug (fun m ->
        m "Comments: connecting%s"
          (if Option.is_some gamma_auth then " (authenticated)" else ""));
    let subscription = Types.comments_subscription ?gamma_auth () in
    let conn, message_stream =
      make_filtered_client ~sw ~net ~clock ~subscription ~filter:comment_filter
        ~channel_name:"comments"
    in
    { conn; message_stream; gamma_auth }

  let stream t = t.message_stream
  let gamma_auth t = t.gamma_auth
  let close t = Connection.close t.conn
end
