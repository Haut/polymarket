(** Gamma API query types for Polymarket.

    These types are used for API query parameters. *)

(** {1 Query Parameter Enums} *)

(** Status filter for events and markets *)
type status =
  | Active  (** Only active/open items *)
  | Closed  (** Only closed/resolved items *)
  | All  (** All items regardless of status *)

val string_of_status : status -> string
val status_of_yojson : Yojson.Safe.t -> status
val yojson_of_status : status -> Yojson.Safe.t
val pp_status : Format.formatter -> status -> unit
val show_status : status -> string
val equal_status : status -> status -> bool

(** Parent entity type for comments *)
type parent_entity_type =
  | Event  (** Event entity *)
  | Series  (** Series entity *)
  | Market  (** Market entity *)

val string_of_parent_entity_type : parent_entity_type -> string
val parent_entity_type_of_yojson : Yojson.Safe.t -> parent_entity_type
val yojson_of_parent_entity_type : parent_entity_type -> Yojson.Safe.t
val pp_parent_entity_type : Format.formatter -> parent_entity_type -> unit
val show_parent_entity_type : parent_entity_type -> string
val equal_parent_entity_type : parent_entity_type -> parent_entity_type -> bool

(** Slug size for URL slugs *)
type slug_size =
  | Sm  (** Small slug *)
  | Md  (** Medium slug *)
  | Lg  (** Large slug *)

val string_of_slug_size : slug_size -> string
val slug_size_of_yojson : Yojson.Safe.t -> slug_size
val yojson_of_slug_size : slug_size -> Yojson.Safe.t
val pp_slug_size : Format.formatter -> slug_size -> unit
val show_slug_size : slug_size -> string
val equal_slug_size : slug_size -> slug_size -> bool
