(** Gamma API query types for Polymarket.

    These types are used for API query parameters. *)

(** {1 Query Parameter Enums} *)

type status =
  | Active  (** Only active/open items *)
  | Closed  (** Only closed/resolved items *)
  | All  (** All items regardless of status *)
[@@deriving yojson, show, eq]

let string_of_status = function
  | Active -> "active"
  | Closed -> "closed"
  | All -> "all"

type parent_entity_type =
  | Event  (** Event entity *)
  | Series  (** Series entity *)
  | Market  (** Market entity *)
[@@deriving yojson, show, eq]

let string_of_parent_entity_type = function
  | Event -> "Event"
  | Series -> "Series"
  | Market -> "market"

type slug_size =
  | Sm  (** Small slug *)
  | Md  (** Medium slug *)
  | Lg  (** Large slug *)
[@@deriving yojson, show, eq]

let string_of_slug_size = function Sm -> "sm" | Md -> "md" | Lg -> "lg"
