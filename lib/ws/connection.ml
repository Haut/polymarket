(** WebSocket connection management with TLS and reconnection support.

    Uses tls-eio for pure-OCaml TLS, avoiding OpenSSL dependencies. *)

let src = Logs.Src.create "polymarket.wss" ~doc:"WebSocket connection"

module Log = (val Logs.src_log src : Logs.LOG)

(** Connection state *)
type state = Disconnected | Connecting | Connected | Closing | Closed

type config = {
  host : string;
  port : int;
  resource : string;
  initial_backoff : float;
  max_backoff : float;
  ping_interval : float;
}
(** Connection configuration *)

let default_config ~host ~resource =
  {
    host;
    port = 443;
    resource;
    initial_backoff = 1.0;
    max_backoff = 60.0;
    ping_interval = 30.0;
  }

(** Network wrapper to hide type parameter *)
type net_t = Net : 'a Eio.Net.t -> net_t

type t = {
  config : config;
  sw : Eio.Switch.t;
  net : net_t;
  clock : float Eio.Time.clock_ty Eio.Resource.t;
  mutable state : state;
  mutable flow : Tls_eio.t option;
  message_stream : string Eio.Stream.t;
  mutable subscription_msg : string option;
  mutable closed : bool;
  mutable current_backoff : float;
}
(** Internal connection type *)

(** TLS/connection error type *)
type init_error =
  | Ca_certs_error of string
  | Tls_config_error of string
  | Dns_error of string

let string_of_init_error = function
  | Ca_certs_error msg -> "CA certs error: " ^ msg
  | Tls_config_error msg -> "TLS config error: " ^ msg
  | Dns_error msg -> "DNS error: " ^ msg

(** Create TLS configuration *)
let make_tls_config () =
  match Ca_certs.authenticator () with
  | Error (`Msg msg) -> Error (Ca_certs_error msg)
  | Ok authenticator -> (
      match Tls.Config.client ~authenticator () with
      | Ok cfg -> Ok cfg
      | Error (`Msg msg) -> Error (Tls_config_error msg))

(** Create a new connection *)
let create ~sw ~net ~clock ~host ~resource ?(ping_interval = 30.0)
    ?(buffer_size = 1000) () =
  let config = default_config ~host ~resource in
  {
    config = { config with ping_interval };
    sw;
    net = Net net;
    clock;
    state = Disconnected;
    flow = None;
    message_stream = Eio.Stream.create buffer_size;
    subscription_msg = None;
    closed = false;
    current_backoff = 1.0;
  }

(** Establish TCP + TLS connection *)
let connect_tls t =
  let host = t.config.host in
  let port = t.config.port in
  let (Net net) = t.net in

  Log.debug (fun m -> m "Connecting to %s:%d" host port);

  (* Resolve address *)
  match Eio.Net.getaddrinfo_stream net host ~service:(string_of_int port) with
  | [] -> Error (Dns_error ("Failed to resolve host: " ^ host))
  | addr :: _ -> (
      (* Connect TCP *)
      let socket = Eio.Net.connect ~sw:t.sw net addr in

      (* Upgrade to TLS *)
      match make_tls_config () with
      | Error e -> Error e
      | Ok tls_config ->
          let host_name =
            Domain_name.of_string_exn host |> Domain_name.host_exn
          in
          Log.debug (fun m -> m "TLS handshake");
          let tls_flow =
            Tls_eio.client_of_flow tls_config ~host:host_name socket
          in
          Log.debug (fun m -> m "TLS connected");
          Ok tls_flow)

(** Connect and perform WebSocket handshake *)
let connect_internal t =
  t.state <- Connecting;
  match connect_tls t with
  | Error e ->
      Log.err (fun m -> m "Connection failed: %s" (string_of_init_error e));
      t.state <- Disconnected;
      false
  | Ok flow -> (
      (* Perform WebSocket handshake *)
      match
        Handshake.perform ~flow ~host:t.config.host ~port:t.config.port
          ~resource:t.config.resource
      with
      | Handshake.Success ->
          t.flow <- Some flow;
          t.state <- Connected;
          t.current_backoff <- t.config.initial_backoff;
          Log.debug (fun m -> m "Connected");
          true
      | Handshake.Failed msg ->
          Log.err (fun m -> m "Handshake failed: %s" msg);
          t.state <- Disconnected;
          false)

(** Send a frame *)
let send_frame t frame =
  match t.flow with
  | Some flow ->
      let data = Frame.encode ~mask:true frame in
      Eio.Flow.copy_string data flow;
      Log.debug (fun m ->
          m "Frame sent (opcode %d)" (Frame.Opcode.to_int frame.opcode))
  | None -> Log.warn (fun m -> m "Send failed: not connected")

(** Send a text message *)
let send t msg =
  send_frame t (Frame.text msg);
  Log.debug (fun m -> m "Message sent")

(** Send a ping *)
let send_ping t = send_frame t (Frame.ping ())

(** Receive loop - reads frames and dispatches to message stream *)
let receive_loop t =
  match t.flow with
  | None -> ()
  | Some flow -> (
      try
        while t.state = Connected do
          let frame = Frame.decode flow in
          match frame.opcode with
          | Frame.Opcode.Text | Frame.Opcode.Binary ->
              Eio.Stream.add t.message_stream frame.payload
          | Frame.Opcode.Ping ->
              (* Respond with pong *)
              send_frame t (Frame.pong ~payload:frame.payload ());
              Log.debug (fun m -> m "Ping received")
          | Frame.Opcode.Pong -> Log.debug (fun m -> m "Pong received")
          | Frame.Opcode.Close ->
              Log.debug (fun m -> m "Close received");
              t.state <- Closed
          | _ -> ()
        done
      with
      | End_of_file ->
          Log.debug (fun m -> m "EOF");
          t.state <- Disconnected
      | exn ->
          Log.err (fun m -> m "Receive error: %s" (Printexc.to_string exn));
          t.state <- Disconnected)

(** Ping loop - sends periodic pings *)
let ping_loop t =
  try
    while t.state = Connected && not t.closed do
      Eio.Time.sleep t.clock t.config.ping_interval;
      if t.state = Connected then begin
        send_ping t;
        Log.debug (fun m -> m "Ping sent")
      end
    done
  with
  | Eio.Cancel.Cancelled _ -> Log.debug (fun m -> m "Ping cancelled")
  | _ -> ()

(** Connect with exponential backoff retry *)
let rec connect_with_retry t =
  if t.closed then ()
  else if connect_internal t then begin
    (* Send subscription message if set *)
    match t.subscription_msg with
    | Some msg ->
        send t msg;
        Log.debug (fun m -> m "Resubscribed")
    | None -> ()
  end
  else begin
    Log.warn (fun m -> m "Retrying in %.1fs" t.current_backoff);
    Eio.Time.sleep t.clock t.current_backoff;
    t.current_backoff <- min (t.current_backoff *. 2.0) t.config.max_backoff;
    connect_with_retry t
  end

(** Set subscription message for reconnection *)
let set_subscription t msg = t.subscription_msg <- Some msg

(** Get message stream *)
let message_stream t = t.message_stream

(** Check if connected *)
let is_connected t = t.state = Connected

(** Check if closed *)
let is_closed t = t.closed

(** Close connection *)
let close t =
  if not t.closed then begin
    t.closed <- true;
    (match t.flow with
    | Some flow ->
        (try
           send_frame t (Frame.close ());
           Eio.Flow.close flow
         with _ -> ());
        t.flow <- None
    | None -> ());
    t.state <- Closed;
    Log.debug (fun m -> m "Closed")
  end

(** Start the connection with receive loop *)
let start t =
  Eio.Fiber.fork ~sw:t.sw (fun () ->
      try
        while not t.closed do
          if t.state = Disconnected then connect_with_retry t;
          if t.state = Connected then receive_loop t;
          (* Small delay before reconnect attempt *)
          if t.state = Disconnected && not t.closed then
            Eio.Time.sleep t.clock 0.1
        done
      with Eio.Cancel.Cancelled _ ->
        Log.debug (fun m -> m "Receive cancelled"))

(** Start ping loop *)
let start_ping t = Eio.Fiber.fork ~sw:t.sw (fun () -> ping_loop t)

(** Start a message parsing fiber that reads from a connection's raw stream,
    parses messages using the provided function, and adds them to the output
    stream. Handles cancellation and errors with consistent logging.

    @param sw Switch for fiber lifecycle
    @param channel_name Name for log messages (e.g., "market", "user")
    @param conn WebSocket connection to read from
    @param parse Function to parse raw messages into typed messages
    @param output_stream Output stream for parsed messages *)
let start_parsing_fiber (type a) ~sw ~channel_name ~conn
    ~(parse : string -> a list) ~(output_stream : a Eio.Stream.t) =
  Eio.Fiber.fork ~sw (fun () ->
      try
        let raw_stream = conn.message_stream in
        while not conn.closed do
          let raw = Eio.Stream.take raw_stream in
          let msgs = parse raw in
          List.iter (fun msg -> Eio.Stream.add output_stream msg) msgs
        done;
        Log.debug (fun m -> m "Parser stopped (%s)" channel_name)
      with
      | Eio.Cancel.Cancelled _ ->
          Log.debug (fun m -> m "Parser cancelled (%s)" channel_name)
      | exn ->
          Log.err (fun m ->
              m "Parser error (%s): %s" channel_name (Printexc.to_string exn)))
