(** WebSocket message types for Polymarket WSS API.

    This module defines types for the Market and User WebSocket channels. *)

(** {1 Channel Types} *)

module Channel : sig
  type t = Market | User

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Common Types} *)

type order_summary = {
  price : Common.Primitives.Decimal.t;
  size : Common.Primitives.Decimal.t;
}
[@@deriving yojson, eq]

(** {1 Market Channel Message Types} *)

module Market_event : sig
  type t =
    | Book
    | Price_change
    | Tick_size_change
    | Last_trade_price
    | Best_bid_ask
    | New_market
    | Market_resolved

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
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
[@@deriving yojson, eq]
(** Book message - full orderbook snapshot *)

type price_change_entry = {
  asset_id : string;
  price : Common.Primitives.Decimal.t;
  size : Common.Primitives.Decimal.t;
  side : string;
  hash : string;
  best_bid : Common.Primitives.Decimal.t option;
  best_ask : Common.Primitives.Decimal.t option;
}
[@@deriving yojson, eq]
(** Price change entry within a price_change message *)

type price_change_message = {
  event_type : string;
  market : string;
  price_changes : price_change_entry list;
  timestamp : string;
}
[@@deriving yojson, eq]
(** Price change message - incremental orderbook update *)

type tick_size_change_message = {
  event_type : string;
  asset_id : string;
  market : string;
  old_tick_size : Common.Primitives.Decimal.t;
  new_tick_size : Common.Primitives.Decimal.t;
  side : string option;
  timestamp : string;
}
[@@deriving yojson, eq]
(** Tick size change message *)

type last_trade_price_message = {
  event_type : string;
  asset_id : string;
  market : string;
  price : Common.Primitives.Decimal.t;
  side : string;
  size : Common.Primitives.Decimal.t;
  fee_rate_bps : Common.Primitives.Decimal.t option;
  transaction_hash : string option;
  timestamp : string;
}
[@@deriving yojson, eq]
(** Last trade price message *)

type best_bid_ask_message = {
  event_type : string;
  asset_id : string;
  market : string;
  best_bid : Common.Primitives.Decimal.t;
  best_ask : Common.Primitives.Decimal.t;
  spread : Common.Primitives.Decimal.t;
  timestamp : string;
}
[@@deriving yojson, eq]
(** Best bid/ask message *)

type event_message = {
  id : string option;
  ticker : string option;
  slug : string option;
  title : string option;
  description : string option;
}
[@@deriving yojson, eq]
(** Event metadata shared by new_market and market_resolved messages *)

type new_market_message = {
  event_type : string;
  id : string;
  question : string;
  market : string;
  slug : string;
  description : string option;
  assets_ids : string list;
  outcomes : string list;
  event : event_message option;
  timestamp : string;
  tags : string list option;
}
[@@deriving yojson, eq]
(** New market message *)

type market_resolved_message = {
  event_type : string;
  id : string;
  market : string;
  assets_ids : string list;
  winning_asset_id : string;
  winning_outcome : string;
  event : event_message option;
  timestamp : string;
  tags : string list option;
}
[@@deriving yojson, eq]
(** Market resolved message *)

(** {1 User Channel Message Types} *)

module User_event : sig
  type t = Trade | Order

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Trade_status : sig
  type t = Matched | Mined | Confirmed | Retrying | Failed

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Order_event_type : sig
  type t = Placement | Update | Cancellation

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

type maker_order = {
  asset_id : string;
  matched_amount : Common.Primitives.Decimal.t;
  order_id : string;
  outcome : string option;
  owner : string;
  price : Common.Primitives.Decimal.t;
  maker_address : string option;
  fee_rate_bps : Common.Primitives.Decimal.t option;
  side : string option;
}
[@@deriving yojson, eq]
(** Maker order in a trade *)

type trade_message = {
  event_type : string;
  id : string;
  asset_id : string;
  market : string;
  side : string;
  size : Common.Primitives.Decimal.t;
  price : Common.Primitives.Decimal.t;
  status : Trade_status.t;
  outcome : string option;
  owner : string;
  trade_owner : string option;
  taker_order_id : string;
  maker_orders : maker_order list option;
  matchtime : string option;
  last_update : string option;
  timestamp : string;
  type_ : string;
  fee_rate_bps : Common.Primitives.Decimal.t option;
  maker_address : string option;
  transaction_hash : string option;
  bucket_index : int option;
  trader_side : string option;
}
[@@deriving yojson, eq]
(** Trade message from user channel *)

type order_message = {
  event_type : string;
  id : string;
  asset_id : string;
  market : string;
  side : string;
  price : Common.Primitives.Decimal.t;
  original_size : Common.Primitives.Decimal.t;
  size_matched : Common.Primitives.Decimal.t;
  outcome : string option;
  owner : string;
  order_owner : string option;
  associate_trades : string list option;
  timestamp : string;
  type_ : Order_event_type.t;
  created_at : string option;
  expiration : string option;
  order_type : string option;
  status : string option;
  maker_address : string option;
}
[@@deriving yojson, eq]
(** Order message from user channel *)

(** {1 Unified Message Types} *)

(** Market channel messages. *)
type market_message =
  | Book of book_message
  | Price_change of price_change_message
  | Tick_size_change of tick_size_change_message
  | Last_trade_price of last_trade_price_message
  | Best_bid_ask of best_bid_ask_message
  | New_market of new_market_message
  | Market_resolved of market_resolved_message
[@@deriving eq]

(** User channel messages. *)
type user_message = Trade of trade_message | Order of order_message
[@@deriving eq]

(** Top-level message type. *)
type message =
  | Market of market_message
  | User of user_message
  | Unknown of string
[@@deriving eq]

(** {1 Message Parsing} *)

val parse_message : channel:Channel.t -> string -> message list
(** Parse a raw WebSocket message based on the channel type. *)

(** {1 Subscription Builders} *)

val market_subscribe_json :
  ?initial_dump:bool ->
  ?level:int ->
  ?custom_feature_enabled:bool ->
  asset_ids:string list ->
  unit ->
  string
(** Create a JSON subscribe message for the market channel. *)

val user_subscribe_json :
  credentials:Common.Auth.credentials -> ?markets:string list -> unit -> string
(** Create a JSON subscribe message for the user channel with auth. *)

val user_subscribe_markets_json : markets:string list -> string
(** Create a JSON message to subscribe to additional user channel markets. *)

val user_unsubscribe_markets_json : markets:string list -> string
(** Create a JSON message to unsubscribe from user channel markets. *)

val subscribe_assets_json :
  ?level:int ->
  ?custom_feature_enabled:bool ->
  asset_ids:string list ->
  unit ->
  string
(** Create a JSON message to subscribe to additional assets. *)

val unsubscribe_assets_json :
  ?custom_feature_enabled:bool -> asset_ids:string list -> unit -> string
(** Create a JSON message to unsubscribe from assets. *)
