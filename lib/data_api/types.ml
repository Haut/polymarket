(** Data API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    data-api-openapi.yaml for the Polymarket Data API
    (https://data-api.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Query Parameter Enums} *)

module Sort_direction = struct
  type t = Asc | Desc [@@deriving enum]
end

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

module Side = Polymarket_common.Primitives.Side
(** Re-export shared Side module from Common.Primitives *)

module Activity_type = struct
  type t = Trade | Split | Merge | Redeem | Reward | Conversion
  [@@deriving enum]
end

(** {1 Response Types} *)

type health_response = { data : string } [@@deriving yojson, show, eq]
(** Health check response *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors *)

let error_to_string = Polymarket_http.Client.error_to_string
let pp_error = Polymarket_http.Client.pp_error

(** {1 Domain Models} *)

type position = {
  proxy_wallet : Polymarket_common.Primitives.Address.t; [@key "proxyWallet"]
  asset : string;
  condition_id : Polymarket_common.Primitives.Hash64.t; [@key "conditionId"]
  size : float;
  avg_price : float; [@key "avgPrice"]
  initial_value : float; [@key "initialValue"]
  current_value : float; [@key "currentValue"]
  cash_pnl : float; [@key "cashPnl"]
  percent_pnl : float; [@key "percentPnl"]
  total_bought : float; [@key "totalBought"]
  realized_pnl : float; [@key "realizedPnl"]
  percent_realized_pnl : float; [@key "percentRealizedPnl"]
  cur_price : float; [@key "curPrice"]
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
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Position in a market *)

type closed_position = {
  proxy_wallet : Polymarket_common.Primitives.Address.t; [@key "proxyWallet"]
  asset : string;
  condition_id : Polymarket_common.Primitives.Hash64.t; [@key "conditionId"]
  avg_price : float; [@key "avgPrice"]
  total_bought : float; [@key "totalBought"]
  realized_pnl : float; [@key "realizedPnl"]
  cur_price : float; [@key "curPrice"]
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
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Closed position in a market *)

type trade = {
  proxy_wallet : Polymarket_common.Primitives.Address.t; [@key "proxyWallet"]
  side : Side.t;
  asset : string;
  condition_id : Polymarket_common.Primitives.Hash64.t; [@key "conditionId"]
  size : float;
  price : float;
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
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Trade record *)

type activity = {
  proxy_wallet : Polymarket_common.Primitives.Address.t; [@key "proxyWallet"]
  timestamp : int64;
  condition_id : Polymarket_common.Primitives.Hash64.t; [@key "conditionId"]
  activity_type : Activity_type.t; [@key "type"]
  size : float;
  usdc_size : float; [@key "usdcSize"]
  transaction_hash : string; [@key "transactionHash"]
  price : float;
  asset : string;
  side : Side.t;
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
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Activity record *)

type holder = {
  proxy_wallet : Polymarket_common.Primitives.Address.t; [@key "proxyWallet"]
  bio : string;
  asset : string;
  pseudonym : string;
  amount : float;
  display_username_public : bool; [@key "displayUsernamePublic"]
  outcome_index : int; [@key "outcomeIndex"]
  name : string;
  profile_image : string; [@key "profileImage"]
  profile_image_optimized : string; [@key "profileImageOptimized"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Holder of a position *)

type meta_holder = { token : string; holders : holder list }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Meta holder with token and list of holders *)

type traded = { user : Polymarket_common.Primitives.Address.t; traded : int }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Traded record *)

type revision_entry = { revision : string; timestamp : int }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Revision entry *)

type revision_payload = {
  question_id : Polymarket_common.Primitives.Hash64.t; [@key "questionID"]
  revisions : revision_entry list;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Revision payload *)

type value = { user : Polymarket_common.Primitives.Address.t; value : float }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Value record *)

type open_interest = {
  market : string;  (** Can be "GLOBAL" or a condition ID hash *)
  value : float;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Open interest for a market *)

type market_volume = {
  market : Polymarket_common.Primitives.Hash64.t option; [@yojson.option]
  value : float option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Market volume *)

type live_volume = {
  total : float option; [@yojson.option]
  markets : market_volume list; [@default []]
}
[@@deriving yojson, show, eq]
(** Live volume *)

(** Custom deserializer for live_volume that handles null markets *)
let live_volume_of_yojson json =
  match json with
  | `Assoc fields ->
      let total =
        match List.assoc_opt "total" fields with
        | Some (`Float f) -> Some f
        | Some (`Int i) -> Some (float_of_int i)
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
  | _ -> failwith "live_volume_of_yojson: expected object"

(** {1 Leaderboard Types} *)

type leaderboard_entry = {
  rank : string;
  builder : string;
  volume : float;
  active_users : int; [@key "activeUsers"]
  verified : bool;
  builder_logo : string; [@key "builderLogo"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Leaderboard entry for builders *)

type builder_volume_entry = {
  dt : Polymarket_common.Primitives.Timestamp.t;
  builder : string;
  builder_logo : string; [@key "builderLogo"]
  verified : bool;
  volume : float;
  active_users : int; [@key "activeUsers"]
  rank : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Builder volume entry *)

type trader_leaderboard_entry = {
  rank : string;
  proxy_wallet : Polymarket_common.Primitives.Address.t; [@key "proxyWallet"]
  user_name : string; [@key "userName"]
  vol : float;
  pnl : float;
  profile_image : string; [@key "profileImage"]
  x_username : string; [@key "xUsername"]
  verified_badge : bool; [@key "verifiedBadge"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Trader leaderboard entry *)
