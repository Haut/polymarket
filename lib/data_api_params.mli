(** Query parameter types for the Polymarket Data API.

    These types correspond to the query parameters defined in the OpenAPI spec
    for the Data API endpoints.
*)

(** {1 Sort Direction} *)

(** Sort direction for paginated results *)
type sort_direction =
  | ASC   (** Ascending order *)
  | DESC  (** Descending order *)

val string_of_sort_direction : sort_direction -> string
val sort_direction_of_yojson : Yojson.Safe.t -> sort_direction
val yojson_of_sort_direction : sort_direction -> Yojson.Safe.t
val pp_sort_direction : Format.formatter -> sort_direction -> unit
val show_sort_direction : sort_direction -> string
val equal_sort_direction : sort_direction -> sort_direction -> bool

(** {1 Position Parameters} *)

(** Sort field for positions endpoint *)
type position_sort_by =
  | CURRENT       (** Current value *)
  | INITIAL       (** Initial value *)
  | TOKENS        (** Number of tokens *)
  | CASHPNL       (** Cash profit/loss *)
  | PERCENTPNL    (** Percent profit/loss *)
  | TITLE         (** Title alphabetically *)
  | RESOLVING     (** Resolving status *)
  | PRICE         (** Current price *)
  | AVGPRICE      (** Average price *)

val string_of_position_sort_by : position_sort_by -> string
val position_sort_by_of_yojson : Yojson.Safe.t -> position_sort_by
val yojson_of_position_sort_by : position_sort_by -> Yojson.Safe.t
val pp_position_sort_by : Format.formatter -> position_sort_by -> unit
val show_position_sort_by : position_sort_by -> string
val equal_position_sort_by : position_sort_by -> position_sort_by -> bool

(** {1 Trade Parameters} *)

(** Filter type for trades endpoint *)
type filter_type =
  | CASH          (** Filter by cash amount *)
  | TOKENS_FILTER (** Filter by token amount *)

val string_of_filter_type : filter_type -> string
val filter_type_of_yojson : Yojson.Safe.t -> filter_type
val yojson_of_filter_type : filter_type -> Yojson.Safe.t
val pp_filter_type : Format.formatter -> filter_type -> unit
val show_filter_type : filter_type -> string
val equal_filter_type : filter_type -> filter_type -> bool

(** {1 Activity Parameters} *)

(** Sort field for activity endpoint *)
type activity_sort_by =
  | TIMESTAMP   (** Timestamp *)
  | TOKENS_SORT (** Token amount *)
  | CASH_SORT   (** Cash amount *)

val string_of_activity_sort_by : activity_sort_by -> string
val activity_sort_by_of_yojson : Yojson.Safe.t -> activity_sort_by
val yojson_of_activity_sort_by : activity_sort_by -> Yojson.Safe.t
val pp_activity_sort_by : Format.formatter -> activity_sort_by -> unit
val show_activity_sort_by : activity_sort_by -> string
val equal_activity_sort_by : activity_sort_by -> activity_sort_by -> bool

(** {1 Closed Position Parameters} *)

(** Sort field for closed positions endpoint *)
type closed_position_sort_by =
  | REALIZEDPNL   (** Realized profit/loss *)
  | TITLE_SORT    (** Title alphabetically *)
  | PRICE_SORT    (** Price *)
  | AVGPRICE_SORT (** Average price *)
  | TIMESTAMP_SORT (** Timestamp *)

val string_of_closed_position_sort_by : closed_position_sort_by -> string
val closed_position_sort_by_of_yojson : Yojson.Safe.t -> closed_position_sort_by
val yojson_of_closed_position_sort_by : closed_position_sort_by -> Yojson.Safe.t
val pp_closed_position_sort_by : Format.formatter -> closed_position_sort_by -> unit
val show_closed_position_sort_by : closed_position_sort_by -> string
val equal_closed_position_sort_by : closed_position_sort_by -> closed_position_sort_by -> bool

(** {1 Time Period} *)

(** Time period for aggregated data *)
type time_period =
  | DAY   (** Last 24 hours *)
  | WEEK  (** Last 7 days *)
  | MONTH (** Last 30 days *)
  | ALL   (** All time *)

val string_of_time_period : time_period -> string
val time_period_of_yojson : Yojson.Safe.t -> time_period
val yojson_of_time_period : time_period -> Yojson.Safe.t
val pp_time_period : Format.formatter -> time_period -> unit
val show_time_period : time_period -> string
val equal_time_period : time_period -> time_period -> bool

(** {1 Leaderboard Parameters} *)

(** Market category for leaderboard filtering *)
type leaderboard_category =
  | OVERALL   (** All markets *)
  | POLITICS  (** Political markets *)
  | SPORTS    (** Sports markets *)
  | CRYPTO    (** Cryptocurrency markets *)
  | CULTURE   (** Culture/entertainment markets *)
  | MENTIONS  (** Social mentions markets *)
  | WEATHER   (** Weather markets *)
  | ECONOMICS (** Economics markets *)
  | TECH      (** Technology markets *)
  | FINANCE   (** Finance markets *)

val string_of_leaderboard_category : leaderboard_category -> string
val leaderboard_category_of_yojson : Yojson.Safe.t -> leaderboard_category
val yojson_of_leaderboard_category : leaderboard_category -> Yojson.Safe.t
val pp_leaderboard_category : Format.formatter -> leaderboard_category -> unit
val show_leaderboard_category : leaderboard_category -> string
val equal_leaderboard_category : leaderboard_category -> leaderboard_category -> bool

(** Ordering criteria for trader leaderboard *)
type leaderboard_order_by =
  | PNL (** Order by profit/loss *)
  | VOL (** Order by volume *)

val string_of_leaderboard_order_by : leaderboard_order_by -> string
val leaderboard_order_by_of_yojson : Yojson.Safe.t -> leaderboard_order_by
val yojson_of_leaderboard_order_by : leaderboard_order_by -> Yojson.Safe.t
val pp_leaderboard_order_by : Format.formatter -> leaderboard_order_by -> unit
val show_leaderboard_order_by : leaderboard_order_by -> string
val equal_leaderboard_order_by : leaderboard_order_by -> leaderboard_order_by -> bool
