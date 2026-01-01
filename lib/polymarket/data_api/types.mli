(** Data API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    data-api-openapi.yaml for the Polymarket Data API
    (https://data-api.polymarket.com). *)

(** {1 Query Parameter Enums} *)

module Sort_direction : sig
  type t = Asc | Desc [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

module Position_sort_by : sig
  type t =
    | Current
    | Initial
    | Tokens
    | Cashpnl
    | Percentpnl
    | Title
    | Resolving
    | Price
    | Avgprice
  [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

module Filter_type : sig
  type t = Cash | Tokens [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

module Activity_sort_by : sig
  type t = Timestamp | Tokens | Cash [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

module Closed_position_sort_by : sig
  type t = Realizedpnl | Title | Price | Avgprice | Timestamp
  [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

module Time_period : sig
  type t = Day | Week | Month | All [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

module Leaderboard_category : sig
  type t =
    | Overall
    | Politics
    | Sports
    | Crypto
    | Culture
    | Mentions
    | Weather
    | Economics
    | Tech
    | Finance
  [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

module Leaderboard_order_by : sig
  type t = Pnl | Vol [@@deriving yojson, eq]

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
end

(** {1 Domain Enums} *)

module Side = Polymarket_common.Primitives.Side

module Activity_type : sig
  type t = Trade | Split | Merge | Redeem | Reward | Conversion
  [@@deriving eq]

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
end

(** {1 Response Types} *)

type health_response = { data : string } [@@deriving yojson, show, eq]
(** Health check response *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors (alias to
    Polymarket_http.Client.error) *)

val error_to_string : error -> string
(** Convert error to human-readable string *)

val pp_error : Format.formatter -> error -> unit
(** Pretty printer for errors *)

(** {1 Domain Models} *)

type position = {
  proxy_wallet : Polymarket_common.Primitives.Address.t;
  asset : string;
  condition_id : Polymarket_common.Primitives.Hash64.t;
  size : float;
  avg_price : float;
  initial_value : float;
  current_value : float;
  cash_pnl : float;
  percent_pnl : float;
  total_bought : float;
  realized_pnl : float;
  percent_realized_pnl : float;
  cur_price : float;
  redeemable : bool;
  mergeable : bool;
  title : string;
  slug : string;
  icon : string;
  event_slug : string;
  outcome : string;
  outcome_index : int;
  opposite_outcome : string;
  opposite_asset : string;
  end_date : string;
  negative_risk : bool;
}
[@@deriving yojson, show, eq]
(** Position in a market *)

type closed_position = {
  proxy_wallet : Polymarket_common.Primitives.Address.t;
  asset : string;
  condition_id : Polymarket_common.Primitives.Hash64.t;
  avg_price : float;
  total_bought : float;
  realized_pnl : float;
  cur_price : float;
  timestamp : int64;
  title : string;
  slug : string;
  icon : string;
  event_slug : string;
  outcome : string;
  outcome_index : int;
  opposite_outcome : string;
  opposite_asset : string;
  end_date : string;
}
[@@deriving yojson, show, eq]
(** Closed position in a market *)

type trade = {
  proxy_wallet : Polymarket_common.Primitives.Address.t;
  side : Side.t;
  asset : string;
  condition_id : Polymarket_common.Primitives.Hash64.t;
  size : float;
  price : float;
  timestamp : int64;
  title : string;
  slug : string;
  icon : string;
  event_slug : string;
  outcome : string;
  outcome_index : int;
  name : string;
  pseudonym : string;
  bio : string;
  profile_image : string;
  profile_image_optimized : string;
  transaction_hash : string;
}
[@@deriving yojson, show, eq]
(** Trade record *)

type activity = {
  proxy_wallet : Polymarket_common.Primitives.Address.t;
  timestamp : int64;
  condition_id : Polymarket_common.Primitives.Hash64.t;
  activity_type : Activity_type.t;
  size : float;
  usdc_size : float;
  transaction_hash : string;
  price : float;
  asset : string;
  side : Side.t;
  outcome_index : int;
  title : string;
  slug : string;
  icon : string;
  event_slug : string;
  outcome : string;
  name : string;
  pseudonym : string;
  bio : string;
  profile_image : string;
  profile_image_optimized : string;
}
[@@deriving yojson, show, eq]
(** Activity record *)

type holder = {
  proxy_wallet : Polymarket_common.Primitives.Address.t;
  bio : string;
  asset : string;
  pseudonym : string;
  amount : float;
  display_username_public : bool;
  outcome_index : int;
  name : string;
  profile_image : string;
  profile_image_optimized : string;
}
[@@deriving yojson, show, eq]
(** Holder of a position *)

type meta_holder = { token : string; holders : holder list }
[@@deriving yojson, show, eq]
(** Meta holder with token and list of holders *)

type traded = { user : Polymarket_common.Primitives.Address.t; traded : int }
[@@deriving yojson, show, eq]
(** Traded record *)

type revision_entry = { revision : string; timestamp : int }
[@@deriving yojson, show, eq]
(** Revision entry *)

type revision_payload = {
  question_id : Polymarket_common.Primitives.Hash64.t;
  revisions : revision_entry list;
}
[@@deriving yojson, show, eq]
(** Revision payload *)

type value = { user : Polymarket_common.Primitives.Address.t; value : float }
[@@deriving yojson, show, eq]
(** Value record *)

type open_interest = {
  market : string;  (** Can be "GLOBAL" or a condition ID hash *)
  value : float;
}
[@@deriving yojson, show, eq]
(** Open interest for a market *)

type market_volume = {
  market : Polymarket_common.Primitives.Hash64.t option;
  value : float option;
}
[@@deriving yojson, show, eq]
(** Market volume *)

type live_volume = { total : float option; markets : market_volume list }
[@@deriving yojson, show, eq]
(** Live volume *)

(** {1 Leaderboard Types} *)

type leaderboard_entry = {
  rank : string;
  builder : string;
  volume : float;
  active_users : int;
  verified : bool;
  builder_logo : string;
}
[@@deriving yojson, show, eq]
(** Leaderboard entry for builders *)

type builder_volume_entry = {
  dt : Polymarket_common.Primitives.Timestamp.t;
  builder : string;
  builder_logo : string;
  verified : bool;
  volume : float;
  active_users : int;
  rank : string;
}
[@@deriving yojson, show, eq]
(** Builder volume entry *)

type trader_leaderboard_entry = {
  rank : string;
  proxy_wallet : Polymarket_common.Primitives.Address.t;
  user_name : string;
  vol : float;
  pnl : float;
  profile_image : string;
  x_username : string;
  verified_badge : bool;
}
[@@deriving yojson, show, eq]
(** Trader leaderboard entry *)
