(** High-level WebSocket client for Polymarket.

    Provides typed streaming access to Market and User channels. *)

module Connection = Websocket.Connection

let section = "WSS"

(** Polymarket WebSocket host *)
let default_host = "ws-subscriptions-clob.polymarket.com"

module Constants = Polymarket_common.Constants

(** {1 Internal Helpers} *)

(** Create a WebSocket client with the common initialization pattern. Uses the
    Connection's built-in ping loop (30s interval). *)
let make_client ~sw ~net ~clock ~resource ~subscribe_msg ~channel ~channel_name
    =
  let conn =
    Connection.create ~sw ~net ~clock ~host:default_host ~resource
      ~buffer_size:Constants.message_buffer_size ()
  in
  let message_stream = Eio.Stream.create Constants.message_buffer_size in
  Connection.set_subscription conn subscribe_msg;
  Connection.start conn;
  Connection.start_ping conn;
  Connection.start_parsing_fiber ~sw ~log_section:section ~channel_name ~conn
    ~parse:(Types.parse_message ~channel)
    ~output_stream:message_stream;
  (conn, message_stream)

(** {1 Market Channel Client} *)

module Market = struct
  type t = {
    conn : Connection.t;
    message_stream : Types.message Eio.Stream.t;
    mutable asset_ids : string list;
  }

  let connect ~sw ~net ~clock ~asset_ids () =
    let subscribe_msg = Types.market_subscribe_json ~asset_ids in
    let conn, message_stream =
      make_client ~sw ~net ~clock ~resource:"/ws/market" ~subscribe_msg
        ~channel:Types.Channel.Market ~channel_name:"market"
    in
    { conn; message_stream; asset_ids }

  let stream t = t.message_stream

  let subscribe t ~asset_ids =
    t.asset_ids <- t.asset_ids @ asset_ids;
    let msg = Types.subscribe_assets_json ~asset_ids in
    Connection.send t.conn msg;
    (* Update stored subscription for reconnect *)
    let full_msg = Types.market_subscribe_json ~asset_ids:t.asset_ids in
    Connection.set_subscription t.conn full_msg

  let unsubscribe t ~asset_ids =
    t.asset_ids <-
      List.filter (fun id -> not (List.mem id asset_ids)) t.asset_ids;
    let msg = Types.unsubscribe_assets_json ~asset_ids in
    Connection.send t.conn msg;
    (* Update stored subscription for reconnect *)
    let full_msg = Types.market_subscribe_json ~asset_ids:t.asset_ids in
    Connection.set_subscription t.conn full_msg

  let close t = Connection.close t.conn
end

(** {1 User Channel Client} *)

module User = struct
  type t = { conn : Connection.t; message_stream : Types.message Eio.Stream.t }

  let connect ~sw ~net ~clock ~credentials ~markets () =
    let subscribe_msg = Types.user_subscribe_json ~credentials ~markets in
    let conn, message_stream =
      make_client ~sw ~net ~clock ~resource:"/ws/user" ~subscribe_msg
        ~channel:Types.Channel.User ~channel_name:"user"
    in
    { conn; message_stream }

  let stream t = t.message_stream
  let close t = Connection.close t.conn
end
