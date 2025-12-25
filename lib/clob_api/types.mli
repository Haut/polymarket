(** CLOB API types for Polymarket.

    These types correspond to the Polymarket CLOB API
    (https://clob.polymarket.com). *)

(** {1 Primitive Types} *)

type address = string
(** Ethereum address (0x-prefixed, 40 hex chars). *)

type signature = string
(** Hex-encoded signature (0x-prefixed). *)

type token_id = string
(** ERC1155 token ID. *)

val address_of_yojson : Yojson.Safe.t -> address
val yojson_of_address : address -> Yojson.Safe.t
val pp_address : Format.formatter -> address -> unit
val show_address : address -> string
val equal_address : address -> address -> bool
val signature_of_yojson : Yojson.Safe.t -> signature
val yojson_of_signature : signature -> Yojson.Safe.t
val pp_signature : Format.formatter -> signature -> unit
val show_signature : signature -> string
val equal_signature : signature -> signature -> bool
val token_id_of_yojson : Yojson.Safe.t -> token_id
val yojson_of_token_id : token_id -> Yojson.Safe.t
val pp_token_id : Format.formatter -> token_id -> unit
val show_token_id : token_id -> string
val equal_token_id : token_id -> token_id -> bool

(** {1 Validation Errors} *)

exception Invalid_address of string
exception Invalid_signature of string

(** {1 Enums} *)

(** Order side enum *)
type order_side = BUY | SELL

val string_of_order_side : order_side -> string
val order_side_of_string : string -> order_side
val order_side_of_yojson : Yojson.Safe.t -> order_side
val yojson_of_order_side : order_side -> Yojson.Safe.t
val pp_order_side : Format.formatter -> order_side -> unit
val show_order_side : order_side -> string
val equal_order_side : order_side -> order_side -> bool

(** Order type enum - time in force *)
type order_type =
  | GTC
  | GTD
  | FOK
  | FAK
      (** GTC: Good Till Cancelled GTD: Good Till Date FOK: Fill or Kill FAK:
          Fill and Kill *)

val string_of_order_type : order_type -> string
val order_type_of_string : string -> order_type
val order_type_of_yojson : Yojson.Safe.t -> order_type
val yojson_of_order_type : order_type -> Yojson.Safe.t
val pp_order_type : Format.formatter -> order_type -> unit
val show_order_type : order_type -> string
val equal_order_type : order_type -> order_type -> bool

(** Signature type enum *)
type signature_type =
  | EOA
  | POLY_PROXY
  | POLY_GNOSIS_SAFE
      (** EOA: EIP712 signature from externally owned account (0) POLY_PROXY:
          EIP712 from Polymarket proxy wallet signer (1) POLY_GNOSIS_SAFE:
          EIP712 from Polymarket Gnosis Safe signer (2) *)

val int_of_signature_type : signature_type -> int
val signature_type_of_int : int -> signature_type
val signature_type_of_yojson : Yojson.Safe.t -> signature_type
val yojson_of_signature_type : signature_type -> Yojson.Safe.t
val pp_signature_type : Format.formatter -> signature_type -> unit
val show_signature_type : signature_type -> string
val equal_signature_type : signature_type -> signature_type -> bool

(** Order status enum *)
type order_status = LIVE | MATCHED | DELAYED | UNMATCHED | CANCELLED | EXPIRED

val string_of_order_status : order_status -> string
val order_status_of_string : string -> order_status
val order_status_of_yojson : Yojson.Safe.t -> order_status
val yojson_of_order_status : order_status -> Yojson.Safe.t
val pp_order_status : Format.formatter -> order_status -> unit
val show_order_status : order_status -> string
val equal_order_status : order_status -> order_status -> bool

(** Trade type enum *)
type trade_type = TAKER | MAKER

val string_of_trade_type : trade_type -> string
val trade_type_of_string : string -> trade_type
val trade_type_of_yojson : Yojson.Safe.t -> trade_type
val yojson_of_trade_type : trade_type -> Yojson.Safe.t
val pp_trade_type : Format.formatter -> trade_type -> unit
val show_trade_type : trade_type -> string
val equal_trade_type : trade_type -> trade_type -> bool

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
  maker : address option;
  signer : address option;
  taker : address option;
  token_id : token_id option;
  maker_amount : string option;
  taker_amount : string option;
  expiration : string option;
  nonce : string option;
  fee_rate_bps : string option;
  side : order_side option;
  signature_type : signature_type option;
  signature : signature option;
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
  order_type : order_type option;
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
  status : order_status option;
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
  status : order_status option;
  market : string option;
  asset_id : token_id option;
  original_size : string option;
  size_matched : string option;
  price : string option;
  side : order_side option;
  outcome : string option;
  maker_address : address option;
  owner : string option;
  expiration : string option;
  order_type : order_type option;
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
  maker_address : address option;
  owner : string option;
  matched_amount : string option;
  fee_rate_bps : string option;
  price : string option;
  asset_id : token_id option;
  outcome : string option;
  side : order_side option;
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
  asset_id : token_id option;
  side : order_side option;
  size : string option;
  fee_rate_bps : string option;
  price : string option;
  status : string option;
  match_time : string option;
  last_update : string option;
  outcome : string option;
  maker_address : address option;
  owner : string option;
  transaction_hash : string option;
  bucket_index : int option;
  maker_orders : maker_order_fill list;
  trade_type : trade_type option;
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

type prices_response = (token_id * token_price) list
(** Map from token_id to token_price *)

val prices_response_of_yojson : Yojson.Safe.t -> prices_response
val yojson_of_prices_response : prices_response -> Yojson.Safe.t
val pp_prices_response : Format.formatter -> prices_response -> unit
val show_prices_response : prices_response -> string
val equal_prices_response : prices_response -> prices_response -> bool

type spreads_response = (token_id * string) list
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

(** {1 Error Response} *)

type error_response = Http_client.Client.error_response = { error : string }
(** Error response (alias to Http_client.Client.error_response) *)

val error_response_of_yojson : Yojson.Safe.t -> error_response
val yojson_of_error_response : error_response -> Yojson.Safe.t
val pp_error_response : Format.formatter -> error_response -> unit
val show_error_response : error_response -> string
val equal_error_response : error_response -> error_response -> bool

(** {1 Validation Functions} *)

val is_valid_address : address -> bool
(** Validates an address string (0x-prefixed, 40 hex chars). *)

val is_valid_signature : signature -> bool
(** Validates a hex signature string (0x-prefixed). *)

(** {1 Validating Deserializers} *)

val address_of_yojson_exn : Yojson.Safe.t -> address
(** Deserialize an address with validation.
    @raise Invalid_address if the address doesn't match the expected pattern *)

val signature_of_yojson_exn : Yojson.Safe.t -> signature
(** Deserialize a signature with validation.
    @raise Invalid_signature if the signature is invalid *)

val address_of_yojson_result : Yojson.Safe.t -> (address, string) result
(** Deserialize an address with validation, returning a result. *)

val signature_of_yojson_result : Yojson.Safe.t -> (signature, string) result
(** Deserialize a signature with validation, returning a result. *)
