(** Data API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in data-api-openapi.yaml
    for the Polymarket Data API (https://data-api.polymarket.com).
*)

(** {1 Primitive Types} *)

(** User Profile Address (0x-prefixed, 40 hex chars).
    Pattern: ^0x[a-fA-F0-9]{40}$
    @example "0x56687bf447db6ffa42ffe2204a05edaa20f55839" *)
type address = string

(** 0x-prefixed 64-hex string.
    Pattern: ^0x[a-fA-F0-9]{64}$
    @example "0xdd22472e552920b8438158ea7238bfadfa4f736aa4cee91a6b86c39ead110917" *)
type hash64 = string

(** {1 Validation Exceptions} *)

(** Raised when an address fails validation *)
exception Invalid_address of string

(** Raised when a hash64 fails validation *)
exception Invalid_hash64 of string

(** {1 Enums} *)

(** Trade side enum *)
type side =
  | BUY   (** Buy side of a trade *)
  | SELL  (** Sell side of a trade *)

val string_of_side : side -> string

(** Activity type enum *)
type activity_type =
  | TRADE       (** A trade activity *)
  | SPLIT       (** A position split *)
  | MERGE       (** A position merge *)
  | REDEEM      (** A redemption *)
  | REWARD      (** A reward *)
  | CONVERSION  (** A conversion *)

val string_of_activity_type : activity_type -> string

(** {1 Response Types} *)

(** Health check response *)
type health_response = {
  data : string option;
}

(** Error response *)
type error_response = {
  error : string;
}

(** {1 Domain Models} *)

(** Position in a market *)
type position = {
  proxy_wallet : address option;
  asset : string option;
  condition_id : hash64 option;
  size : float option;
  avg_price : float option;
  initial_value : float option;
  current_value : float option;
  cash_pnl : float option;
  percent_pnl : float option;
  total_bought : float option;
  realized_pnl : float option;
  percent_realized_pnl : float option;
  cur_price : float option;
  redeemable : bool option;
  mergeable : bool option;
  title : string option;
  slug : string option;
  icon : string option;
  event_slug : string option;
  outcome : string option;
  outcome_index : int option;
  opposite_outcome : string option;
  opposite_asset : string option;
  end_date : string option;
  negative_risk : bool option;
}

(** Closed position in a market *)
type closed_position = {
  proxy_wallet : address option;
  asset : string option;
  condition_id : hash64 option;
  avg_price : float option;
  total_bought : float option;
  realized_pnl : float option;
  cur_price : float option;
  timestamp : int64 option;
  title : string option;
  slug : string option;
  icon : string option;
  event_slug : string option;
  outcome : string option;
  outcome_index : int option;
  opposite_outcome : string option;
  opposite_asset : string option;
  end_date : string option;
}

(** Trade record *)
type trade = {
  proxy_wallet : address option;
  side : side option;
  asset : string option;
  condition_id : hash64 option;
  size : float option;
  price : float option;
  timestamp : int64 option;
  title : string option;
  slug : string option;
  icon : string option;
  event_slug : string option;
  outcome : string option;
  outcome_index : int option;
  name : string option;
  pseudonym : string option;
  bio : string option;
  profile_image : string option;
  profile_image_optimized : string option;
  transaction_hash : string option;
}

(** Activity record *)
type activity = {
  proxy_wallet : address option;
  timestamp : int64 option;
  condition_id : hash64 option;
  activity_type : activity_type option;
  size : float option;
  usdc_size : float option;
  transaction_hash : string option;
  price : float option;
  asset : string option;
  side : side option;
  outcome_index : int option;
  title : string option;
  slug : string option;
  icon : string option;
  event_slug : string option;
  outcome : string option;
  name : string option;
  pseudonym : string option;
  bio : string option;
  profile_image : string option;
  profile_image_optimized : string option;
}

(** Holder of a position *)
type holder = {
  proxy_wallet : address option;
  bio : string option;
  asset : string option;
  pseudonym : string option;
  amount : float option;
  display_username_public : bool option;
  outcome_index : int option;
  name : string option;
  profile_image : string option;
  profile_image_optimized : string option;
}

(** Meta holder with token and list of holders *)
type meta_holder = {
  token : string option;
  holders : holder list option;
}

(** Traded record *)
type traded = {
  user : address option;
  traded : int option;
}

(** Revision entry *)
type revision_entry = {
  revision : string option;
  timestamp : int option;
}

(** Revision payload *)
type revision_payload = {
  question_id : hash64 option;
  revisions : revision_entry list option;
}

(** Value record *)
type value = {
  user : address option;
  value : float option;
}

(** Open interest for a market *)
type open_interest = {
  market : hash64 option;
  value : float option;
}

(** Market volume *)
type market_volume = {
  market : hash64 option;
  value : float option;
}

(** Live volume *)
type live_volume = {
  total : float option;
  markets : market_volume list option;
}

(** Other size record *)
type other_size = {
  id : int option;
  user : address option;
  size : float option;
}

(** {1 Leaderboard Types} *)

(** Leaderboard entry for builders *)
type leaderboard_entry = {
  rank : string option;
  builder : string option;
  volume : float option;
  active_users : int option;
  verified : bool option;
  builder_logo : string option;
}

(** Builder volume entry *)
type builder_volume_entry = {
  dt : string option;
  builder : string option;
  builder_logo : string option;
  verified : bool option;
  volume : float option;
  active_users : int option;
  rank : string option;
}

(** Trader leaderboard entry *)
type trader_leaderboard_entry = {
  rank : string option;
  proxy_wallet : address option;
  user_name : string option;
  vol : float option;
  pnl : float option;
  profile_image : string option;
  x_username : string option;
  verified_badge : bool option;
}

(** {1 JSON Conversion Functions} *)

val address_of_yojson : Yojson.Safe.t -> address
val yojson_of_address : address -> Yojson.Safe.t

val hash64_of_yojson : Yojson.Safe.t -> hash64
val yojson_of_hash64 : hash64 -> Yojson.Safe.t

val side_of_yojson : Yojson.Safe.t -> side
val yojson_of_side : side -> Yojson.Safe.t

val activity_type_of_yojson : Yojson.Safe.t -> activity_type
val yojson_of_activity_type : activity_type -> Yojson.Safe.t

(** {1 Validating Deserializers} *)

(** Deserialize an address with validation.
    @raise Invalid_address if the address doesn't match the expected pattern *)
val address_of_yojson_exn : Yojson.Safe.t -> address

(** Deserialize a hash64 with validation.
    @raise Invalid_hash64 if the hash doesn't match the expected pattern *)
val hash64_of_yojson_exn : Yojson.Safe.t -> hash64

(** Deserialize an address with validation, returning a result.
    @return [Ok address] if valid, [Error msg] if invalid *)
val address_of_yojson_result : Yojson.Safe.t -> (address, string) result

(** Deserialize a hash64 with validation, returning a result.
    @return [Ok hash64] if valid, [Error msg] if invalid *)
val hash64_of_yojson_result : Yojson.Safe.t -> (hash64, string) result

(** {1 Pretty Printing Functions} *)

val pp_address : Format.formatter -> address -> unit
val show_address : address -> string

val pp_hash64 : Format.formatter -> hash64 -> unit
val show_hash64 : hash64 -> string

val pp_side : Format.formatter -> side -> unit
val show_side : side -> string

val pp_activity_type : Format.formatter -> activity_type -> unit
val show_activity_type : activity_type -> string

val pp_health_response : Format.formatter -> health_response -> unit
val show_health_response : health_response -> string

val pp_error_response : Format.formatter -> error_response -> unit
val show_error_response : error_response -> string

val pp_position : Format.formatter -> position -> unit
val show_position : position -> string

val pp_closed_position : Format.formatter -> closed_position -> unit
val show_closed_position : closed_position -> string

val pp_trade : Format.formatter -> trade -> unit
val show_trade : trade -> string

val pp_activity : Format.formatter -> activity -> unit
val show_activity : activity -> string

val pp_holder : Format.formatter -> holder -> unit
val show_holder : holder -> string

val pp_meta_holder : Format.formatter -> meta_holder -> unit
val show_meta_holder : meta_holder -> string

val pp_traded : Format.formatter -> traded -> unit
val show_traded : traded -> string

val pp_revision_entry : Format.formatter -> revision_entry -> unit
val show_revision_entry : revision_entry -> string

val pp_revision_payload : Format.formatter -> revision_payload -> unit
val show_revision_payload : revision_payload -> string

val pp_value : Format.formatter -> value -> unit
val show_value : value -> string

val pp_open_interest : Format.formatter -> open_interest -> unit
val show_open_interest : open_interest -> string

val pp_market_volume : Format.formatter -> market_volume -> unit
val show_market_volume : market_volume -> string

val pp_live_volume : Format.formatter -> live_volume -> unit
val show_live_volume : live_volume -> string

val pp_other_size : Format.formatter -> other_size -> unit
val show_other_size : other_size -> string

val pp_leaderboard_entry : Format.formatter -> leaderboard_entry -> unit
val show_leaderboard_entry : leaderboard_entry -> string

val pp_builder_volume_entry : Format.formatter -> builder_volume_entry -> unit
val show_builder_volume_entry : builder_volume_entry -> string

val pp_trader_leaderboard_entry : Format.formatter -> trader_leaderboard_entry -> unit
val show_trader_leaderboard_entry : trader_leaderboard_entry -> string

(** {1 Equality Functions} *)

val equal_address : address -> address -> bool
val equal_hash64 : hash64 -> hash64 -> bool
val equal_side : side -> side -> bool
val equal_activity_type : activity_type -> activity_type -> bool
val equal_health_response : health_response -> health_response -> bool
val equal_error_response : error_response -> error_response -> bool
val equal_position : position -> position -> bool
val equal_closed_position : closed_position -> closed_position -> bool
val equal_trade : trade -> trade -> bool
val equal_activity : activity -> activity -> bool
val equal_holder : holder -> holder -> bool
val equal_meta_holder : meta_holder -> meta_holder -> bool
val equal_traded : traded -> traded -> bool
val equal_revision_entry : revision_entry -> revision_entry -> bool
val equal_revision_payload : revision_payload -> revision_payload -> bool
val equal_value : value -> value -> bool
val equal_open_interest : open_interest -> open_interest -> bool
val equal_market_volume : market_volume -> market_volume -> bool
val equal_live_volume : live_volume -> live_volume -> bool
val equal_other_size : other_size -> other_size -> bool
val equal_leaderboard_entry : leaderboard_entry -> leaderboard_entry -> bool
val equal_builder_volume_entry : builder_volume_entry -> builder_volume_entry -> bool
val equal_trader_leaderboard_entry : trader_leaderboard_entry -> trader_leaderboard_entry -> bool

val health_response_of_yojson : Yojson.Safe.t -> health_response
val yojson_of_health_response : health_response -> Yojson.Safe.t

val error_response_of_yojson : Yojson.Safe.t -> error_response
val yojson_of_error_response : error_response -> Yojson.Safe.t

val position_of_yojson : Yojson.Safe.t -> position
val yojson_of_position : position -> Yojson.Safe.t

val closed_position_of_yojson : Yojson.Safe.t -> closed_position
val yojson_of_closed_position : closed_position -> Yojson.Safe.t

val trade_of_yojson : Yojson.Safe.t -> trade
val yojson_of_trade : trade -> Yojson.Safe.t

val activity_of_yojson : Yojson.Safe.t -> activity
val yojson_of_activity : activity -> Yojson.Safe.t

val holder_of_yojson : Yojson.Safe.t -> holder
val yojson_of_holder : holder -> Yojson.Safe.t

val meta_holder_of_yojson : Yojson.Safe.t -> meta_holder
val yojson_of_meta_holder : meta_holder -> Yojson.Safe.t

val traded_of_yojson : Yojson.Safe.t -> traded
val yojson_of_traded : traded -> Yojson.Safe.t

val revision_entry_of_yojson : Yojson.Safe.t -> revision_entry
val yojson_of_revision_entry : revision_entry -> Yojson.Safe.t

val revision_payload_of_yojson : Yojson.Safe.t -> revision_payload
val yojson_of_revision_payload : revision_payload -> Yojson.Safe.t

val value_of_yojson : Yojson.Safe.t -> value
val yojson_of_value : value -> Yojson.Safe.t

val open_interest_of_yojson : Yojson.Safe.t -> open_interest
val yojson_of_open_interest : open_interest -> Yojson.Safe.t

val market_volume_of_yojson : Yojson.Safe.t -> market_volume
val yojson_of_market_volume : market_volume -> Yojson.Safe.t

val live_volume_of_yojson : Yojson.Safe.t -> live_volume
val yojson_of_live_volume : live_volume -> Yojson.Safe.t

val other_size_of_yojson : Yojson.Safe.t -> other_size
val yojson_of_other_size : other_size -> Yojson.Safe.t

val leaderboard_entry_of_yojson : Yojson.Safe.t -> leaderboard_entry
val yojson_of_leaderboard_entry : leaderboard_entry -> Yojson.Safe.t

val builder_volume_entry_of_yojson : Yojson.Safe.t -> builder_volume_entry
val yojson_of_builder_volume_entry : builder_volume_entry -> Yojson.Safe.t

val trader_leaderboard_entry_of_yojson : Yojson.Safe.t -> trader_leaderboard_entry
val yojson_of_trader_leaderboard_entry : trader_leaderboard_entry -> Yojson.Safe.t

(** {1 Validation Functions} *)

(** Validates an address string matches the expected pattern.
    Pattern: ^0x[a-fA-F0-9]{40}$
    @return [true] if the address is valid, [false] otherwise *)
val is_valid_address : address -> bool

(** Validates a hash64 string matches the expected pattern.
    Pattern: ^0x[a-fA-F0-9]{64}$
    @return [true] if the hash is valid, [false] otherwise *)
val is_valid_hash64 : hash64 -> bool

(** {1 Constructors} *)

(** Create an empty position record with all fields set to [None] *)
val empty_position : position

(** Create an empty closed_position record with all fields set to [None] *)
val empty_closed_position : closed_position

(** Create an empty trade record with all fields set to [None] *)
val empty_trade : trade

(** Create an empty activity record with all fields set to [None] *)
val empty_activity : activity

(** Create an empty holder record with all fields set to [None] *)
val empty_holder : holder

(** Create an empty trader_leaderboard_entry record with all fields set to [None] *)
val empty_trader_leaderboard_entry : trader_leaderboard_entry
