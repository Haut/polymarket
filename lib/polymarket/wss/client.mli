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
    ?initial_dump:bool ->
    ?level:int ->
    ?custom_feature_enabled:bool ->
    asset_ids:string list ->
    unit ->
    t
  (** Connect to the market channel with initial asset subscriptions. *)

  val stream : t -> Types.message Eio.Stream.t
  (** Get the stream of market messages. *)

  val subscribe :
    t ->
    ?level:int ->
    ?custom_feature_enabled:bool ->
    asset_ids:string list ->
    unit ->
    unit
  (** Subscribe to additional assets. *)

  val unsubscribe :
    t -> ?custom_feature_enabled:bool -> asset_ids:string list -> unit -> unit
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
    credentials:Common.Auth.credentials ->
    ?markets:string list ->
    unit ->
    t
  (** Connect to the user channel with authentication. If [markets] is omitted,
      subscribes to all markets. *)

  val stream : t -> Types.message Eio.Stream.t
  (** Get the stream of user messages. *)

  val subscribe : t -> markets:string list -> unit
  (** Subscribe to additional markets. *)

  val unsubscribe : t -> markets:string list -> unit
  (** Unsubscribe from markets. *)

  val close : t -> unit
  (** Close the connection. *)
end
