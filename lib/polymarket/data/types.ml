(** Data API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    data-api-openapi.yaml for the Polymarket Data API
    (https://data-api.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module P = Common.Primitives

(** Side option that treats empty string as None *)
module Side_option = struct
  type t = P.Side.t option [@@deriving show, eq]

  let t_of_yojson = function
    | `String "" -> None
    | json -> Some (P.Side.t_of_yojson json)

  let yojson_of_t = function
    | None -> `String ""
    | Some s -> P.Side.yojson_of_t s
end

(** {1 Query Parameter Enums} *)

module Sort_direction = P.Sort_dir
(** Re-export shared Sort_dir module from P *)

module Position_sort_by = struct
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
  [@@deriving enum]
end

module Filter_type = struct
  type t = Cash | Tokens [@@deriving enum]
end

module Activity_sort_by = struct
  type t = Timestamp | Tokens | Cash [@@deriving enum]
end

module Closed_position_sort_by = struct
  type t = Realizedpnl | Title | Price | Avgprice | Timestamp
  [@@deriving enum]
end

module Time_period = struct
  type t = Day | Week | Month | All [@@deriving enum]
end

module Leaderboard_category = struct
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
  [@@deriving enum]
end

module Leaderboard_order_by = struct
  type t = Pnl | Vol [@@deriving enum]
end

(** {1 Domain Enums} *)

module Side = P.Side
(** Re-export shared Side module from P *)

module Activity_type = struct
  type t = Trade | Split | Merge | Redeem | Reward | Conversion
  [@@deriving enum]
end

(** {1 Response Types} *)

type health_response = { data : string }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Health check response *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors *)

let error_to_string = Polymarket_http.Client.error_to_string
let pp_error = Polymarket_http.Client.pp_error

(** {1 Domain Models} *)

type position = {
  proxy_wallet : P.Address.t; [@key "proxyWallet"]
  asset : string;
  condition_id : P.Hash64.t; [@key "conditionId"]
  size : P.Decimal.t;
  avg_price : P.Decimal.t; [@key "avgPrice"]
  initial_value : P.Decimal.t; [@key "initialValue"]
  current_value : P.Decimal.t; [@key "currentValue"]
  cash_pnl : P.Decimal.t; [@key "cashPnl"]
  percent_pnl : P.Decimal.t; [@key "percentPnl"]
  total_bought : P.Decimal.t; [@key "totalBought"]
  realized_pnl : P.Decimal.t; [@key "realizedPnl"]
  percent_realized_pnl : P.Decimal.t; [@key "percentRealizedPnl"]
  cur_price : P.Decimal.t; [@key "curPrice"]
  redeemable : bool;
  mergeable : bool;
  title : string;
  slug : string;
  icon : string;
  event_slug : string; [@key "eventSlug"]
  outcome : string;
  outcome_index : int; [@key "outcomeIndex"]
  opposite_outcome : string; [@key "oppositeOutcome"]
  opposite_asset : string; [@key "oppositeAsset"]
  end_date : string; [@key "endDate"]
  negative_risk : bool; [@key "negativeRisk"]
  event_id : string; [@key "eventId"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Position in a market *)

type closed_position = {
  proxy_wallet : P.Address.t; [@key "proxyWallet"]
  asset : string;
  condition_id : P.Hash64.t; [@key "conditionId"]
  avg_price : P.Decimal.t; [@key "avgPrice"]
  total_bought : P.Decimal.t; [@key "totalBought"]
  realized_pnl : P.Decimal.t; [@key "realizedPnl"]
  cur_price : P.Decimal.t; [@key "curPrice"]
  timestamp : int64;
  title : string;
  slug : string;
  icon : string;
  event_slug : string; [@key "eventSlug"]
  outcome : string;
  outcome_index : int; [@key "outcomeIndex"]
  opposite_outcome : string; [@key "oppositeOutcome"]
  opposite_asset : string; [@key "oppositeAsset"]
  end_date : string; [@key "endDate"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Closed position in a market *)

type trade = {
  proxy_wallet : P.Address.t; [@key "proxyWallet"]
  side : Side.t;
  asset : string;
  condition_id : P.Hash64.t; [@key "conditionId"]
  size : P.Decimal.t;
  price : P.Decimal.t;
  timestamp : int64;
  title : string;
  slug : string;
  icon : string;
  event_slug : string; [@key "eventSlug"]
  outcome : string;
  outcome_index : int; [@key "outcomeIndex"]
  name : string;
  pseudonym : string;
  bio : string;
  profile_image : string; [@key "profileImage"]
  profile_image_optimized : string; [@key "profileImageOptimized"]
  transaction_hash : string; [@key "transactionHash"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Trade record *)

type activity = {
  proxy_wallet : P.Address.t; [@key "proxyWallet"]
  timestamp : int64;
  condition_id : P.Hash64.t; [@key "conditionId"]
  activity_type : Activity_type.t; [@key "type"]
  size : P.Decimal.t;
  usdc_size : P.Decimal.t; [@key "usdcSize"]
  transaction_hash : string; [@key "transactionHash"]
  price : P.Decimal.t;
  asset : string;
  side : Side_option.t;
  outcome_index : int; [@key "outcomeIndex"]
  title : string;
  slug : string;
  icon : string;
  event_slug : string; [@key "eventSlug"]
  outcome : string;
  name : string;
  pseudonym : string;
  bio : string;
  profile_image : string; [@key "profileImage"]
  profile_image_optimized : string; [@key "profileImageOptimized"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Activity record *)

type holder = {
  proxy_wallet : P.Address.t; [@key "proxyWallet"]
  bio : string;
  asset : string;
  pseudonym : string;
  amount : P.Decimal.t;
  display_username_public : bool; [@key "displayUsernamePublic"]
  outcome_index : int; [@key "outcomeIndex"]
  name : string;
  profile_image : string; [@key "profileImage"]
  profile_image_optimized : string; [@key "profileImageOptimized"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Holder of a position *)

type meta_holder = { token : string; holders : holder list }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Meta holder with token and list of holders *)

type traded = { user : P.Address.t; traded : int }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Traded record *)

type revision_entry = { revision : string; timestamp : int }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Revision entry *)

type revision_payload = {
  question_id : P.Hash64.t; [@key "questionID"]
  revisions : revision_entry list;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Revision payload *)

type value = { user : P.Address.t; value : P.Decimal.t }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Value record *)

type open_interest = {
  market : string;  (** Can be "GLOBAL" or a condition ID hash *)
  value : P.Decimal.t;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Open interest for a market *)

type market_volume = {
  market : P.Hash64.t option; [@yojson.option]
  value : P.Decimal.t option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Market volume *)

type live_volume = {
  total : P.Decimal.t option; [@yojson.option]
  markets : market_volume list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Live volume *)

(** Custom deserializer for live_volume that handles null markets *)
let live_volume_of_yojson json =
  match json with
  | `Assoc fields ->
      let total =
        match List.assoc_opt "total" fields with
        | Some (`Float f) -> Some (P.Decimal.of_float f)
        | Some (`Int i) -> Some (P.Decimal.of_int i)
        | Some (`String s) -> Some (P.Decimal.of_string s)
        | Some `Null | None -> None
        | _ -> None
      in
      let markets =
        match List.assoc_opt "markets" fields with
        | Some `Null | None -> []
        | Some (`List items) -> List.map market_volume_of_yojson items
        | _ -> []
      in
      { total; markets }
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "live_volume: expected object", json))

(** {1 Leaderboard Types} *)

type leaderboard_entry = {
  rank : string;
  builder : string;
  volume : P.Decimal.t;
  active_users : int; [@key "activeUsers"]
  verified : bool;
  builder_logo : string; [@key "builderLogo"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Leaderboard entry for builders *)

type builder_volume_entry = {
  dt : P.Timestamp.t;
  builder : string;
  builder_logo : string; [@key "builderLogo"]
  verified : bool;
  volume : P.Decimal.t;
  active_users : int; [@key "activeUsers"]
  rank : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Builder volume entry *)

type trader_leaderboard_entry = {
  rank : string;
  proxy_wallet : P.Address.t; [@key "proxyWallet"]
  user_name : string; [@key "userName"]
  vol : P.Decimal.t;
  pnl : P.Decimal.t;
  profile_image : string; [@key "profileImage"]
  x_username : string; [@key "xUsername"]
  verified_badge : bool; [@key "verifiedBadge"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Trader leaderboard entry *)
