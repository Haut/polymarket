(** WebSocket connection management with TLS and reconnection support.

    Uses tls-eio for pure-OCaml TLS, avoiding OpenSSL dependencies. *)

(** {1 Types} *)

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

type t
(** WebSocket connection handle. *)

(** {1 Configuration} *)

val default_config : host:string -> resource:string -> config
(** Create default configuration for a host and resource path. *)

(** {1 Connection Management} *)

val create :
  sw:Eio.Switch.t ->
  net:'a Eio.Net.t ->
  clock:float Eio.Time.clock_ty Eio.Resource.t ->
  host:string ->
  resource:string ->
  ?ping_interval:float ->
  ?buffer_size:int ->
  unit ->
  t
(** Create a new WebSocket connection. Does not connect immediately.

    @param ping_interval Ping interval in seconds (default: 30.0)
    @param buffer_size Message buffer size (default: 1000) *)

val start : t -> unit
(** Start the connection with automatic reconnection. *)

val close : t -> unit
(** Close the connection. *)

(** {1 Messaging} *)

val send : t -> string -> unit
(** Send a text message over the connection. *)

val send_ping : t -> unit
(** Send a ping frame. *)

val set_subscription : t -> string -> unit
(** Set the subscription message to send on (re)connect. *)

val message_stream : t -> string Eio.Stream.t
(** Get the stream of received messages. *)

(** {1 Status} *)

val is_connected : t -> bool
(** Check if currently connected. *)

val is_closed : t -> bool
(** Check if the connection has been closed. *)

(** {1 Ping Loop} *)

val start_ping : t -> unit
(** Start the periodic ping loop in a background fiber. *)

(** {1 Message Parsing} *)

val start_parsing_fiber :
  sw:Eio.Switch.t ->
  log_section:string ->
  channel_name:string ->
  conn:t ->
  parse:(string -> 'a list) ->
  output_stream:'a Eio.Stream.t ->
  unit
(** Start a message parsing fiber that reads from a connection's raw stream,
    parses messages using the provided function, and adds them to the output
    stream.

    Handles cancellation and errors with consistent logging.

    @param log_section Logging section (e.g., "WSS", "RTDS")
    @param channel_name Name for log messages (e.g., "market", "user")
    @param parse Function to parse raw messages into typed messages
    @param output_stream Output stream for parsed messages *)
