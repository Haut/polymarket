(** Data API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    data-api-openapi.yaml for the Polymarket Data API
    (https://data-api.polymarket.com). *)

(** {1 Primitive Types} *)

type address = string
(** User Profile Address (0x-prefixed, 40 hex chars). *)

type hash64 = string
(** 0x-prefixed 64-hex string. *)

(** {1 Query Parameter Enums} *)

(** Sort direction for paginated results *)
type sort_direction =
  | ASC  (** Ascending order *)
  | DESC  (** Descending order *)

val string_of_sort_direction : sort_direction -> string
val sort_direction_of_yojson : Yojson.Safe.t -> sort_direction
val yojson_of_sort_direction : sort_direction -> Yojson.Safe.t
val pp_sort_direction : Format.formatter -> sort_direction -> unit
val show_sort_direction : sort_direction -> string
val equal_sort_direction : sort_direction -> sort_direction -> bool

(** Sort field for positions endpoint *)
type position_sort_by =
  | CURRENT  (** Current value *)
  | INITIAL  (** Initial value *)
  | TOKENS  (** Number of tokens *)
  | CASHPNL  (** Cash profit/loss *)
  | PERCENTPNL  (** Percent profit/loss *)
  | TITLE  (** Title alphabetically *)
  | RESOLVING  (** Resolving status *)
  | PRICE  (** Current price *)
  | AVGPRICE  (** Average price *)

val string_of_position_sort_by : position_sort_by -> string
val position_sort_by_of_yojson : Yojson.Safe.t -> position_sort_by
val yojson_of_position_sort_by : position_sort_by -> Yojson.Safe.t
val pp_position_sort_by : Format.formatter -> position_sort_by -> unit
val show_position_sort_by : position_sort_by -> string
val equal_position_sort_by : position_sort_by -> position_sort_by -> bool

(** Filter type for trades endpoint *)
type filter_type =
  | CASH  (** Filter by cash amount *)
  | TOKENS_FILTER  (** Filter by token amount *)

val string_of_filter_type : filter_type -> string
val filter_type_of_yojson : Yojson.Safe.t -> filter_type
val yojson_of_filter_type : filter_type -> Yojson.Safe.t
val pp_filter_type : Format.formatter -> filter_type -> unit
val show_filter_type : filter_type -> string
val equal_filter_type : filter_type -> filter_type -> bool

(** Sort field for activity endpoint *)
type activity_sort_by =
  | TIMESTAMP  (** Timestamp *)
  | TOKENS_SORT  (** Token amount *)
  | CASH_SORT  (** Cash amount *)

val string_of_activity_sort_by : activity_sort_by -> string
val activity_sort_by_of_yojson : Yojson.Safe.t -> activity_sort_by
val yojson_of_activity_sort_by : activity_sort_by -> Yojson.Safe.t
val pp_activity_sort_by : Format.formatter -> activity_sort_by -> unit
val show_activity_sort_by : activity_sort_by -> string
val equal_activity_sort_by : activity_sort_by -> activity_sort_by -> bool

(** Sort field for closed positions endpoint *)
type closed_position_sort_by =
  | REALIZEDPNL  (** Realized profit/loss *)
  | TITLE_SORT  (** Title alphabetically *)
  | PRICE_SORT  (** Price *)
  | AVGPRICE_SORT  (** Average price *)
  | TIMESTAMP_SORT  (** Timestamp *)

val string_of_closed_position_sort_by : closed_position_sort_by -> string
val closed_position_sort_by_of_yojson : Yojson.Safe.t -> closed_position_sort_by
val yojson_of_closed_position_sort_by : closed_position_sort_by -> Yojson.Safe.t

val pp_closed_position_sort_by :
  Format.formatter -> closed_position_sort_by -> unit

val show_closed_position_sort_by : closed_position_sort_by -> string

val equal_closed_position_sort_by :
  closed_position_sort_by -> closed_position_sort_by -> bool

(** Time period for aggregated data *)
type time_period =
  | DAY  (** Last 24 hours *)
  | WEEK  (** Last 7 days *)
  | MONTH  (** Last 30 days *)
  | ALL  (** All time *)

val string_of_time_period : time_period -> string
val time_period_of_yojson : Yojson.Safe.t -> time_period
val yojson_of_time_period : time_period -> Yojson.Safe.t
val pp_time_period : Format.formatter -> time_period -> unit
val show_time_period : time_period -> string
val equal_time_period : time_period -> time_period -> bool

(** Market category for leaderboard filtering *)
type leaderboard_category =
  | OVERALL  (** All markets *)
  | POLITICS  (** Political markets *)
  | SPORTS  (** Sports markets *)
  | CRYPTO  (** Cryptocurrency markets *)
  | CULTURE  (** Culture/entertainment markets *)
  | MENTIONS  (** Social mentions markets *)
  | WEATHER  (** Weather markets *)
  | ECONOMICS  (** Economics markets *)
  | TECH  (** Technology markets *)
  | FINANCE  (** Finance markets *)

val string_of_leaderboard_category : leaderboard_category -> string
val leaderboard_category_of_yojson : Yojson.Safe.t -> leaderboard_category
val yojson_of_leaderboard_category : leaderboard_category -> Yojson.Safe.t
val pp_leaderboard_category : Format.formatter -> leaderboard_category -> unit
val show_leaderboard_category : leaderboard_category -> string

val equal_leaderboard_category :
  leaderboard_category -> leaderboard_category -> bool

(** Ordering criteria for trader leaderboard *)
type leaderboard_order_by =
  | PNL  (** Order by profit/loss *)
  | VOL  (** Order by volume *)

val string_of_leaderboard_order_by : leaderboard_order_by -> string
val leaderboard_order_by_of_yojson : Yojson.Safe.t -> leaderboard_order_by
val yojson_of_leaderboard_order_by : leaderboard_order_by -> Yojson.Safe.t
val pp_leaderboard_order_by : Format.formatter -> leaderboard_order_by -> unit
val show_leaderboard_order_by : leaderboard_order_by -> string

val equal_leaderboard_order_by :
  leaderboard_order_by -> leaderboard_order_by -> bool

(** {1 Domain Enums} *)

(** Trade side enum *)
type side =
  | BUY  (** Buy side of a trade *)
  | SELL  (** Sell side of a trade *)

val string_of_side : side -> string

(** Activity type enum *)
type activity_type =
  | TRADE  (** A trade activity *)
  | SPLIT  (** A position split *)
  | MERGE  (** A position merge *)
  | REDEEM  (** A redemption *)
  | REWARD  (** A reward *)
  | CONVERSION  (** A conversion *)

val string_of_activity_type : activity_type -> string

(** {1 Response Types} *)

type health_response = { data : string }
(** Health check response *)

type error_response = Http_client.Client.error_response = { error : string }
(** Error response (alias to Http_client.Client.error_response for
    compatibility) *)

(** {1 Domain Models} *)

type position = {
  proxy_wallet : address;
  asset : string;
  condition_id : hash64;
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
(** Position in a market *)

type closed_position = {
  proxy_wallet : address;
  asset : string;
  condition_id : hash64;
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
(** Closed position in a market *)

type trade = {
  proxy_wallet : address;
  side : side;
  asset : string;
  condition_id : hash64;
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
(** Trade record *)

type activity = {
  proxy_wallet : address;
  timestamp : int64;
  condition_id : hash64;
  activity_type : activity_type;
  size : float;
  usdc_size : float;
  transaction_hash : string;
  price : float;
  asset : string;
  side : side;
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
(** Activity record *)

type holder = {
  proxy_wallet : address;
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
(** Holder of a position *)

type meta_holder = { token : string; holders : holder list }
(** Meta holder with token and list of holders *)

type traded = { user : address; traded : int }
(** Traded record *)

type revision_entry = { revision : string; timestamp : int }
(** Revision entry *)

type revision_payload = {
  question_id : hash64;
  revisions : revision_entry list;
}
(** Revision payload *)

type value = { user : address; value : float }
(** Value record *)

type open_interest = { market : hash64; value : float }
(** Open interest for a market *)

type market_volume = { market : hash64 option; value : float option }
(** Market volume *)

type live_volume = { total : float option; markets : market_volume list }
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
(** Leaderboard entry for builders *)

type builder_volume_entry = {
  dt : Common.Primitives.Timestamp.t;
  builder : string;
  builder_logo : string;
  verified : bool;
  volume : float;
  active_users : int;
  rank : string;
}
(** Builder volume entry *)

type trader_leaderboard_entry = {
  rank : string;
  proxy_wallet : address;
  user_name : string;
  vol : float;
  pnl : float;
  profile_image : string;
  x_username : string;
  verified_badge : bool;
}
(** Trader leaderboard entry *)

(** {1 JSON Conversion Functions} *)

val address_of_yojson : Yojson.Safe.t -> address
val yojson_of_address : address -> Yojson.Safe.t
val hash64_of_yojson : Yojson.Safe.t -> hash64
val yojson_of_hash64 : hash64 -> Yojson.Safe.t
val side_of_yojson : Yojson.Safe.t -> side
val yojson_of_side : side -> Yojson.Safe.t
val activity_type_of_yojson : Yojson.Safe.t -> activity_type
val yojson_of_activity_type : activity_type -> Yojson.Safe.t

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
val pp_leaderboard_entry : Format.formatter -> leaderboard_entry -> unit
val show_leaderboard_entry : leaderboard_entry -> string
val pp_builder_volume_entry : Format.formatter -> builder_volume_entry -> unit
val show_builder_volume_entry : builder_volume_entry -> string

val pp_trader_leaderboard_entry :
  Format.formatter -> trader_leaderboard_entry -> unit

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
val equal_leaderboard_entry : leaderboard_entry -> leaderboard_entry -> bool

val equal_builder_volume_entry :
  builder_volume_entry -> builder_volume_entry -> bool

val equal_trader_leaderboard_entry :
  trader_leaderboard_entry -> trader_leaderboard_entry -> bool

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
val leaderboard_entry_of_yojson : Yojson.Safe.t -> leaderboard_entry
val yojson_of_leaderboard_entry : leaderboard_entry -> Yojson.Safe.t
val builder_volume_entry_of_yojson : Yojson.Safe.t -> builder_volume_entry
val yojson_of_builder_volume_entry : builder_volume_entry -> Yojson.Safe.t

val trader_leaderboard_entry_of_yojson :
  Yojson.Safe.t -> trader_leaderboard_entry

val yojson_of_trader_leaderboard_entry :
  trader_leaderboard_entry -> Yojson.Safe.t
