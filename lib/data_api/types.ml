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

(** {1 Validation Errors} *)

exception Invalid_address of string
exception Invalid_hash64 of string

(** {1 Enums} *)

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

type error_response = Common.Http_client.error_response = { error : string }
[@@deriving yojson, show, eq]
(** Error response (alias to Common.Http_client.error_response for
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

(** {1 Validation Functions} *)

(** Validates an address string matches the expected pattern.
    Pattern: ^0x[a-fA-F0-9]{40}$ *)
let is_valid_address (addr : address) : bool =
  let len = String.length addr in
  len = 42
  && String.length addr >= 2
  && addr.[0] = '0'
  && addr.[1] = 'x'
  && String.for_all
       (fun c ->
         match c with
         | '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true
         | _ -> false)
       (String.sub addr 2 (len - 2))

(** Validates a hash64 string matches the expected pattern.
    Pattern: ^0x[a-fA-F0-9]{64}$ *)
let is_valid_hash64 (hash : hash64) : bool =
  let len = String.length hash in
  len = 66
  && String.length hash >= 2
  && hash.[0] = '0'
  && hash.[1] = 'x'
  && String.for_all
       (fun c ->
         match c with
         | '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true
         | _ -> false)
       (String.sub hash 2 (len - 2))

(** {1 Validating Deserializers} *)

(** Deserialize an address with validation.
    @raise Invalid_address if the address doesn't match the expected pattern *)
let address_of_yojson_exn json =
  let addr = address_of_yojson json in
  if is_valid_address addr then addr else raise (Invalid_address addr)

(** Deserialize a hash64 with validation.
    @raise Invalid_hash64 if the hash doesn't match the expected pattern *)
let hash64_of_yojson_exn json =
  let hash = hash64_of_yojson json in
  if is_valid_hash64 hash then hash else raise (Invalid_hash64 hash)

(** Deserialize an address with validation, returning a result.
    @return [Ok address] if valid, [Error msg] if invalid *)
let address_of_yojson_result json =
  try
    let addr = address_of_yojson json in
    if is_valid_address addr then Ok addr
    else Error ("Invalid address format: " ^ addr)
  with Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _) ->
    Error ("JSON parse error: " ^ Printexc.to_string exn)

(** Deserialize a hash64 with validation, returning a result.
    @return [Ok hash64] if valid, [Error msg] if invalid *)
let hash64_of_yojson_result json =
  try
    let hash = hash64_of_yojson json in
    if is_valid_hash64 hash then Ok hash
    else Error ("Invalid hash64 format: " ^ hash)
  with Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _) ->
    Error ("JSON parse error: " ^ Printexc.to_string exn)

(** {1 Constructors} *)

(** Create an empty position record *)
let empty_position : position =
  {
    proxy_wallet = None;
    asset = None;
    condition_id = None;
    size = None;
    avg_price = None;
    initial_value = None;
    current_value = None;
    cash_pnl = None;
    percent_pnl = None;
    total_bought = None;
    realized_pnl = None;
    percent_realized_pnl = None;
    cur_price = None;
    redeemable = None;
    mergeable = None;
    title = None;
    slug = None;
    icon = None;
    event_slug = None;
    outcome = None;
    outcome_index = None;
    opposite_outcome = None;
    opposite_asset = None;
    end_date = None;
    negative_risk = None;
  }

(** Create an empty closed_position record *)
let empty_closed_position : closed_position =
  {
    proxy_wallet = None;
    asset = None;
    condition_id = None;
    avg_price = None;
    total_bought = None;
    realized_pnl = None;
    cur_price = None;
    timestamp = None;
    title = None;
    slug = None;
    icon = None;
    event_slug = None;
    outcome = None;
    outcome_index = None;
    opposite_outcome = None;
    opposite_asset = None;
    end_date = None;
  }

(** Create an empty trade record *)
let empty_trade : trade =
  {
    proxy_wallet = None;
    side = None;
    asset = None;
    condition_id = None;
    size = None;
    price = None;
    timestamp = None;
    title = None;
    slug = None;
    icon = None;
    event_slug = None;
    outcome = None;
    outcome_index = None;
    name = None;
    pseudonym = None;
    bio = None;
    profile_image = None;
    profile_image_optimized = None;
    transaction_hash = None;
  }

(** Create an empty activity record *)
let empty_activity : activity =
  {
    proxy_wallet = None;
    timestamp = None;
    condition_id = None;
    activity_type = None;
    size = None;
    usdc_size = None;
    transaction_hash = None;
    price = None;
    asset = None;
    side = None;
    outcome_index = None;
    title = None;
    slug = None;
    icon = None;
    event_slug = None;
    outcome = None;
    name = None;
    pseudonym = None;
    bio = None;
    profile_image = None;
    profile_image_optimized = None;
  }

(** Create an empty holder record *)
let empty_holder : holder =
  {
    proxy_wallet = None;
    bio = None;
    asset = None;
    pseudonym = None;
    amount = None;
    display_username_public = None;
    outcome_index = None;
    name = None;
    profile_image = None;
    profile_image_optimized = None;
  }

(** Create an empty trader_leaderboard_entry record *)
let empty_trader_leaderboard_entry : trader_leaderboard_entry =
  {
    rank = None;
    proxy_wallet = None;
    user_name = None;
    vol = None;
    pnl = None;
    profile_image = None;
    x_username = None;
    verified_badge = None;
  }
