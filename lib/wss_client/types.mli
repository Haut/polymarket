(** WebSocket message types for Polymarket WSS API.

    This module defines types for the Market and User WebSocket channels. *)

(** {1 Channel Types} *)

module Channel : sig
  type t = Market | User

  val to_string : t -> string
  val of_string : string -> t
  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
end

(** {1 Common Types} *)

type order_summary = { price : string; size : string }

val order_summary_of_yojson : Yojson.Safe.t -> order_summary
val yojson_of_order_summary : order_summary -> Yojson.Safe.t
val pp_order_summary : Format.formatter -> order_summary -> unit
val show_order_summary : order_summary -> string
val equal_order_summary : order_summary -> order_summary -> bool

(** {1 Market Channel Message Types} *)

module Market_event : sig
  type t =
    | Book
    | Price_change
    | Tick_size_change
    | Last_trade_price
    | Best_bid_ask

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
end

type book_message = {
  event_type : string;
  asset_id : string;
  market : string;
  timestamp : string;
  hash : string;
  bids : order_summary list;
  asks : order_summary list;
}
(** Book message - full orderbook snapshot *)

val book_message_of_yojson : Yojson.Safe.t -> book_message
val yojson_of_book_message : book_message -> Yojson.Safe.t
val pp_book_message : Format.formatter -> book_message -> unit
val show_book_message : book_message -> string
val equal_book_message : book_message -> book_message -> bool

type price_change_entry = {
  asset_id : string;
  price : string;
  size : string;
  side : string;
  hash : string;
  best_bid : string;
  best_ask : string;
}
(** Price change entry within a price_change message *)

val price_change_entry_of_yojson : Yojson.Safe.t -> price_change_entry
val yojson_of_price_change_entry : price_change_entry -> Yojson.Safe.t
val pp_price_change_entry : Format.formatter -> price_change_entry -> unit
val show_price_change_entry : price_change_entry -> string
val equal_price_change_entry : price_change_entry -> price_change_entry -> bool

type price_change_message = {
  event_type : string;
  market : string;
  price_changes : price_change_entry list;
  timestamp : string;
}
(** Price change message - incremental orderbook update *)

val price_change_message_of_yojson : Yojson.Safe.t -> price_change_message
val yojson_of_price_change_message : price_change_message -> Yojson.Safe.t
val pp_price_change_message : Format.formatter -> price_change_message -> unit
val show_price_change_message : price_change_message -> string

val equal_price_change_message :
  price_change_message -> price_change_message -> bool

type tick_size_change_message = {
  event_type : string;
  asset_id : string;
  market : string;
  old_tick_size : string;
  new_tick_size : string;
  side : string option;
  timestamp : string;
}
(** Tick size change message *)

val tick_size_change_message_of_yojson :
  Yojson.Safe.t -> tick_size_change_message

val yojson_of_tick_size_change_message :
  tick_size_change_message -> Yojson.Safe.t

val pp_tick_size_change_message :
  Format.formatter -> tick_size_change_message -> unit

val show_tick_size_change_message : tick_size_change_message -> string

val equal_tick_size_change_message :
  tick_size_change_message -> tick_size_change_message -> bool

type last_trade_price_message = {
  event_type : string;
  asset_id : string;
  market : string;
  price : string;
  side : string;
  size : string;
  fee_rate_bps : string;
  timestamp : string;
}
(** Last trade price message *)

val last_trade_price_message_of_yojson :
  Yojson.Safe.t -> last_trade_price_message

val yojson_of_last_trade_price_message :
  last_trade_price_message -> Yojson.Safe.t

val pp_last_trade_price_message :
  Format.formatter -> last_trade_price_message -> unit

val show_last_trade_price_message : last_trade_price_message -> string

val equal_last_trade_price_message :
  last_trade_price_message -> last_trade_price_message -> bool

type best_bid_ask_message = {
  event_type : string;
  asset_id : string;
  market : string;
  best_bid : string;
  best_ask : string;
  timestamp : string;
}
(** Best bid/ask message *)

val best_bid_ask_message_of_yojson : Yojson.Safe.t -> best_bid_ask_message
val yojson_of_best_bid_ask_message : best_bid_ask_message -> Yojson.Safe.t
val pp_best_bid_ask_message : Format.formatter -> best_bid_ask_message -> unit
val show_best_bid_ask_message : best_bid_ask_message -> string

val equal_best_bid_ask_message :
  best_bid_ask_message -> best_bid_ask_message -> bool

(** {1 User Channel Message Types} *)

module User_event : sig
  type t = Trade | Order

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
end

module Trade_status : sig
  type t = Matched | Mined | Confirmed | Retrying | Failed

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
end

module Order_event_type : sig
  type t = Placement | Update | Cancellation

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
end

type maker_order = {
  asset_id : string;
  matched_amount : string;
  order_id : string;
  outcome : string;
  owner : string;
  price : string;
}
(** Maker order in a trade *)

val maker_order_of_yojson : Yojson.Safe.t -> maker_order
val yojson_of_maker_order : maker_order -> Yojson.Safe.t
val pp_maker_order : Format.formatter -> maker_order -> unit
val show_maker_order : maker_order -> string
val equal_maker_order : maker_order -> maker_order -> bool

type trade_message = {
  event_type : string;
  id : string;
  asset_id : string;
  market : string;
  side : string;
  size : string;
  price : string;
  status : Trade_status.t;
  outcome : string;
  owner : string;
  trade_owner : string;
  taker_order_id : string;
  maker_orders : maker_order list;
  matchtime : string;
  last_update : string;
  timestamp : string;
  type_ : string;
}
(** Trade message from user channel *)

val trade_message_of_yojson : Yojson.Safe.t -> trade_message
val yojson_of_trade_message : trade_message -> Yojson.Safe.t
val pp_trade_message : Format.formatter -> trade_message -> unit
val show_trade_message : trade_message -> string
val equal_trade_message : trade_message -> trade_message -> bool

type order_message = {
  event_type : string;
  id : string;
  asset_id : string;
  market : string;
  side : string;
  price : string;
  original_size : string;
  size_matched : string;
  outcome : string;
  owner : string;
  order_owner : string;
  associate_trades : string list option;
  timestamp : string;
  type_ : Order_event_type.t;
}
(** Order message from user channel *)

val order_message_of_yojson : Yojson.Safe.t -> order_message
val yojson_of_order_message : order_message -> Yojson.Safe.t
val pp_order_message : Format.formatter -> order_message -> unit
val show_order_message : order_message -> string
val equal_order_message : order_message -> order_message -> bool

(** {1 Unified Message Types} *)

type market_message =
  | Book of book_message
  | Price_change of price_change_message
  | Tick_size_change of tick_size_change_message
  | Last_trade_price of last_trade_price_message
  | Best_bid_ask of best_bid_ask_message

val pp_market_message : Format.formatter -> market_message -> unit
val show_market_message : market_message -> string
val equal_market_message : market_message -> market_message -> bool

type user_message = Trade of trade_message | Order of order_message

val pp_user_message : Format.formatter -> user_message -> unit
val show_user_message : user_message -> string
val equal_user_message : user_message -> user_message -> bool

type message =
  | Market of market_message
  | User of user_message
  | Unknown of string

val pp_message : Format.formatter -> message -> unit
val show_message : message -> string
val equal_message : message -> message -> bool

(** {1 Message Parsing} *)

val parse_market_message : Yojson.Safe.t -> market_message
(** Parse a JSON value as a market channel message. *)

val parse_user_message : Yojson.Safe.t -> user_message
(** Parse a JSON value as a user channel message. *)

val parse_message : channel:Channel.t -> string -> message list
(** Parse a raw JSON string into typed messages based on channel. Returns empty
    list for ack messages, handles arrays of messages from initial subscription.
*)

(** {1 Subscription Requests} *)

val market_subscribe_json : asset_ids:string list -> string
(** Generate JSON for market channel subscription. *)

val user_subscribe_json :
  credentials:Polymarket_clob.Auth_types.credentials ->
  markets:string list ->
  string
(** Generate JSON for user channel subscription with authentication. *)

val subscribe_assets_json : asset_ids:string list -> string
(** Generate JSON for subscribing to additional assets. *)

val unsubscribe_assets_json : asset_ids:string list -> string
(** Generate JSON for unsubscribing from assets. *)
