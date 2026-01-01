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
  unit ->
  t
(** Create a new WebSocket connection. Does not connect immediately. *)

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
