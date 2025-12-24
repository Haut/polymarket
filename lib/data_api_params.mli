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

(** {1 Trade Parameters} *)

(** Filter type for trades endpoint *)
type filter_type =
  | CASH          (** Filter by cash amount *)
  | TOKENS_FILTER (** Filter by token amount *)

val string_of_filter_type : filter_type -> string

(** {1 Activity Parameters} *)

(** Sort field for activity endpoint *)
type activity_sort_by =
  | TIMESTAMP   (** Timestamp *)
  | TOKENS_SORT (** Token amount *)
  | CASH_SORT   (** Cash amount *)

val string_of_activity_sort_by : activity_sort_by -> string

(** {1 Closed Position Parameters} *)

(** Sort field for closed positions endpoint *)
type closed_position_sort_by =
  | REALIZEDPNL   (** Realized profit/loss *)
  | TITLE_SORT    (** Title alphabetically *)
  | PRICE_SORT    (** Price *)
  | AVGPRICE_SORT (** Average price *)
  | TIMESTAMP_SORT (** Timestamp *)

val string_of_closed_position_sort_by : closed_position_sort_by -> string

(** {1 Time Period} *)

(** Time period for aggregated data *)
type time_period =
  | DAY   (** Last 24 hours *)
  | WEEK  (** Last 7 days *)
  | MONTH (** Last 30 days *)
  | ALL   (** All time *)

val string_of_time_period : time_period -> string

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

(** Ordering criteria for trader leaderboard *)
type leaderboard_order_by =
  | PNL (** Order by profit/loss *)
  | VOL (** Order by volume *)

val string_of_leaderboard_order_by : leaderboard_order_by -> string
