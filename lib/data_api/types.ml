(** Data API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    data-api-openapi.yaml for the Polymarket Data API
    (https://data-api.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Query Parameter Enums} *)

module Sort_direction = struct
  type t = Asc | Desc [@@deriving yojson, show, eq]

  let to_string = function Asc -> "ASC" | Desc -> "DESC"

  let of_string = function
    | "ASC" | "asc" -> Asc
    | "DESC" | "desc" -> Desc
    | s -> failwith ("Unknown sort_direction: " ^ s)
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
  [@@deriving yojson, show, eq]

  let to_string = function
    | Current -> "CURRENT"
    | Initial -> "INITIAL"
    | Tokens -> "TOKENS"
    | Cashpnl -> "CASHPNL"
    | Percentpnl -> "PERCENTPNL"
    | Title -> "TITLE"
    | Resolving -> "RESOLVING"
    | Price -> "PRICE"
    | Avgprice -> "AVGPRICE"

  let of_string = function
    | "CURRENT" | "current" -> Current
    | "INITIAL" | "initial" -> Initial
    | "TOKENS" | "tokens" -> Tokens
    | "CASHPNL" | "cashpnl" -> Cashpnl
    | "PERCENTPNL" | "percentpnl" -> Percentpnl
    | "TITLE" | "title" -> Title
    | "RESOLVING" | "resolving" -> Resolving
    | "PRICE" | "price" -> Price
    | "AVGPRICE" | "avgprice" -> Avgprice
    | s -> failwith ("Unknown position_sort_by: " ^ s)
end

module Filter_type = struct
  type t = Cash | Tokens [@@deriving yojson, show, eq]

  let to_string = function Cash -> "CASH" | Tokens -> "TOKENS"

  let of_string = function
    | "CASH" | "cash" -> Cash
    | "TOKENS" | "tokens" -> Tokens
    | s -> failwith ("Unknown filter_type: " ^ s)
end

module Activity_sort_by = struct
  type t = Timestamp | Tokens | Cash [@@deriving yojson, show, eq]

  let to_string = function
    | Timestamp -> "TIMESTAMP"
    | Tokens -> "TOKENS"
    | Cash -> "CASH"

  let of_string = function
    | "TIMESTAMP" | "timestamp" -> Timestamp
    | "TOKENS" | "tokens" -> Tokens
    | "CASH" | "cash" -> Cash
    | s -> failwith ("Unknown activity_sort_by: " ^ s)
end

module Closed_position_sort_by = struct
  type t = Realizedpnl | Title | Price | Avgprice | Timestamp
  [@@deriving yojson, show, eq]

  let to_string = function
    | Realizedpnl -> "REALIZEDPNL"
    | Title -> "TITLE"
    | Price -> "PRICE"
    | Avgprice -> "AVGPRICE"
    | Timestamp -> "TIMESTAMP"

  let of_string = function
    | "REALIZEDPNL" | "realizedpnl" -> Realizedpnl
    | "TITLE" | "title" -> Title
    | "PRICE" | "price" -> Price
    | "AVGPRICE" | "avgprice" -> Avgprice
    | "TIMESTAMP" | "timestamp" -> Timestamp
    | s -> failwith ("Unknown closed_position_sort_by: " ^ s)
end

module Time_period = struct
  type t = Day | Week | Month | All [@@deriving yojson, show, eq]

  let to_string = function
    | Day -> "DAY"
    | Week -> "WEEK"
    | Month -> "MONTH"
    | All -> "ALL"

  let of_string = function
    | "DAY" | "day" -> Day
    | "WEEK" | "week" -> Week
    | "MONTH" | "month" -> Month
    | "ALL" | "all" -> All
    | s -> failwith ("Unknown time_period: " ^ s)
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
  [@@deriving yojson, show, eq]

  let to_string = function
    | Overall -> "OVERALL"
    | Politics -> "POLITICS"
    | Sports -> "SPORTS"
    | Crypto -> "CRYPTO"
    | Culture -> "CULTURE"
    | Mentions -> "MENTIONS"
    | Weather -> "WEATHER"
    | Economics -> "ECONOMICS"
    | Tech -> "TECH"
    | Finance -> "FINANCE"

  let of_string = function
    | "OVERALL" | "overall" -> Overall
    | "POLITICS" | "politics" -> Politics
    | "SPORTS" | "sports" -> Sports
    | "CRYPTO" | "crypto" -> Crypto
    | "CULTURE" | "culture" -> Culture
    | "MENTIONS" | "mentions" -> Mentions
    | "WEATHER" | "weather" -> Weather
    | "ECONOMICS" | "economics" -> Economics
    | "TECH" | "tech" -> Tech
    | "FINANCE" | "finance" -> Finance
    | s -> failwith ("Unknown leaderboard_category: " ^ s)
end

module Leaderboard_order_by = struct
  type t = Pnl | Vol [@@deriving yojson, show, eq]

  let to_string = function Pnl -> "PNL" | Vol -> "VOL"

  let of_string = function
    | "PNL" | "pnl" -> Pnl
    | "VOL" | "vol" -> Vol
    | s -> failwith ("Unknown leaderboard_order_by: " ^ s)
end

(** {1 Domain Enums} *)

module Side = Polymarket_common.Primitives.Side
(** Re-export shared Side module from Common.Primitives *)

module Activity_type = struct
  type t = Trade | Split | Merge | Redeem | Reward | Conversion
  [@@deriving show, eq]

  let to_string = function
    | Trade -> "TRADE"
    | Split -> "SPLIT"
    | Merge -> "MERGE"
    | Redeem -> "REDEEM"
    | Reward -> "REWARD"
    | Conversion -> "CONVERSION"

  let of_string = function
    | "TRADE" | "trade" -> Trade
    | "SPLIT" | "split" -> Split
    | "MERGE" | "merge" -> Merge
    | "REDEEM" | "redeem" -> Redeem
    | "REWARD" | "reward" -> Reward
    | "CONVERSION" | "conversion" -> Conversion
    | s -> failwith ("Unknown activity_type: " ^ s)

  let t_of_yojson = function
    | `String s -> of_string s
    | _ -> failwith "Activity_type.t_of_yojson: expected string"

  let yojson_of_t t = `String (to_string t)
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
