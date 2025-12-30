(** High-level WebSocket client for Polymarket.

    Provides typed streaming access to Market and User channels. *)

module Connection = Websocket.Connection

let section = "WSS"

(** Polymarket WebSocket host *)
let default_host = "ws-subscriptions-clob.polymarket.com"

(** {1 Market Channel Client} *)

module Market = struct
  type t = {
    conn : Connection.t;
    message_stream : Types.message Eio.Stream.t;
    mutable asset_ids : string list;
  }

  let connect ~sw ~net ~clock ~asset_ids () =
    let conn =
      Connection.create ~sw ~net ~clock ~host:default_host
        ~resource:"/ws/market" ()
    in
    let message_stream = Eio.Stream.create 1000 in

    (* Set subscription message for reconnection *)
    let subscribe_msg = Types.market_subscribe_json ~asset_ids in
    Connection.set_subscription conn subscribe_msg;

    (* Start the connection *)
    Connection.start conn;

    (* Start message parsing fiber *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          let raw_stream = Connection.message_stream conn in
          while not (Connection.is_closed conn) do
            let raw = Eio.Stream.take raw_stream in
            let msgs = Types.parse_message ~channel:Types.Channel.Market raw in
            List.iter (fun msg -> Eio.Stream.add message_stream msg) msgs
          done;
          Logger.log_debug ~section ~event:"PARSER_STOPPED"
            [ ("channel", "market") ]
        with
        | Eio.Cancel.Cancelled _ ->
            Logger.log_debug ~section ~event:"PARSER_CANCELLED"
              [ ("channel", "market") ]
        | exn ->
            Logger.log_err ~section ~event:"PARSER_ERROR"
              [ ("channel", "market"); ("error", Printexc.to_string exn) ]);

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
    let conn =
      Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws/user"
        ()
    in
    let message_stream = Eio.Stream.create 1000 in

    (* Set subscription message with auth for reconnection *)
    let subscribe_msg = Types.user_subscribe_json ~credentials ~markets in
    Connection.set_subscription conn subscribe_msg;

    (* Start the connection *)
    Connection.start conn;

    (* Start message parsing fiber *)
    Eio.Fiber.fork ~sw (fun () ->
        try
          let raw_stream = Connection.message_stream conn in
          while not (Connection.is_closed conn) do
            let raw = Eio.Stream.take raw_stream in
            let msgs = Types.parse_message ~channel:Types.Channel.User raw in
            List.iter (fun msg -> Eio.Stream.add message_stream msg) msgs
          done;
          Logger.log_debug ~section ~event:"PARSER_STOPPED"
            [ ("channel", "user") ]
        with
        | Eio.Cancel.Cancelled _ ->
            Logger.log_debug ~section ~event:"PARSER_CANCELLED"
              [ ("channel", "user") ]
        | exn ->
            Logger.log_err ~section ~event:"PARSER_ERROR"
              [ ("channel", "user"); ("error", Printexc.to_string exn) ]);

    { conn; message_stream }

  let stream t = t.message_stream
  let close t = Connection.close t.conn
end
