(** Gamma API query types for Polymarket.

    These types are used for API query parameters. *)

(** {1 Query Parameter Enums} *)

(** Status filter for events and markets *)
type status =
  | Active  (** Only active/open items *)
  | Closed  (** Only closed/resolved items *)
  | All  (** All items regardless of status *)

val string_of_status : status -> string

(** Parent entity type for comments *)
type parent_entity_type =
  | Event  (** Event entity *)
  | Series  (** Series entity *)
  | Market  (** Market entity *)

val string_of_parent_entity_type : parent_entity_type -> string

(** Slug size for URL slugs *)
type slug_size =
  | Sm  (** Small slug *)
  | Md  (** Medium slug *)
  | Lg  (** Large slug *)

val string_of_slug_size : slug_size -> string
