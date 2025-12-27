(** Low-level WebSocket connection management with reconnection support. *)

module Logger = Polymarket_common.Logger

(** Default WebSocket endpoint *)
let default_host = "ws-subscriptions-clob.polymarket.com"

let default_port = 443

type config = {
  host : string;
  port : int;
  channel : Types.Channel.t;
  initial_backoff : float;
  max_backoff : float;
}
(** Connection configuration *)

let default_config channel =
  {
    host = default_host;
    port = default_port;
    channel;
    initial_backoff = 1.0;
    max_backoff = 60.0;
  }

(** Connection state *)
type state =
  | Disconnected
  | Connected
  | Reconnecting of float (* backoff time *)

type t = {
  config : config;
  sw : Eio.Switch.t;
  net : Eio_unix.Net.t;
  mutable state : state;
  mutable wsd : Httpun_ws.Wsd.t option;
  message_stream : string Eio.Stream.t;
  mutable subscription_msg : string option;
  mutable closed : bool;
}
(** Internal connection type *)

(** Generate a random nonce for WebSocket handshake (raw 16 bytes) *)
let generate_nonce () =
  let bytes = Bytes.create 16 in
  for i = 0 to 15 do
    Bytes.set bytes i (Char.chr (Random.int 256))
  done;
  Bytes.to_string bytes

(** Create SSL context for TLS connections *)
let make_ssl_context () =
  Ssl.init ();
  (* Use TLSv1_2 as minimum, allowing negotiation up to TLSv1_3 *)
  let ctx = Ssl.create_context Ssl.TLSv1_2 Ssl.Client_context in
  (* Set ALPN to offer only HTTP/1.1 - required for WebSocket upgrade *)
  Ssl.set_context_alpn_protos ctx [ "http/1.1" ];
  ctx

(** Set ALPN on individual socket for WebSocket compatibility *)
let configure_ssl_socket ssl_sock host =
  (* Set SNI hostname - required by most modern servers *)
  Ssl.set_client_SNI_hostname ssl_sock host;
  (* Also set ALPN on the socket level to ensure HTTP/1.1 *)
  Ssl.set_alpn_protos ssl_sock [ "http/1.1" ]

(** Create a new connection *)
let create ~sw ~(net : Eio_unix.Net.t) ~channel () =
  {
    config = default_config channel;
    sw;
    net;
    state = Disconnected;
    wsd = None;
    message_stream = Eio.Stream.create 1000;
    subscription_msg = None;
    closed = false;
  }

(** Resource path for the channel *)
let resource_path t =
  match t.config.channel with
  | Types.Channel.Market -> "/ws/market"
  | Types.Channel.User -> "/ws/user"

(** Connect to WebSocket server *)
let connect_internal t =
  let host = t.config.host in
  let port = t.config.port in
  let resource = resource_path t in

  Logger.log_info ~section:"WSS" ~event:"CONNECT"
    [ ("host", host); ("port", string_of_int port); ("resource", resource) ];

  (* Resolve address *)
  let addr =
    match
      Eio.Net.getaddrinfo_stream t.net host ~service:(string_of_int port)
    with
    | [] -> failwith ("Failed to resolve host: " ^ host)
    | addr :: _ -> addr
  in

  (* Create TCP socket *)
  let socket = Eio.Net.connect ~sw:t.sw t.net addr in

  (* Upgrade to TLS using OpenSSL *)
  let ssl_ctx = make_ssl_context () in
  let ssl_context = Eio_ssl.Context.create ~ctx:ssl_ctx socket in
  let ssl_sock = Eio_ssl.Context.ssl_socket ssl_context in
  (* Configure SNI and ALPN for HTTP/1.1 WebSocket compatibility *)
  configure_ssl_socket ssl_sock host;
  Logger.log_info ~section:"WSS" ~event:"TLS" [ ("status", "handshake_start") ];
  let tls_socket = Eio_ssl.connect ssl_context in

  (* Log negotiated ALPN protocol *)
  let alpn_proto =
    match Ssl.get_negotiated_alpn_protocol ssl_sock with
    | Some proto -> proto
    | None -> "none"
  in
  Logger.log_info ~section:"WSS" ~event:"TLS"
    [ ("status", "connected"); ("alpn", alpn_proto) ];

  (* Fail fast if HTTP/2 was negotiated - WebSocket requires HTTP/1.1 *)
  if alpn_proto = "h2" then
    failwith "Server negotiated HTTP/2 but WebSocket requires HTTP/1.1";

  (* Promise for connection completion *)
  let connected, set_connected = Eio.Promise.create () in

  (* WebSocket handler *)
  let websocket_handler wsd =
    t.wsd <- Some wsd;
    t.state <- Connected;
    Eio.Promise.resolve set_connected ();
    Logger.log_info ~section:"WSS" ~event:"CONNECTED" [];

    (* Frame handler *)
    let frame ~opcode ~is_fin:_ ~len payload =
      match opcode with
      | `Text | `Binary ->
          (* Accumulate payload data - need to reschedule reads for multi-chunk payloads *)
          let buffer = Buffer.create len in
          let rec schedule_read () =
            Httpun_ws.Payload.schedule_read payload
              ~on_eof:(fun () ->
                let msg = Buffer.contents buffer in
                if String.length msg > 0 then
                  Eio.Stream.add t.message_stream msg)
              ~on_read:(fun bs ~off ~len ->
                Buffer.add_string buffer (Bigstringaf.substring bs ~off ~len);
                schedule_read ())
          in
          schedule_read ()
      | `Ping ->
          Logger.log_debug ~section:"WSS" ~event:"PING"
            [ ("direction", "recv") ];
          Httpun_ws.Wsd.send_pong wsd
      | `Pong ->
          Logger.log_debug ~section:"WSS" ~event:"PONG"
            [ ("direction", "recv") ]
      | `Connection_close ->
          Logger.log_info ~section:"WSS" ~event:"CLOSE"
            [ ("reason", "server_initiated") ];
          t.state <- Disconnected;
          Httpun_ws.Payload.close payload
      | `Continuation | `Other _ -> ()
    in

    let eof ?error () =
      (match error with
      | Some (`Exn exn) ->
          Logger.log_err ~section:"WSS" ~event:"ERROR"
            [ ("error", Printexc.to_string exn) ]
      | None -> ());
      t.state <- Disconnected;
      t.wsd <- None
    in

    { Httpun_ws.Websocket_connection.frame; eof }
  in

  (* Error handler *)
  let error_handler error =
    let msg =
      match error with
      | `Exn exn -> Printexc.to_string exn
      | `Invalid_response_body_length _ -> "Invalid response body length"
      | `Malformed_response msg -> "Malformed response: " ^ msg
      | `Handshake_failure (resp, body) ->
          (* Read response body for error details *)
          let body_content = ref "" in
          let rec read_body () =
            Httpun.Body.Reader.schedule_read body
              ~on_eof:(fun () -> ())
              ~on_read:(fun bs ~off ~len ->
                body_content :=
                  !body_content ^ Bigstringaf.substring bs ~off ~len;
                read_body ())
          in
          read_body ();
          let headers_str =
            Httpun.Headers.fold
              ~f:(fun name value acc -> acc ^ name ^ ": " ^ value ^ "; ")
              ~init:"" resp.Httpun.Response.headers
          in
          Printf.sprintf "Handshake failed: %d %s\nHeaders: %s\nBody: %s"
            (Httpun.Status.to_code resp.Httpun.Response.status)
            (Httpun.Status.to_string resp.Httpun.Response.status)
            headers_str !body_content
    in
    Logger.log_err ~section:"WSS" ~event:"ERROR" [ ("error", msg) ];
    t.state <- Disconnected
  in

  (* Generate nonce for WebSocket handshake *)
  let nonce = generate_nonce () in

  (* WebSocket headers - httpun-ws only adds Sec-WebSocket-Key from nonce *)
  let headers =
    Httpun.Headers.of_list
      [
        ("Host", host);
        ("Connection", "Upgrade");
        ("Upgrade", "websocket");
        ("Sec-WebSocket-Version", "13");
        ("Origin", "https://polymarket.com");
        ("User-Agent", "polymarket-ocaml/1.0");
      ]
  in

  (* Create WebSocket client connection - httpun-ws adds Sec-WebSocket-Key from nonce *)
  let sha1 s = Digestif.SHA1.(digest_string s |> to_raw_string) in
  let connection =
    Httpun_ws.Client_connection.connect ~nonce ~headers ~sha1 ~error_handler
      ~websocket_handler resource
  in

  (* Use Gluten to run the connection *)
  let _client =
    Gluten_eio.Client.create ~sw:t.sw ~read_buffer_size:0x1000
      ~protocol:(module Httpun_ws.Client_connection)
      connection tls_socket
  in

  (* Wait for connection *)
  Eio.Promise.await connected

(** Send a text message *)
let send t msg =
  match t.wsd with
  | Some wsd ->
      let bytes = Bytes.of_string msg in
      Httpun_ws.Wsd.send_bytes wsd ~kind:`Text bytes ~off:0
        ~len:(Bytes.length bytes);
      Logger.log_debug ~section:"WSS" ~event:"SEND"
        [ ("len", string_of_int (String.length msg)) ]
  | None ->
      Logger.log_warn ~section:"WSS" ~event:"SEND"
        [ ("error", "not_connected") ]

(** Send ping to keep connection alive *)
let send_ping t =
  match t.wsd with
  | Some wsd ->
      Httpun_ws.Wsd.send_ping wsd;
      Logger.log_debug ~section:"WSS" ~event:"PING" [ ("direction", "send") ]
  | None -> ()

(** Check if connected *)
let is_connected t = match t.state with Connected -> true | _ -> false

(** Set subscription message for reconnection *)
let set_subscription t msg = t.subscription_msg <- Some msg

(** Get message stream *)
let message_stream t = t.message_stream

(** Close connection *)
let close t =
  t.closed <- true;
  match t.wsd with
  | Some wsd ->
      Httpun_ws.Wsd.close wsd;
      t.wsd <- None;
      t.state <- Disconnected;
      Logger.log_info ~section:"WSS" ~event:"CLOSE"
        [ ("reason", "client_initiated") ]
  | None -> ()

(** Check if connection is closed *)
let is_closed t = t.closed

(** Connect with exponential backoff retry *)
let rec connect_with_retry t =
  let backoff =
    match t.state with Reconnecting b -> b | _ -> t.config.initial_backoff
  in
  try
    connect_internal t;
    (* Resubscribe if we have a subscription message *)
    match t.subscription_msg with
    | Some msg ->
        send t msg;
        Logger.log_info ~section:"WSS" ~event:"SUBSCRIBE"
          [ ("status", "resubscribed") ]
    | None -> ()
  with exn ->
    Logger.log_warn ~section:"WSS" ~event:"RECONNECT"
      [
        ("error", Printexc.to_string exn);
        ("backoff_sec", Printf.sprintf "%.1f" backoff);
      ];
    t.state <- Reconnecting (min (backoff *. 2.0) t.config.max_backoff);
    Eio_unix.sleep backoff;
    connect_with_retry t

(** Run connection with automatic reconnection *)
let run_with_reconnect t ~on_disconnect =
  try
    while not t.closed do
      if not (is_connected t) then begin
        on_disconnect ();
        connect_with_retry t
      end;
      (* Check connection status periodically *)
      Eio_unix.sleep 1.0
    done;
    Logger.log_info ~section:"WSS" ~event:"MONITOR"
      [ ("status", "stopped"); ("reason", "closed") ]
  with Eio.Cancel.Cancelled _ ->
    Logger.log_debug ~section:"WSS" ~event:"MONITOR" [ ("status", "cancelled") ]

(** Start keepalive ping loop *)
let start_keepalive t ~interval =
  Eio.Fiber.fork ~sw:t.sw (fun () ->
      try
        while not t.closed do
          Eio_unix.sleep interval;
          if is_connected t then send_ping t
        done;
        Logger.log_debug ~section:"WSS" ~event:"KEEPALIVE"
          [ ("status", "stopped"); ("reason", "closed") ]
      with Eio.Cancel.Cancelled _ ->
        Logger.log_debug ~section:"WSS" ~event:"KEEPALIVE"
          [ ("status", "cancelled") ])
