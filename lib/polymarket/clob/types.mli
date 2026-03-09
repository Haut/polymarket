(** CLOB API types for Polymarket.

    These types correspond to the Polymarket CLOB API
    (https://clob.polymarket.com). *)

(** {1 Primitives Module Alias} *)

module P = Common.Primitives

(** {1 Enum Modules} *)

module Side = Common.Primitives.Side

module Order_type : sig
  type t =
    | Gtc
    | Gtd
    | Fok
    | Fak
        (** Gtc: Good Till Cancelled, Gtd: Good Till Date, Fok: Fill or Kill,
            Fak: Fill and Kill *)

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Interval : sig
  type t = Min_1 | Min_5 | Min_15 | Hour_1 | Hour_6 | Day_1 | Week_1 | Max

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Status : sig
  type t = Live | Matched | Delayed | Unmatched | Cancelled | Expired

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Order_status : sig
  type t = Live | Invalid | Canceled_market_resolved | Canceled | Matched

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Signature_type : sig
  type t =
    | Eoa
    | Poly_proxy
    | Poly_gnosis_safe
        (** Eoa: EIP712 from externally owned account (0), Poly_proxy: EIP712
            from Polymarket proxy wallet signer (1), Poly_gnosis_safe: EIP712
            from Polymarket Gnosis Safe signer (2) *)

  val to_int : t -> int
  val of_int_opt : int -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Trade_type : sig
  type t = Taker | Maker

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Trade_status : sig
  type t = Confirmed | Failed | Retrying | Matched | Mined

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Order Book Types} *)

type order_book_level = { price : string option; size : string option }
(** Order book price level with price and size *)

val order_book_level_of_yojson : Yojson.Safe.t -> order_book_level
val yojson_of_order_book_level : order_book_level -> Yojson.Safe.t
val pp_order_book_level : Format.formatter -> order_book_level -> unit
val show_order_book_level : order_book_level -> string
val equal_order_book_level : order_book_level -> order_book_level -> bool

type order_book_summary = {
  market : string option;
  asset_id : string option;
  timestamp : string option;
  hash : string option;
  bids : order_book_level list;
  asks : order_book_level list;
  min_order_size : string option;
  tick_size : string option;
  neg_risk : bool option;
  last_trade_price : string option;
}
(** Order book summary for a token *)

val order_book_summary_of_yojson : Yojson.Safe.t -> order_book_summary
val yojson_of_order_book_summary : order_book_summary -> Yojson.Safe.t
val pp_order_book_summary : Format.formatter -> order_book_summary -> unit
val show_order_book_summary : order_book_summary -> string
val equal_order_book_summary : order_book_summary -> order_book_summary -> bool

(** {1 Signed Order Types} *)

type signed_order = {
  salt : string option;
  maker : P.Address.t option;
  signer : P.Address.t option;
  taker : P.Address.t option;
  token_id : P.U256.t option;
  maker_amount : string option;
  taker_amount : string option;
  expiration : string option;
  nonce : string option;
  fee_rate_bps : string option;
  side : Side.t option;
  signature_type : Signature_type.t option;
  signature : P.Signature.t option;
}
(** Cryptographically signed order for the CLOB *)

val signed_order_of_yojson : Yojson.Safe.t -> signed_order
val yojson_of_signed_order : signed_order -> Yojson.Safe.t
val pp_signed_order : Format.formatter -> signed_order -> unit
val show_signed_order : signed_order -> string
val equal_signed_order : signed_order -> signed_order -> bool

type order_request = {
  order : signed_order option;
  owner : string option;
  order_type : Order_type.t option;
  defer_exec : bool option;
}
(** Request body for creating an order *)

val order_request_of_yojson : Yojson.Safe.t -> order_request
val yojson_of_order_request : order_request -> Yojson.Safe.t
val pp_order_request : Format.formatter -> order_request -> unit
val show_order_request : order_request -> string
val equal_order_request : order_request -> order_request -> bool

type create_order_response = {
  success : bool option;
  error_msg : string option;
  order_id : string option;
  order_hashes : string list;
  status : Status.t option;
  making_amount : string option;
  taking_amount : string option;
  transactions_hashes : string list;
  trade_ids : string list;
}
(** Response from creating an order *)

val create_order_response_of_yojson : Yojson.Safe.t -> create_order_response
val yojson_of_create_order_response : create_order_response -> Yojson.Safe.t
val pp_create_order_response : Format.formatter -> create_order_response -> unit
val show_create_order_response : create_order_response -> string

val equal_create_order_response :
  create_order_response -> create_order_response -> bool

(** {1 Open Order Types} *)

type open_order = {
  id : string option;
  status : Order_status.t option;
  market : string option;
  asset_id : P.U256.t option;
  original_size : string option;
  size_matched : string option;
  price : string option;
  side : Side.t option;
  outcome : string option;
  maker_address : P.Address.t option;
  owner : string option;
  expiration : string option;
  order_type : Order_type.t option;
  created_at : string option;
  associate_trades : string list;
}
(** An open/active order *)

val open_order_of_yojson : Yojson.Safe.t -> open_order
val yojson_of_open_order : open_order -> Yojson.Safe.t
val pp_open_order : Format.formatter -> open_order -> unit
val show_open_order : open_order -> string
val equal_open_order : open_order -> open_order -> bool

type orders_response = {
  limit : int;
  next_cursor : string;
  count : int;
  data : open_order list;
}
(** Paginated response from get orders endpoint *)

val orders_response_of_yojson : Yojson.Safe.t -> orders_response
val yojson_of_orders_response : orders_response -> Yojson.Safe.t
val pp_orders_response : Format.formatter -> orders_response -> unit
val show_orders_response : orders_response -> string
val equal_orders_response : orders_response -> orders_response -> bool

type order_scoring_response = { scoring : bool }
(** Response indicating whether an order is currently scoring for rewards *)

val order_scoring_response_of_yojson : Yojson.Safe.t -> order_scoring_response
val yojson_of_order_scoring_response : order_scoring_response -> Yojson.Safe.t

val pp_order_scoring_response :
  Format.formatter -> order_scoring_response -> unit

val show_order_scoring_response : order_scoring_response -> string

val equal_order_scoring_response :
  order_scoring_response -> order_scoring_response -> bool

type heartbeat_response = { status : string }
(** Response from heartbeat endpoint *)

val heartbeat_response_of_yojson : Yojson.Safe.t -> heartbeat_response
val yojson_of_heartbeat_response : heartbeat_response -> Yojson.Safe.t
val pp_heartbeat_response : Format.formatter -> heartbeat_response -> unit
val show_heartbeat_response : heartbeat_response -> string
val equal_heartbeat_response : heartbeat_response -> heartbeat_response -> bool

(** {1 Cancel Types} *)

type cancel_response = {
  canceled : string list;
  not_canceled : (string * string) list;
}
(** Response from canceling orders *)

val cancel_response_of_yojson : Yojson.Safe.t -> cancel_response
val yojson_of_cancel_response : cancel_response -> Yojson.Safe.t
val pp_cancel_response : Format.formatter -> cancel_response -> unit
val show_cancel_response : cancel_response -> string
val equal_cancel_response : cancel_response -> cancel_response -> bool

(** {1 Trade Types} *)

type maker_order_fill = {
  order_id : string option;
  maker_address : P.Address.t option;
  owner : string option;
  matched_amount : string option;
  fee_rate_bps : string option;
  price : string option;
  asset_id : P.U256.t option;
  outcome : string option;
  side : Side.t option;
}
(** Maker order that was filled in a trade *)

val maker_order_fill_of_yojson : Yojson.Safe.t -> maker_order_fill
val yojson_of_maker_order_fill : maker_order_fill -> Yojson.Safe.t
val pp_maker_order_fill : Format.formatter -> maker_order_fill -> unit
val show_maker_order_fill : maker_order_fill -> string
val equal_maker_order_fill : maker_order_fill -> maker_order_fill -> bool

type clob_trade = {
  id : string option;
  taker_order_id : string option;
  market : string option;
  asset_id : P.U256.t option;
  side : Side.t option;
  size : string option;
  fee_rate_bps : string option;
  price : string option;
  status : Trade_status.t option;
  match_time : string option;
  match_time_nano : string option;
  last_update : string option;
  outcome : string option;
  bucket_index : int option;
  owner : string option;
  maker_address : P.Address.t option;
  transaction_hash : string option;
  err_msg : string option;
  maker_orders : maker_order_fill list;
  trader_side : Trade_type.t option;
}
(** A trade on the CLOB *)

val clob_trade_of_yojson : Yojson.Safe.t -> clob_trade
val yojson_of_clob_trade : clob_trade -> Yojson.Safe.t
val pp_clob_trade : Format.formatter -> clob_trade -> unit
val show_clob_trade : clob_trade -> string
val equal_clob_trade : clob_trade -> clob_trade -> bool

type trades_response = {
  limit : int;
  next_cursor : string;
  count : int;
  data : clob_trade list;
}
(** Paginated response from get trades endpoint *)

val trades_response_of_yojson : Yojson.Safe.t -> trades_response
val yojson_of_trades_response : trades_response -> Yojson.Safe.t
val pp_trades_response : Format.formatter -> trades_response -> unit
val show_trades_response : trades_response -> string
val equal_trades_response : trades_response -> trades_response -> bool

(** {1 Builder Trade Types} *)

type builder_trade = {
  id : string option;
  trade_type : string option;
  taker_order_hash : string option;
  builder : string option;
  market : string option;
  asset_id : string option;
  side : Side.t option;
  size : string option;
  size_usdc : string option;
  price : string option;
  status : string option;
  outcome : string option;
  outcome_index : int option;
  owner : string option;
  maker : P.Address.t option;
  transaction_hash : string option;
  match_time : string option;
  bucket_index : int option;
  fee : string option;
  fee_usdc : string option;
  err_msg : string option;
  created_at : string option;
  updated_at : string option;
}
(** A builder-originated trade *)

val builder_trade_of_yojson : Yojson.Safe.t -> builder_trade
val yojson_of_builder_trade : builder_trade -> Yojson.Safe.t
val pp_builder_trade : Format.formatter -> builder_trade -> unit
val show_builder_trade : builder_trade -> string
val equal_builder_trade : builder_trade -> builder_trade -> bool

type builder_trades_response = {
  limit : int;
  next_cursor : string;
  count : int;
  data : builder_trade list;
}
(** Paginated response from get builder trades endpoint *)

val builder_trades_response_of_yojson : Yojson.Safe.t -> builder_trades_response
val yojson_of_builder_trades_response : builder_trades_response -> Yojson.Safe.t

val pp_builder_trades_response :
  Format.formatter -> builder_trades_response -> unit

val show_builder_trades_response : builder_trades_response -> string

val equal_builder_trades_response :
  builder_trades_response -> builder_trades_response -> bool

(** {1 Simplified Market Types} *)

type reward_rate = {
  asset_address : string option;
  rewards_daily_rate : float option;
}
(** Reward rate for a specific asset *)

val reward_rate_of_yojson : Yojson.Safe.t -> reward_rate
val yojson_of_reward_rate : reward_rate -> Yojson.Safe.t
val pp_reward_rate : Format.formatter -> reward_rate -> unit
val show_reward_rate : reward_rate -> string
val equal_reward_rate : reward_rate -> reward_rate -> bool

type rewards = {
  rates : reward_rate list;
  min_size : float option;
  max_spread : float option;
}
(** Rewards configuration for a market *)

val rewards_of_yojson : Yojson.Safe.t -> rewards
val yojson_of_rewards : rewards -> Yojson.Safe.t
val pp_rewards : Format.formatter -> rewards -> unit
val show_rewards : rewards -> string
val equal_rewards : rewards -> rewards -> bool

type market_token = {
  token_id : string option;
  outcome : string option;
  price : float option;
  winner : bool option;
}
(** Token within a simplified market *)

val market_token_of_yojson : Yojson.Safe.t -> market_token
val yojson_of_market_token : market_token -> Yojson.Safe.t
val pp_market_token : Format.formatter -> market_token -> unit
val show_market_token : market_token -> string
val equal_market_token : market_token -> market_token -> bool

type simplified_market = {
  condition_id : string option;
  rewards : rewards option;
  tokens : market_token list;
  active : bool option;
  closed : bool option;
  archived : bool option;
  accepting_orders : bool option;
}
(** A simplified market from the CLOB *)

val simplified_market_of_yojson : Yojson.Safe.t -> simplified_market
val yojson_of_simplified_market : simplified_market -> Yojson.Safe.t
val pp_simplified_market : Format.formatter -> simplified_market -> unit
val show_simplified_market : simplified_market -> string
val equal_simplified_market : simplified_market -> simplified_market -> bool

type simplified_markets_response = {
  limit : int option;
  next_cursor : string option;
  count : int option;
  data : simplified_market list;
}
(** Paginated response from get simplified markets endpoint *)

val simplified_markets_response_of_yojson :
  Yojson.Safe.t -> simplified_markets_response

val yojson_of_simplified_markets_response :
  simplified_markets_response -> Yojson.Safe.t

val pp_simplified_markets_response :
  Format.formatter -> simplified_markets_response -> unit

val show_simplified_markets_response : simplified_markets_response -> string

val equal_simplified_markets_response :
  simplified_markets_response -> simplified_markets_response -> bool

type clob_market = {
  enable_order_book : bool option;
  active : bool option;
  closed : bool option;
  archived : bool option;
  accepting_orders : bool option;
  accepting_order_timestamp : string option;
  minimum_order_size : float option;
  minimum_tick_size : float option;
  condition_id : string option;
  question_id : string option;
  question : string option;
  description : string option;
  market_slug : string option;
  end_date_iso : string option;
  game_start_time : string option;
  seconds_delay : int option;
  fpmm : string option;
  maker_base_fee : int64 option;
  taker_base_fee : int64 option;
  notifications_enabled : bool option;
  neg_risk : bool option;
  neg_risk_market_id : string option;
  neg_risk_request_id : string option;
  icon : string option;
  image : string option;
  rewards : rewards option;
  is_50_50_outcome : bool option;
  tokens : market_token list;
  tags : string list;
}
(** A full market from the CLOB *)

val clob_market_of_yojson : Yojson.Safe.t -> clob_market
val yojson_of_clob_market : clob_market -> Yojson.Safe.t
val pp_clob_market : Format.formatter -> clob_market -> unit
val show_clob_market : clob_market -> string
val equal_clob_market : clob_market -> clob_market -> bool

type markets_response = {
  limit : int option;
  next_cursor : string option;
  count : int option;
  data : clob_market list;
}
(** Paginated response from get markets endpoint *)

val markets_response_of_yojson : Yojson.Safe.t -> markets_response
val yojson_of_markets_response : markets_response -> Yojson.Safe.t
val pp_markets_response : Format.formatter -> markets_response -> unit
val show_markets_response : markets_response -> string
val equal_markets_response : markets_response -> markets_response -> bool

(** {1 Price Types} *)

type price_response = { price : string option }
(** Response from get price endpoint *)

val price_response_of_yojson : Yojson.Safe.t -> price_response
val yojson_of_price_response : price_response -> Yojson.Safe.t
val pp_price_response : Format.formatter -> price_response -> unit
val show_price_response : price_response -> string
val equal_price_response : price_response -> price_response -> bool

type midpoint_response = { mid_price : string option }
(** Response from get midpoint endpoint *)

val midpoint_response_of_yojson : Yojson.Safe.t -> midpoint_response
val yojson_of_midpoint_response : midpoint_response -> Yojson.Safe.t
val pp_midpoint_response : Format.formatter -> midpoint_response -> unit
val show_midpoint_response : midpoint_response -> string
val equal_midpoint_response : midpoint_response -> midpoint_response -> bool

type spread_response = { spread : string option }
(** Response from get spread endpoint *)

val spread_response_of_yojson : Yojson.Safe.t -> spread_response
val yojson_of_spread_response : spread_response -> Yojson.Safe.t
val pp_spread_response : Format.formatter -> spread_response -> unit
val show_spread_response : spread_response -> string
val equal_spread_response : spread_response -> spread_response -> bool

type token_price = { buy : string option; sell : string option }
(** Token prices for buy and sell sides *)

val token_price_of_yojson : Yojson.Safe.t -> token_price
val yojson_of_token_price : token_price -> Yojson.Safe.t
val pp_token_price : Format.formatter -> token_price -> unit
val show_token_price : token_price -> string
val equal_token_price : token_price -> token_price -> bool

type prices_response = (P.U256.t * token_price) list
(** Map from token_id to token_price *)

val prices_response_of_yojson : Yojson.Safe.t -> prices_response
val yojson_of_prices_response : prices_response -> Yojson.Safe.t
val pp_prices_response : Format.formatter -> prices_response -> unit
val show_prices_response : prices_response -> string
val equal_prices_response : prices_response -> prices_response -> bool

type midpoints_response = (P.U256.t * string) list
(** Map from token_id to midpoint price *)

val midpoints_response_of_yojson : Yojson.Safe.t -> midpoints_response
val yojson_of_midpoints_response : midpoints_response -> Yojson.Safe.t
val pp_midpoints_response : Format.formatter -> midpoints_response -> unit
val show_midpoints_response : midpoints_response -> string
val equal_midpoints_response : midpoints_response -> midpoints_response -> bool

type spreads_response = (P.U256.t * string) list
(** Map from token_id to spread value *)

val spreads_response_of_yojson : Yojson.Safe.t -> spreads_response
val yojson_of_spreads_response : spreads_response -> Yojson.Safe.t
val pp_spreads_response : Format.formatter -> spreads_response -> unit
val show_spreads_response : spreads_response -> string
val equal_spreads_response : spreads_response -> spreads_response -> bool

type last_trade_price_entry = {
  token_id : string;
  price : string;
  side : Side.t;
}
(** Entry in last trade prices response *)

val last_trade_price_entry_of_yojson : Yojson.Safe.t -> last_trade_price_entry
val yojson_of_last_trade_price_entry : last_trade_price_entry -> Yojson.Safe.t

val pp_last_trade_price_entry :
  Format.formatter -> last_trade_price_entry -> unit

val show_last_trade_price_entry : last_trade_price_entry -> string

val equal_last_trade_price_entry :
  last_trade_price_entry -> last_trade_price_entry -> bool

type fee_rate_response = { base_fee : int64 }
(** Response from get fee rate endpoint *)

val fee_rate_response_of_yojson : Yojson.Safe.t -> fee_rate_response
val yojson_of_fee_rate_response : fee_rate_response -> Yojson.Safe.t
val pp_fee_rate_response : Format.formatter -> fee_rate_response -> unit
val show_fee_rate_response : fee_rate_response -> string
val equal_fee_rate_response : fee_rate_response -> fee_rate_response -> bool

type tick_size_response = { minimum_tick_size : float }
(** Response from get tick size endpoint *)

val tick_size_response_of_yojson : Yojson.Safe.t -> tick_size_response
val yojson_of_tick_size_response : tick_size_response -> Yojson.Safe.t
val pp_tick_size_response : Format.formatter -> tick_size_response -> unit
val show_tick_size_response : tick_size_response -> string
val equal_tick_size_response : tick_size_response -> tick_size_response -> bool

(** {1 Timeseries Types} *)

type price_point = { t : int64 option; p : Common.Primitives.Decimal.t option }
(** Single price point with timestamp and price *)

val price_point_of_yojson : Yojson.Safe.t -> price_point
val yojson_of_price_point : price_point -> Yojson.Safe.t
val pp_price_point : Format.formatter -> price_point -> unit
val show_price_point : price_point -> string
val equal_price_point : price_point -> price_point -> bool

type price_history = { history : price_point list }
(** Historical price data *)

val price_history_of_yojson : Yojson.Safe.t -> price_history
val yojson_of_price_history : price_history -> Yojson.Safe.t
val pp_price_history : Format.formatter -> price_history -> unit
val show_price_history : price_history -> string
val equal_price_history : price_history -> price_history -> bool

type rebated_fees = {
  date : string;
  condition_id : string;
  asset_address : string;
  maker_address : string;
  rebated_fees_usdc : string;
}
(** Rebated fees for a maker on a specific market and date *)

val rebated_fees_of_yojson : Yojson.Safe.t -> rebated_fees
val yojson_of_rebated_fees : rebated_fees -> Yojson.Safe.t
val pp_rebated_fees : Format.formatter -> rebated_fees -> unit
val show_rebated_fees : rebated_fees -> string
val equal_rebated_fees : rebated_fees -> rebated_fees -> bool

(** {1 Error Types} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors. *)

val error_to_string : error -> string
(** Convert error to human-readable string *)

val pp_error : Format.formatter -> error -> unit
(** Pretty printer for errors *)

(** {1 Field Lists for Extra Field Detection} *)

val yojson_fields_of_order_book_level : string list
val yojson_fields_of_order_book_summary : string list
val yojson_fields_of_signed_order : string list
val yojson_fields_of_order_request : string list
val yojson_fields_of_create_order_response : string list
val yojson_fields_of_open_order : string list
val yojson_fields_of_orders_response : string list
val yojson_fields_of_order_scoring_response : string list
val yojson_fields_of_heartbeat_response : string list
val yojson_fields_of_maker_order_fill : string list
val yojson_fields_of_clob_trade : string list
val yojson_fields_of_trades_response : string list
val yojson_fields_of_builder_trade : string list
val yojson_fields_of_builder_trades_response : string list
val yojson_fields_of_reward_rate : string list
val yojson_fields_of_rewards : string list
val yojson_fields_of_market_token : string list
val yojson_fields_of_simplified_market : string list
val yojson_fields_of_simplified_markets_response : string list
val yojson_fields_of_clob_market : string list
val yojson_fields_of_markets_response : string list
val yojson_fields_of_price_response : string list
val yojson_fields_of_midpoint_response : string list
val yojson_fields_of_spread_response : string list
val yojson_fields_of_last_trade_price_entry : string list
val yojson_fields_of_fee_rate_response : string list
val yojson_fields_of_tick_size_response : string list
val yojson_fields_of_token_price : string list
val yojson_fields_of_price_point : string list
val yojson_fields_of_price_history : string list
val yojson_fields_of_rebated_fees : string list
