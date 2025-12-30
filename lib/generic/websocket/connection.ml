(** WebSocket connection management with TLS and reconnection support.

    Uses tls-eio for pure-OCaml TLS, avoiding OpenSSL dependencies. *)

let section = "WSS"

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

(** Create TLS configuration *)
let make_tls_config () =
  let authenticator =
    match Ca_certs.authenticator () with
    | Ok auth -> auth
    | Error (`Msg msg) -> failwith ("CA certs error: " ^ msg)
  in
  match Tls.Config.client ~authenticator () with
  | Ok cfg -> cfg
  | Error (`Msg msg) -> failwith ("TLS config error: " ^ msg)

(** Create a new connection *)
let create ~sw ~net ~clock ~host ~resource () =
  {
    config = default_config ~host ~resource;
    sw;
    net = Net net;
    clock;
    state = Disconnected;
    flow = None;
    message_stream = Eio.Stream.create 1000;
    subscription_msg = None;
    closed = false;
    current_backoff = 1.0;
  }

(** Establish TCP + TLS connection *)
let connect_tls t =
  let host = t.config.host in
  let port = t.config.port in
  let (Net net) = t.net in

  Logger.log_info ~section ~event:"TCP_CONNECT"
    [ ("host", host); ("port", string_of_int port) ];

  (* Resolve address *)
  let addr =
    match Eio.Net.getaddrinfo_stream net host ~service:(string_of_int port) with
    | [] -> failwith ("Failed to resolve host: " ^ host)
    | addr :: _ -> addr
  in

  (* Connect TCP *)
  let socket = Eio.Net.connect ~sw:t.sw net addr in

  (* Upgrade to TLS *)
  let tls_config = make_tls_config () in
  let host_name = Domain_name.of_string_exn host |> Domain_name.host_exn in
  Logger.log_debug ~section ~event:"TLS_HANDSHAKE" [];
  let tls_flow = Tls_eio.client_of_flow tls_config ~host:host_name socket in
  Logger.log_info ~section ~event:"TLS_CONNECTED" [];

  tls_flow

(** Connect and perform WebSocket handshake *)
let connect_internal t =
  t.state <- Connecting;
  let flow = connect_tls t in

  (* Perform WebSocket handshake *)
  match
    Handshake.perform ~flow ~host:t.config.host ~port:t.config.port
      ~resource:t.config.resource
  with
  | Handshake.Success ->
      t.flow <- Some flow;
      t.state <- Connected;
      t.current_backoff <- t.config.initial_backoff;
      Logger.log_info ~section ~event:"CONNECTED" [];
      true
  | Handshake.Failed msg ->
      Logger.log_err ~section ~event:"HANDSHAKE_FAILED" [ ("error", msg) ];
      t.state <- Disconnected;
      false

(** Send a frame *)
let send_frame t frame =
  match t.flow with
  | Some flow ->
      let data = Frame.encode ~mask:true frame in
      Eio.Flow.copy_string data flow;
      Logger.log_debug ~section ~event:"FRAME_SENT"
        [ ("opcode", string_of_int (Frame.Opcode.to_int frame.opcode)) ]
  | None ->
      Logger.log_warn ~section ~event:"SEND_FAILED"
        [ ("reason", "not connected") ]

(** Send a text message *)
let send t msg =
  send_frame t (Frame.text msg);
  Logger.log_debug ~section ~event:"MSG_SENT" [ ("msg", msg) ]

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
              Logger.log_debug ~section ~event:"PING_RECV" []
          | Frame.Opcode.Pong -> Logger.log_debug ~section ~event:"PONG_RECV" []
          | Frame.Opcode.Close ->
              Logger.log_info ~section ~event:"CLOSE_RECV" [];
              t.state <- Closed
          | _ -> ()
        done
      with
      | End_of_file ->
          Logger.log_info ~section ~event:"EOF" [];
          t.state <- Disconnected
      | exn ->
          Logger.log_err ~section ~event:"RECV_ERROR"
            [ ("error", Printexc.to_string exn) ];
          t.state <- Disconnected)

(** Ping loop - sends periodic pings *)
let ping_loop t =
  try
    while t.state = Connected && not t.closed do
      Eio.Time.sleep t.clock t.config.ping_interval;
      if t.state = Connected then begin
        send_ping t;
        Logger.log_debug ~section ~event:"PING_SENT" []
      end
    done
  with
  | Eio.Cancel.Cancelled _ ->
      Logger.log_debug ~section ~event:"PING_CANCELLED" []
  | _ -> ()

(** Connect with exponential backoff retry *)
let rec connect_with_retry t =
  if t.closed then ()
  else if connect_internal t then begin
    (* Send subscription message if set *)
    match t.subscription_msg with
    | Some msg ->
        send t msg;
        Logger.log_info ~section ~event:"RESUBSCRIBED" []
    | None -> ()
  end
  else begin
    Logger.log_warn ~section ~event:"RETRY"
      [ ("backoff", Printf.sprintf "%.1fs" t.current_backoff) ];
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
    Logger.log_info ~section ~event:"CLOSED" []
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
        Logger.log_debug ~section ~event:"RECV_CANCELLED" [])

(** Start ping loop *)
let start_ping t = Eio.Fiber.fork ~sw:t.sw (fun () -> ping_loop t)
