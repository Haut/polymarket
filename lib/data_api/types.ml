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

type health_response = { data : string option [@yojson.option] }
[@@deriving yojson, show, eq]
(** Health check response *)

type error_response = Http_client.Client.error_response = { error : string }
[@@deriving yojson, show, eq]
(** Error response (alias to Http_client.Client.error_response for
    compatibility) *)

(** {1 Domain Models} *)

type position = {
  proxy_wallet : address option; [@yojson.option] [@key "proxyWallet"]
  asset : string option; [@yojson.option]
  condition_id : hash64 option; [@yojson.option] [@key "conditionId"]
  size : float option; [@yojson.option]
  avg_price : float option; [@yojson.option] [@key "avgPrice"]
  initial_value : float option; [@yojson.option] [@key "initialValue"]
  current_value : float option; [@yojson.option] [@key "currentValue"]
  cash_pnl : float option; [@yojson.option] [@key "cashPnl"]
  percent_pnl : float option; [@yojson.option] [@key "percentPnl"]
  total_bought : float option; [@yojson.option] [@key "totalBought"]
  realized_pnl : float option; [@yojson.option] [@key "realizedPnl"]
  percent_realized_pnl : float option;
      [@yojson.option] [@key "percentRealizedPnl"]
  cur_price : float option; [@yojson.option] [@key "curPrice"]
  redeemable : bool option; [@yojson.option]
  mergeable : bool option; [@yojson.option]
  title : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  event_slug : string option; [@yojson.option] [@key "eventSlug"]
  outcome : string option; [@yojson.option]
  outcome_index : int option; [@yojson.option] [@key "outcomeIndex"]
  opposite_outcome : string option; [@yojson.option] [@key "oppositeOutcome"]
  opposite_asset : string option; [@yojson.option] [@key "oppositeAsset"]
  end_date : string option; [@yojson.option] [@key "endDate"]
  negative_risk : bool option; [@yojson.option] [@key "negativeRisk"]
}
[@@deriving yojson, show, eq]
(** Position in a market *)

type closed_position = {
  proxy_wallet : address option; [@yojson.option] [@key "proxyWallet"]
  asset : string option; [@yojson.option]
  condition_id : hash64 option; [@yojson.option] [@key "conditionId"]
  avg_price : float option; [@yojson.option] [@key "avgPrice"]
  total_bought : float option; [@yojson.option] [@key "totalBought"]
  realized_pnl : float option; [@yojson.option] [@key "realizedPnl"]
  cur_price : float option; [@yojson.option] [@key "curPrice"]
  timestamp : int64 option; [@yojson.option]
  title : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  event_slug : string option; [@yojson.option] [@key "eventSlug"]
  outcome : string option; [@yojson.option]
  outcome_index : int option; [@yojson.option] [@key "outcomeIndex"]
  opposite_outcome : string option; [@yojson.option] [@key "oppositeOutcome"]
  opposite_asset : string option; [@yojson.option] [@key "oppositeAsset"]
  end_date : string option; [@yojson.option] [@key "endDate"]
}
[@@deriving yojson, show, eq]
(** Closed position in a market *)

type trade = {
  proxy_wallet : address option; [@yojson.option] [@key "proxyWallet"]
  side : side option; [@yojson.option]
  asset : string option; [@yojson.option]
  condition_id : hash64 option; [@yojson.option] [@key "conditionId"]
  size : float option; [@yojson.option]
  price : float option; [@yojson.option]
  timestamp : int64 option; [@yojson.option]
  title : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  event_slug : string option; [@yojson.option] [@key "eventSlug"]
  outcome : string option; [@yojson.option]
  outcome_index : int option; [@yojson.option] [@key "outcomeIndex"]
  name : string option; [@yojson.option]
  pseudonym : string option; [@yojson.option]
  bio : string option; [@yojson.option]
  profile_image : string option; [@yojson.option] [@key "profileImage"]
  profile_image_optimized : string option;
      [@yojson.option] [@key "profileImageOptimized"]
  transaction_hash : string option; [@yojson.option] [@key "transactionHash"]
}
[@@deriving yojson, show, eq]
(** Trade record *)

type activity = {
  proxy_wallet : address option; [@yojson.option] [@key "proxyWallet"]
  timestamp : int64 option; [@yojson.option]
  condition_id : hash64 option; [@yojson.option] [@key "conditionId"]
  activity_type : activity_type option; [@yojson.option] [@key "type"]
  size : float option; [@yojson.option]
  usdc_size : float option; [@yojson.option] [@key "usdcSize"]
  transaction_hash : string option; [@yojson.option] [@key "transactionHash"]
  price : float option; [@yojson.option]
  asset : string option; [@yojson.option]
  side : side option; [@yojson.option]
  outcome_index : int option; [@yojson.option] [@key "outcomeIndex"]
  title : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  event_slug : string option; [@yojson.option] [@key "eventSlug"]
  outcome : string option; [@yojson.option]
  name : string option; [@yojson.option]
  pseudonym : string option; [@yojson.option]
  bio : string option; [@yojson.option]
  profile_image : string option; [@yojson.option] [@key "profileImage"]
  profile_image_optimized : string option;
      [@yojson.option] [@key "profileImageOptimized"]
}
[@@deriving yojson, show, eq]
(** Activity record *)

type holder = {
  proxy_wallet : address option; [@yojson.option] [@key "proxyWallet"]
  bio : string option; [@yojson.option]
  asset : string option; [@yojson.option]
  pseudonym : string option; [@yojson.option]
  amount : float option; [@yojson.option]
  display_username_public : bool option;
      [@yojson.option] [@key "displayUsernamePublic"]
  outcome_index : int option; [@yojson.option] [@key "outcomeIndex"]
  name : string option; [@yojson.option]
  profile_image : string option; [@yojson.option] [@key "profileImage"]
  profile_image_optimized : string option;
      [@yojson.option] [@key "profileImageOptimized"]
}
[@@deriving yojson, show, eq]
(** Holder of a position *)

type meta_holder = {
  token : string option; [@yojson.option]
  holders : holder list option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Meta holder with token and list of holders *)

type traded = {
  user : address option; [@yojson.option]
  traded : int option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Traded record *)

type revision_entry = {
  revision : string option; [@yojson.option]
  timestamp : int option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Revision entry *)

type revision_payload = {
  question_id : hash64 option; [@yojson.option] [@key "questionID"]
  revisions : revision_entry list option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Revision payload *)

type value = {
  user : address option; [@yojson.option]
  value : float option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Value record *)

type open_interest = {
  market : hash64 option; [@yojson.option]
  value : float option; [@yojson.option]
}
[@@deriving yojson, show, eq]
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

type other_size = {
  id : int option; [@yojson.option]
  user : address option; [@yojson.option]
  size : float option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Other size record *)

(** {1 Leaderboard Types} *)

type leaderboard_entry = {
  rank : string option; [@yojson.option]
  builder : string option; [@yojson.option]
  volume : float option; [@yojson.option]
  active_users : int option; [@yojson.option] [@key "activeUsers"]
  verified : bool option; [@yojson.option]
  builder_logo : string option; [@yojson.option] [@key "builderLogo"]
}
[@@deriving yojson, show, eq]
(** Leaderboard entry for builders *)

type builder_volume_entry = {
  dt : string option; [@yojson.option]
  builder : string option; [@yojson.option]
  builder_logo : string option; [@yojson.option] [@key "builderLogo"]
  verified : bool option; [@yojson.option]
  volume : float option; [@yojson.option]
  active_users : int option; [@yojson.option] [@key "activeUsers"]
  rank : string option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Builder volume entry *)

type trader_leaderboard_entry = {
  rank : string option; [@yojson.option]
  proxy_wallet : address option; [@yojson.option] [@key "proxyWallet"]
  user_name : string option; [@yojson.option] [@key "userName"]
  vol : float option; [@yojson.option]
  pnl : float option; [@yojson.option]
  profile_image : string option; [@yojson.option] [@key "profileImage"]
  x_username : string option; [@yojson.option] [@key "xUsername"]
  verified_badge : bool option; [@yojson.option] [@key "verifiedBadge"]
}
[@@deriving yojson, show, eq]
(** Trader leaderboard entry *)
