(** Data API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    data-api-openapi.yaml for the Polymarket Data API
    (https://data-api.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Primitive Types} *)

type address = string [@@deriving yojson, show, eq]
(** User Profile Address (0x-prefixed, 40 hex chars).
    Pattern: ^0x[a-fA-F0-9]{40}$ *)

type hash64 = string [@@deriving yojson, show, eq]
(** 0x-prefixed 64-hex string.
    Pattern: ^0x[a-fA-F0-9]{64}$ *)

(** {1 Query Parameter Enums} *)

type sort_direction = ASC | DESC [@@deriving yojson, show, eq]

let string_of_sort_direction = function ASC -> "ASC" | DESC -> "DESC"

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

type filter_type = CASH | TOKENS_FILTER [@@deriving yojson, show, eq]

let string_of_filter_type = function
  | CASH -> "CASH"
  | TOKENS_FILTER -> "TOKENS"

type activity_sort_by = TIMESTAMP | TOKENS_SORT | CASH_SORT
[@@deriving yojson, show, eq]

let string_of_activity_sort_by = function
  | TIMESTAMP -> "TIMESTAMP"
  | TOKENS_SORT -> "TOKENS"
  | CASH_SORT -> "CASH"

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

type time_period = DAY | WEEK | MONTH | ALL [@@deriving yojson, show, eq]

let string_of_time_period = function
  | DAY -> "DAY"
  | WEEK -> "WEEK"
  | MONTH -> "MONTH"
  | ALL -> "ALL"

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

type leaderboard_order_by = PNL | VOL [@@deriving yojson, show, eq]

let string_of_leaderboard_order_by = function PNL -> "PNL" | VOL -> "VOL"

(** {1 Domain Enums} *)

(** Trade side enum *)
type side = BUY | SELL [@@deriving show, eq]

let string_of_side = function BUY -> "BUY" | SELL -> "SELL"

let side_of_string = function
  | "BUY" | "buy" -> BUY
  | "SELL" | "sell" -> SELL
  | s -> failwith ("Unknown side: " ^ s)

let side_of_yojson = function
  | `String s -> side_of_string s
  | _ -> failwith "side_of_yojson: expected string"

let yojson_of_side side = `String (string_of_side side)

(** Activity type enum *)
type activity_type = TRADE | SPLIT | MERGE | REDEEM | REWARD | CONVERSION
[@@deriving show, eq]

let string_of_activity_type = function
  | TRADE -> "TRADE"
  | SPLIT -> "SPLIT"
  | MERGE -> "MERGE"
  | REDEEM -> "REDEEM"
  | REWARD -> "REWARD"
  | CONVERSION -> "CONVERSION"

let activity_type_of_string = function
  | "TRADE" | "trade" -> TRADE
  | "SPLIT" | "split" -> SPLIT
  | "MERGE" | "merge" -> MERGE
  | "REDEEM" | "redeem" -> REDEEM
  | "REWARD" | "reward" -> REWARD
  | "CONVERSION" | "conversion" -> CONVERSION
  | s -> failwith ("Unknown activity_type: " ^ s)

let activity_type_of_yojson = function
  | `String s -> activity_type_of_string s
  | _ -> failwith "activity_type_of_yojson: expected string"

let yojson_of_activity_type t = `String (string_of_activity_type t)

(** {1 Response Types} *)

type health_response = { data : string } [@@deriving yojson, show, eq]
(** Health check response *)

type error_response = Http_client.Client.error_response = { error : string }
[@@deriving yojson, show, eq]
(** Error response (alias to Http_client.Client.error_response for
    compatibility) *)

(** {1 Domain Models} *)

type position = {
  proxy_wallet : address; [@key "proxyWallet"]
  asset : string;
  condition_id : hash64; [@key "conditionId"]
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
  proxy_wallet : address; [@key "proxyWallet"]
  asset : string;
  condition_id : hash64; [@key "conditionId"]
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
  proxy_wallet : address; [@key "proxyWallet"]
  side : side;
  asset : string;
  condition_id : hash64; [@key "conditionId"]
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
  proxy_wallet : address; [@key "proxyWallet"]
  timestamp : int64;
  condition_id : hash64; [@key "conditionId"]
  activity_type : activity_type; [@key "type"]
  size : float;
  usdc_size : float; [@key "usdcSize"]
  transaction_hash : string; [@key "transactionHash"]
  price : float;
  asset : string;
  side : side;
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
  proxy_wallet : address; [@key "proxyWallet"]
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

type traded = { user : address; traded : int }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Traded record *)

type revision_entry = { revision : string; timestamp : int }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Revision entry *)

type revision_payload = {
  question_id : hash64; [@key "questionID"]
  revisions : revision_entry list;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Revision payload *)

type value = { user : address; value : float }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Value record *)

type open_interest = { market : hash64; value : float }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Open interest for a market *)

type market_volume = {
  market : hash64 option; [@yojson.option]
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
  dt : Common.Primitives.Timestamp.t;
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
  proxy_wallet : address; [@key "proxyWallet"]
  user_name : string; [@key "userName"]
  vol : float;
  pnl : float;
  profile_image : string; [@key "profileImage"]
  x_username : string; [@key "xUsername"]
  verified_badge : bool; [@key "verifiedBadge"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Trader leaderboard entry *)
