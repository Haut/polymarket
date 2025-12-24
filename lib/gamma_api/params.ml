(** Query parameter types for the Polymarket Gamma API.

    These types correspond to the query parameters defined in the OpenAPI spec
    for the Gamma API endpoints. *)

(** {1 Status Filter} *)

type status =
  | Active  (** Only active/open items *)
  | Closed  (** Only closed/resolved items *)
  | All  (** All items regardless of status *)
[@@deriving yojson, show, eq]

let string_of_status = function
  | Active -> "active"
  | Closed -> "closed"
  | All -> "all"

(** {1 Parent Entity Type} *)

type parent_entity_type =
  | Event  (** Event entity *)
  | Series  (** Series entity *)
  | Market  (** Market entity *)
[@@deriving yojson, show, eq]

let string_of_parent_entity_type = function
  | Event -> "Event"
  | Series -> "Series"
  | Market -> "market"

(** {1 Slug Size} *)

type slug_size =
  | Sm  (** Small slug *)
  | Md  (** Medium slug *)
  | Lg  (** Large slug *)
[@@deriving yojson, show, eq]

let string_of_slug_size = function Sm -> "sm" | Md -> "md" | Lg -> "lg"
