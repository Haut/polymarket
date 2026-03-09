(** WebSocket client for Polymarket Sports channel.

    Connects to sports-api.polymarket.com/ws and streams live sports match
    results. Unlike other channels, no subscription message is needed — all
    events are broadcast immediately on connect.

    The server sends text "ping" every ~5s; the client responds with "pong". *)

module Connection = Polymarket_ws.Connection

let src = Logs.Src.create "polymarket.sports" ~doc:"Polymarket Sports client"

module Log = (val Logs.src_log src : Logs.LOG)

(** Sports WebSocket host *)
let default_host = "sports-api.polymarket.com"

module Constants = Common.Constants

type t = { conn : Connection.t; message_stream : Types.message Eio.Stream.t }

let connect ~sw ~net ~clock () =
  Log.debug (fun m -> m "Sports: connecting");
  let conn =
    Connection.create ~sw ~net ~clock ~host:default_host ~resource:"/ws"
      ~buffer_size:Constants.message_buffer_size ()
  in
  let message_stream = Eio.Stream.create Constants.message_buffer_size in
  (* No subscription message — server broadcasts everything on connect *)
  Connection.start conn;
  (* No protocol-level pings — server uses text-based ping/pong *)
  let parse raw =
    if raw = "ping" then begin
      Connection.send conn "pong";
      []
    end
    else Types.parse_message raw
  in
  Connection.start_parsing_fiber ~sw ~channel_name:"sports" ~conn ~parse
    ~output_stream:message_stream;
  { conn; message_stream }

let stream t = t.message_stream
let close t = Connection.close t.conn
