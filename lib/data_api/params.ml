(** Query parameter types for the Polymarket Data API.

    These types correspond to the query parameters defined in the OpenAPI spec
    for the Data API endpoints.
*)

(** {1 Sort Direction} *)

type sort_direction =
  | ASC
  | DESC
[@@deriving yojson, show, eq]

let string_of_sort_direction = function
  | ASC -> "ASC"
  | DESC -> "DESC"

(** {1 Position Parameters} *)

type position_sort_by =
  | CURRENT
  | INITIAL
  | TOKENS
  | CASHPNL
  | PERCENTPNL
  | TITLE
  | RESOLVING
  | PRICE
  | AVGPRICE
[@@deriving yojson, show, eq]

let string_of_position_sort_by = function
  | CURRENT -> "CURRENT"
  | INITIAL -> "INITIAL"
  | TOKENS -> "TOKENS"
  | CASHPNL -> "CASHPNL"
  | PERCENTPNL -> "PERCENTPNL"
  | TITLE -> "TITLE"
  | RESOLVING -> "RESOLVING"
  | PRICE -> "PRICE"
  | AVGPRICE -> "AVGPRICE"

(** {1 Trade Parameters} *)

type filter_type =
  | CASH
  | TOKENS_FILTER
[@@deriving yojson, show, eq]

let string_of_filter_type = function
  | CASH -> "CASH"
  | TOKENS_FILTER -> "TOKENS"

(** {1 Activity Parameters} *)

type activity_sort_by =
  | TIMESTAMP
  | TOKENS_SORT
  | CASH_SORT
[@@deriving yojson, show, eq]

let string_of_activity_sort_by = function
  | TIMESTAMP -> "TIMESTAMP"
  | TOKENS_SORT -> "TOKENS"
  | CASH_SORT -> "CASH"

(** {1 Closed Position Parameters} *)

type closed_position_sort_by =
  | REALIZEDPNL
  | TITLE_SORT
  | PRICE_SORT
  | AVGPRICE_SORT
  | TIMESTAMP_SORT
[@@deriving yojson, show, eq]

let string_of_closed_position_sort_by = function
  | REALIZEDPNL -> "REALIZEDPNL"
  | TITLE_SORT -> "TITLE"
  | PRICE_SORT -> "PRICE"
  | AVGPRICE_SORT -> "AVGPRICE"
  | TIMESTAMP_SORT -> "TIMESTAMP"

(** {1 Time Period} *)

type time_period =
  | DAY
  | WEEK
  | MONTH
  | ALL
[@@deriving yojson, show, eq]

let string_of_time_period = function
  | DAY -> "DAY"
  | WEEK -> "WEEK"
  | MONTH -> "MONTH"
  | ALL -> "ALL"

(** {1 Leaderboard Parameters} *)

type leaderboard_category =
  | OVERALL
  | POLITICS
  | SPORTS
  | CRYPTO
  | CULTURE
  | MENTIONS
  | WEATHER
  | ECONOMICS
  | TECH
  | FINANCE
[@@deriving yojson, show, eq]

let string_of_leaderboard_category = function
  | OVERALL -> "OVERALL"
  | POLITICS -> "POLITICS"
  | SPORTS -> "SPORTS"
  | CRYPTO -> "CRYPTO"
  | CULTURE -> "CULTURE"
  | MENTIONS -> "MENTIONS"
  | WEATHER -> "WEATHER"
  | ECONOMICS -> "ECONOMICS"
  | TECH -> "TECH"
  | FINANCE -> "FINANCE"

type leaderboard_order_by =
  | PNL
  | VOL
[@@deriving yojson, show, eq]

let string_of_leaderboard_order_by = function
  | PNL -> "PNL"
  | VOL -> "VOL"
