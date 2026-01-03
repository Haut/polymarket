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

type order_summary = { price : string; size : string } [@@deriving yojson, eq]

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
  price : string;
  size : string;
  side : string;
  hash : string;
  best_bid : string;
  best_ask : string;
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
  old_tick_size : string;
  new_tick_size : string;
  side : string option;
  timestamp : string;
}
[@@deriving yojson, eq]
(** Tick size change message *)

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
[@@deriving yojson, eq]
(** Last trade price message *)

type best_bid_ask_message = {
  event_type : string;
  asset_id : string;
  market : string;
  best_bid : string;
  best_ask : string;
  timestamp : string;
}
[@@deriving yojson, eq]
(** Best bid/ask message *)

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
  matched_amount : string;
  order_id : string;
  outcome : string;
  owner : string;
  price : string;
}
[@@deriving yojson, eq]
(** Maker order in a trade *)

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
[@@deriving yojson, eq]
(** Trade message from user channel *)

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
[@@deriving yojson, eq]
(** Order message from user channel *)

(** {1 Unified Message Types} *)

type market_message =
  [ `Book of book_message
  | `Price_change of price_change_message
  | `Tick_size_change of tick_size_change_message
  | `Last_trade_price of last_trade_price_message
  | `Best_bid_ask of best_bid_ask_message ]
[@@deriving eq]
(** Market channel messages using polymorphic variants for extensibility. *)

type user_message = [ `Trade of trade_message | `Order of order_message ]
[@@deriving eq]
(** User channel messages using polymorphic variants for extensibility. *)

type message =
  [ `Market of market_message | `User of user_message | `Unknown of string ]
[@@deriving eq]
(** Top-level message type using polymorphic variants. Allows pattern matching
    on all message types at once. *)

(** {1 Message Parsing} *)

val parse_message : channel:Channel.t -> string -> message list
(** Parse a raw WebSocket message based on the channel type. *)

(** {1 Subscription Builders} *)

val market_subscribe_json : asset_ids:string list -> string
(** Create a JSON subscribe message for the market channel. *)

val user_subscribe_json :
  credentials:Auth.credentials -> markets:string list -> string
(** Create a JSON subscribe message for the user channel with auth. *)

val subscribe_assets_json : asset_ids:string list -> string
(** Create a JSON message to subscribe to additional assets. *)

val unsubscribe_assets_json : asset_ids:string list -> string
(** Create a JSON message to unsubscribe from assets. *)
