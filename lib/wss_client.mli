(** High-level WebSocket client for Polymarket.

    Provides typed streaming access to Market and User channels. *)

(** {1 Market Channel Client} *)

module Market : sig
  type t
  (** Market channel client handle. *)

  val connect :
    sw:Eio.Switch.t ->
    net:'a Eio.Net.t ->
    clock:float Eio.Time.clock_ty Eio.Resource.t ->
    asset_ids:string list ->
    unit ->
    t
  (** Connect to the market channel with initial asset subscriptions. *)

  val stream : t -> Wss_types.message Eio.Stream.t
  (** Get the stream of market messages. *)

  val subscribe : t -> asset_ids:string list -> unit
  (** Subscribe to additional assets. *)

  val unsubscribe : t -> asset_ids:string list -> unit
  (** Unsubscribe from assets. *)

  val close : t -> unit
  (** Close the connection. *)
end

(** {1 User Channel Client} *)

module User : sig
  type t
  (** User channel client handle. *)

  val connect :
    sw:Eio.Switch.t ->
    net:'a Eio.Net.t ->
    clock:float Eio.Time.clock_ty Eio.Resource.t ->
    credentials:Auth.credentials ->
    markets:string list ->
    unit ->
    t
  (** Connect to the user channel with authentication. *)

  val stream : t -> Wss_types.message Eio.Stream.t
  (** Get the stream of user messages. *)

  val close : t -> unit
  (** Close the connection. *)
end
