(** Low-level WebSocket connection management with reconnection support. *)

(** {1 Configuration} *)

type config = {
  host : string;
  port : int;
  channel : Types.Channel.t;
  initial_backoff : float;
  max_backoff : float;
}
(** Connection configuration. *)

val default_config : Types.Channel.t -> config
(** Default configuration for a channel. Uses
    [ws-subscriptions-clob.polymarket.com:443]. *)

(** {1 Connection} *)

type t
(** WebSocket connection handle. *)

val create :
  sw:Eio.Switch.t -> net:Eio_unix.Net.t -> channel:Types.Channel.t -> unit -> t
(** Create a new connection (not yet connected). *)

val connect_with_retry : t -> unit
(** Connect to the server with exponential backoff retry on failure. *)

val is_connected : t -> bool
(** Check if currently connected. *)

val send : t -> string -> unit
(** Send a text message. Does nothing if not connected. *)

val send_ping : t -> unit
(** Send a PING frame for keepalive. *)

val set_subscription : t -> string -> unit
(** Set the subscription message to resend on reconnection. *)

val message_stream : t -> string Eio.Stream.t
(** Get the stream of raw messages received from the server. *)

val close : t -> unit
(** Close the connection. Stops reconnection and keepalive loops. *)

val is_closed : t -> bool
(** Check if the connection has been closed. *)

val run_with_reconnect : t -> on_disconnect:(unit -> unit) -> unit
(** Run connection loop with automatic reconnection. Calls [on_disconnect]
    before each reconnection attempt. *)

val start_keepalive : t -> interval:float -> unit
(** Start a background fiber that sends PING every [interval] seconds. *)
