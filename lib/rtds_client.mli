(** High-level WebSocket client for Polymarket Real-Time Data Socket (RTDS).

    Provides typed streaming access to crypto prices and comments. *)

(** {1 Unified RTDS Client} *)

type t
(** RTDS client handle. *)

val connect :
  sw:Eio.Switch.t ->
  net:'a Eio.Net.t ->
  clock:float Eio.Time.clock_ty Eio.Resource.t ->
  unit ->
  t
(** Connect to the RTDS WebSocket. *)

val stream : t -> Rtds_types.message Eio.Stream.t
(** Get the stream of parsed messages. *)

val subscribe : t -> subscriptions:Rtds_types.subscription list -> unit
(** Subscribe to topics. *)

val unsubscribe : t -> subscriptions:Rtds_types.subscription list -> unit
(** Unsubscribe from topics. *)

val close : t -> unit
(** Close the connection. *)

(** {1 Convenience Clients} *)

module Crypto_prices : sig
  (** Specialized client for crypto price streams. *)

  type source = Binance | Chainlink  (** Price data source. *)

  type t
  (** Crypto prices client handle. *)

  val connect_binance :
    sw:Eio.Switch.t ->
    net:'a Eio.Net.t ->
    clock:float Eio.Time.clock_ty Eio.Resource.t ->
    ?symbols:string list ->
    unit ->
    t
  (** Connect to Binance crypto price stream. *)

  val connect_chainlink :
    sw:Eio.Switch.t ->
    net:'a Eio.Net.t ->
    clock:float Eio.Time.clock_ty Eio.Resource.t ->
    ?symbol:string ->
    unit ->
    t
  (** Connect to Chainlink crypto price stream. *)

  val stream : t -> Rtds_types.crypto_message Eio.Stream.t
  (** Get the stream of crypto price messages. *)

  val symbols : t -> string list option
  (** Get the subscribed symbols. *)

  val source : t -> source
  (** Get the price data source. *)

  val close : t -> unit
  (** Close the connection. *)
end

module Comments : sig
  (** Specialized client for comment streams. *)

  type t
  (** Comments client handle. *)

  val connect :
    sw:Eio.Switch.t ->
    net:'a Eio.Net.t ->
    clock:float Eio.Time.clock_ty Eio.Resource.t ->
    ?gamma_auth:Rtds_types.gamma_auth ->
    unit ->
    t
  (** Connect to comments stream. *)

  val stream : t -> Rtds_types.comment Eio.Stream.t
  (** Get the stream of comment messages. *)

  val gamma_auth : t -> Rtds_types.gamma_auth option
  (** Get the gamma authentication used for the connection. *)

  val close : t -> unit
  (** Close the connection. *)
end
