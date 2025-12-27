(** Low-level WebSocket connection management with reconnection support. *)

let src = Logs.Src.create "polymarket.wss" ~doc:"Polymarket WSS client"

module Log = (val Logs.src_log src : Logs.LOG)

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

(** Generate a random nonce for WebSocket handshake *)
let generate_nonce () =
  let bytes = Bytes.create 16 in
  for i = 0 to 15 do
    Bytes.set bytes i (Char.chr (Random.int 256))
  done;
  Base64.encode_string (Bytes.to_string bytes)

(** Create SSL context for TLS connections *)
let make_ssl_context () =
  Ssl.init ();
  let ctx = Ssl.create_context Ssl.TLSv1_3 Ssl.Client_context in
  Ssl.set_context_alpn_protos ctx [ "http/1.1" ];
  ctx

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

  Log.info (fun m -> m "Connecting to wss://%s:%d%s" host port resource);

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
  let tls_socket = Eio_ssl.connect ssl_context in

  (* Promise for connection completion *)
  let connected, set_connected = Eio.Promise.create () in

  (* WebSocket handler *)
  let websocket_handler wsd =
    t.wsd <- Some wsd;
    t.state <- Connected;
    Eio.Promise.resolve set_connected ();
    Log.info (fun m -> m "WebSocket connected");

    (* Frame handler *)
    let frame ~opcode ~is_fin:_ ~len payload =
      match opcode with
      | `Text | `Binary ->
          (* Accumulate payload data *)
          let buffer = Buffer.create len in
          let on_read bs ~off ~len =
            Buffer.add_string buffer (Bigstringaf.substring bs ~off ~len)
          in
          let on_eof () =
            let msg = Buffer.contents buffer in
            if String.length msg > 0 then begin
              Log.debug (fun m -> m "Received: %s" msg);
              Eio.Stream.add t.message_stream msg
            end
          in
          Httpun_ws.Payload.schedule_read payload ~on_eof ~on_read
      | `Ping ->
          Log.debug (fun m -> m "Received PING");
          Httpun_ws.Wsd.send_pong wsd
      | `Pong -> Log.debug (fun m -> m "Received PONG")
      | `Connection_close ->
          Log.info (fun m -> m "Connection closed by server");
          t.state <- Disconnected;
          Httpun_ws.Payload.close payload
      | `Continuation | `Other _ -> ()
    in

    let eof ?error () =
      (match error with
      | Some (`Exn exn) ->
          Log.err (fun m -> m "WebSocket error: %s" (Printexc.to_string exn))
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
      | `Handshake_failure (resp, _) ->
          Printf.sprintf "Handshake failed: %d"
            (Httpun.Status.to_code resp.Httpun.Response.status)
    in
    Log.err (fun m -> m "Connection error: %s" msg);
    t.state <- Disconnected
  in

  (* Connect - eio-ssl returns the exact type httpun-ws-eio expects *)
  let nonce = generate_nonce () in
  let _client =
    Httpun_ws_eio.Client.connect ~sw:t.sw ~nonce ~host ~port ~resource
      ~error_handler ~websocket_handler tls_socket
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
      Log.debug (fun m -> m "Sent: %s" msg)
  | None -> Log.warn (fun m -> m "Cannot send: not connected")

(** Send ping to keep connection alive *)
let send_ping t =
  match t.wsd with
  | Some wsd ->
      Httpun_ws.Wsd.send_ping wsd;
      Log.debug (fun m -> m "Sent PING")
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
      Log.info (fun m -> m "Connection closed")
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
        Log.info (fun m -> m "Resubscribed after reconnect")
    | None -> ()
  with exn ->
    Log.warn (fun m ->
        m "Connection failed (%s), retrying in %.1fs" (Printexc.to_string exn)
          backoff);
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
    Log.info (fun m -> m "Reconnection monitor stopped (connection closed)")
  with Eio.Cancel.Cancelled _ ->
    Log.debug (fun m -> m "Reconnection monitor cancelled")

(** Start keepalive ping loop *)
let start_keepalive t ~interval =
  Eio.Fiber.fork ~sw:t.sw (fun () ->
      try
        while not t.closed do
          Eio_unix.sleep interval;
          if is_connected t then send_ping t
        done;
        Log.debug (fun m -> m "Keepalive stopped (connection closed)")
      with Eio.Cancel.Cancelled _ ->
        Log.debug (fun m -> m "Keepalive cancelled"))
