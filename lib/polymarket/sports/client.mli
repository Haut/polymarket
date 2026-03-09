(** WebSocket client for Polymarket Sports channel.

    Connects to sports-api.polymarket.com/ws and streams live sports match
    results. No subscription message is needed — all events are broadcast
    immediately on connect. *)

type t
(** Sports channel client handle. *)

val connect :
  sw:Eio.Switch.t ->
  net:'a Eio.Net.t ->
  clock:float Eio.Time.clock_ty Eio.Resource.t ->
  unit ->
  t
(** Connect to the sports channel. Automatically handles text-based ping/pong
    keepalive. *)

val stream : t -> Types.message Eio.Stream.t
(** Get the stream of sport result messages. *)

val close : t -> unit
(** Close the connection. *)
