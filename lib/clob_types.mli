(** CLOB API types for Polymarket.

    These types correspond to the Polymarket CLOB API
    (https://clob.polymarket.com). *)

(** {1 Primitives Module Alias} *)

module P = Primitives

(** {1 Enum Modules} *)

module Side = Primitives.Side

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

module Signature_type : sig
  type t =
    | Eoa
    | Poly_proxy
    | Poly_gnosis_safe
        (** Eoa: EIP712 from externally owned account (0), Poly_proxy: EIP712
            from Polymarket proxy wallet signer (1), Poly_gnosis_safe: EIP712
            from Polymarket Gnosis Safe signer (2) *)

  val to_int : t -> int
  val of_int : int -> t
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
  token_id : P.Token_id.t option;
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
  status : Status.t option;
  market : string option;
  asset_id : P.Token_id.t option;
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
  asset_id : P.Token_id.t option;
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
  asset_id : P.Token_id.t option;
  side : Side.t option;
  size : string option;
  fee_rate_bps : string option;
  price : string option;
  status : string option;
  match_time : string option;
  last_update : string option;
  outcome : string option;
  maker_address : P.Address.t option;
  owner : string option;
  transaction_hash : string option;
  bucket_index : int option;
  maker_orders : maker_order_fill list;
  trade_type : Trade_type.t option;
}
(** A trade on the CLOB *)

val clob_trade_of_yojson : Yojson.Safe.t -> clob_trade
val yojson_of_clob_trade : clob_trade -> Yojson.Safe.t
val pp_clob_trade : Format.formatter -> clob_trade -> unit
val show_clob_trade : clob_trade -> string
val equal_clob_trade : clob_trade -> clob_trade -> bool

(** {1 Price Types} *)

type price_response = { price : string option }
(** Response from get price endpoint *)

val price_response_of_yojson : Yojson.Safe.t -> price_response
val yojson_of_price_response : price_response -> Yojson.Safe.t
val pp_price_response : Format.formatter -> price_response -> unit
val show_price_response : price_response -> string
val equal_price_response : price_response -> price_response -> bool

type midpoint_response = { mid : string option }
(** Response from get midpoint endpoint *)

val midpoint_response_of_yojson : Yojson.Safe.t -> midpoint_response
val yojson_of_midpoint_response : midpoint_response -> Yojson.Safe.t
val pp_midpoint_response : Format.formatter -> midpoint_response -> unit
val show_midpoint_response : midpoint_response -> string
val equal_midpoint_response : midpoint_response -> midpoint_response -> bool

type token_price = { buy : string option; sell : string option }
(** Token prices for buy and sell sides *)

val token_price_of_yojson : Yojson.Safe.t -> token_price
val yojson_of_token_price : token_price -> Yojson.Safe.t
val pp_token_price : Format.formatter -> token_price -> unit
val show_token_price : token_price -> string
val equal_token_price : token_price -> token_price -> bool

type prices_response = (P.Token_id.t * token_price) list
(** Map from token_id to token_price *)

val prices_response_of_yojson : Yojson.Safe.t -> prices_response
val yojson_of_prices_response : prices_response -> Yojson.Safe.t
val pp_prices_response : Format.formatter -> prices_response -> unit
val show_prices_response : prices_response -> string
val equal_prices_response : prices_response -> prices_response -> bool

type spreads_response = (P.Token_id.t * string) list
(** Map from token_id to spread value *)

val spreads_response_of_yojson : Yojson.Safe.t -> spreads_response
val yojson_of_spreads_response : spreads_response -> Yojson.Safe.t
val pp_spreads_response : Format.formatter -> spreads_response -> unit
val show_spreads_response : spreads_response -> string
val equal_spreads_response : spreads_response -> spreads_response -> bool

(** {1 Timeseries Types} *)

type price_point = { t : int64 option; p : float option }
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

(** {1 Error Types} *)

type error = Http_client.error
(** Structured error type for all API errors (alias to Http_client.error) *)

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
val yojson_fields_of_maker_order_fill : string list
val yojson_fields_of_clob_trade : string list
val yojson_fields_of_price_response : string list
val yojson_fields_of_midpoint_response : string list
val yojson_fields_of_token_price : string list
val yojson_fields_of_price_point : string list
val yojson_fields_of_price_history : string list
