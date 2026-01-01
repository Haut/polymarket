(** RFQ API types for Polymarket.

    These types correspond to the Polymarket RFQ (Request for Quote) API at
    https://clob.polymarket.com/rfq. *)

(** {1 Primitive Types} *)

type address = string
(** Ethereum address (0x-prefixed, 40 hex chars). *)

type token_id = string
(** ERC1155 token ID or "0" for USDC. *)

type request_id = string
(** UUID for an RFQ request. *)

type quote_id = string
(** UUID for an RFQ quote. *)

type trade_id = string
(** UUID for a trade. *)

type condition_id = string
(** Market condition ID. *)

val address_of_yojson : Yojson.Safe.t -> address
val yojson_of_address : address -> Yojson.Safe.t
val pp_address : Format.formatter -> address -> unit
val show_address : address -> string
val equal_address : address -> address -> bool
val token_id_of_yojson : Yojson.Safe.t -> token_id
val yojson_of_token_id : token_id -> Yojson.Safe.t
val pp_token_id : Format.formatter -> token_id -> unit
val show_token_id : token_id -> string
val equal_token_id : token_id -> token_id -> bool
val request_id_of_yojson : Yojson.Safe.t -> request_id
val yojson_of_request_id : request_id -> Yojson.Safe.t
val pp_request_id : Format.formatter -> request_id -> unit
val show_request_id : request_id -> string
val equal_request_id : request_id -> request_id -> bool
val quote_id_of_yojson : Yojson.Safe.t -> quote_id
val yojson_of_quote_id : quote_id -> Yojson.Safe.t
val pp_quote_id : Format.formatter -> quote_id -> unit
val show_quote_id : quote_id -> string
val equal_quote_id : quote_id -> quote_id -> bool
val trade_id_of_yojson : Yojson.Safe.t -> trade_id
val yojson_of_trade_id : trade_id -> Yojson.Safe.t
val pp_trade_id : Format.formatter -> trade_id -> unit
val show_trade_id : trade_id -> string
val equal_trade_id : trade_id -> trade_id -> bool
val condition_id_of_yojson : Yojson.Safe.t -> condition_id
val yojson_of_condition_id : condition_id -> Yojson.Safe.t
val pp_condition_id : Format.formatter -> condition_id -> unit
val show_condition_id : condition_id -> string
val equal_condition_id : condition_id -> condition_id -> bool

(** {1 Enum Modules} *)

module User_type = Polymarket_clob.Types.Signature_type
(** Reuse Signature_type from CLOB as User_type. EOA = 0, POLY_PROXY = 1,
    POLY_GNOSIS_SAFE = 2 *)

module Side = Polymarket_common.Primitives.Side

(** State filter for GET requests. *)
module State_filter : sig
  type t = Active | Inactive

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** Request lifecycle states. *)
module Request_state : sig
  type t =
    | Accepting_quotes
    | Quote_accepted
    | Maker_order_approved
    | Completed
    | User_canceled
    | Internal_canceled
    | Request_expired
    | Request_execution_failed

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** Quote lifecycle states. *)
module Quote_state : sig
  type t =
    | Request_quoted
    | Request_accepted_quote
    | Maker_approved
    | Completed
    | Maker_canceled
    | Request_canceled
    | Request_expired
    | Execution_failed
    | Maker_rejected_canceled
    | Maker_rejected_expired

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** Sort field for requests and quotes. *)
module Sort_by : sig
  type t = Price | Expiry | Size | Created

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** Sort direction. *)
module Sort_dir : sig
  type t = Asc | Desc

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Request Types} *)

type create_request_body = {
  asset_in : token_id;
  asset_out : token_id;
  amount_in : string;
  amount_out : string;
  user_type : User_type.t;
}
(** Request body for creating an RFQ request. *)

val create_request_body_of_yojson : Yojson.Safe.t -> create_request_body
val yojson_of_create_request_body : create_request_body -> Yojson.Safe.t
val pp_create_request_body : Format.formatter -> create_request_body -> unit
val show_create_request_body : create_request_body -> string

val equal_create_request_body :
  create_request_body -> create_request_body -> bool

type create_request_response = { request_id : request_id; expiry : int }
(** Response from creating an RFQ request. *)

val create_request_response_of_yojson : Yojson.Safe.t -> create_request_response
val yojson_of_create_request_response : create_request_response -> Yojson.Safe.t

val pp_create_request_response :
  Format.formatter -> create_request_response -> unit

val show_create_request_response : create_request_response -> string

val equal_create_request_response :
  create_request_response -> create_request_response -> bool

type cancel_request_body = { request_id : request_id }
(** Request body for canceling an RFQ request. *)

val cancel_request_body_of_yojson : Yojson.Safe.t -> cancel_request_body
val yojson_of_cancel_request_body : cancel_request_body -> Yojson.Safe.t
val pp_cancel_request_body : Format.formatter -> cancel_request_body -> unit
val show_cancel_request_body : cancel_request_body -> string

val equal_cancel_request_body :
  cancel_request_body -> cancel_request_body -> bool

type rfq_request = {
  request_id : request_id;
  user : address;
  proxy : address;
  market : condition_id;
  token : token_id;
  complement : token_id;
  side : Side.t;
  size_in : float;
  size_out : float;
  price : float;
  expiry : int;
}
(** A single RFQ request in the list response. *)

val rfq_request_of_yojson : Yojson.Safe.t -> rfq_request
val yojson_of_rfq_request : rfq_request -> Yojson.Safe.t
val pp_rfq_request : Format.formatter -> rfq_request -> unit
val show_rfq_request : rfq_request -> string
val equal_rfq_request : rfq_request -> rfq_request -> bool

type get_requests_response = {
  data : rfq_request list;
  next_cursor : string;
  limit : int;
  count : int;
}
(** Response from getting RFQ requests. *)

val get_requests_response_of_yojson : Yojson.Safe.t -> get_requests_response
val yojson_of_get_requests_response : get_requests_response -> Yojson.Safe.t
val pp_get_requests_response : Format.formatter -> get_requests_response -> unit
val show_get_requests_response : get_requests_response -> string

val equal_get_requests_response :
  get_requests_response -> get_requests_response -> bool

(** {1 Quote Types} *)

type create_quote_body = {
  request_id : request_id;
  asset_in : token_id;
  asset_out : token_id;
  amount_in : string;
  amount_out : string;
  user_type : User_type.t;
}
(** Request body for creating an RFQ quote. *)

val create_quote_body_of_yojson : Yojson.Safe.t -> create_quote_body
val yojson_of_create_quote_body : create_quote_body -> Yojson.Safe.t
val pp_create_quote_body : Format.formatter -> create_quote_body -> unit
val show_create_quote_body : create_quote_body -> string
val equal_create_quote_body : create_quote_body -> create_quote_body -> bool

type create_quote_response = { quote_id : quote_id }
(** Response from creating an RFQ quote. *)

val create_quote_response_of_yojson : Yojson.Safe.t -> create_quote_response
val yojson_of_create_quote_response : create_quote_response -> Yojson.Safe.t
val pp_create_quote_response : Format.formatter -> create_quote_response -> unit
val show_create_quote_response : create_quote_response -> string

val equal_create_quote_response :
  create_quote_response -> create_quote_response -> bool

type cancel_quote_body = { quote_id : quote_id }
(** Request body for canceling an RFQ quote. *)

val cancel_quote_body_of_yojson : Yojson.Safe.t -> cancel_quote_body
val yojson_of_cancel_quote_body : cancel_quote_body -> Yojson.Safe.t
val pp_cancel_quote_body : Format.formatter -> cancel_quote_body -> unit
val show_cancel_quote_body : cancel_quote_body -> string
val equal_cancel_quote_body : cancel_quote_body -> cancel_quote_body -> bool

type rfq_quote = {
  quote_id : quote_id;
  request_id : request_id;
  user : address;
  proxy : address;
  market : condition_id;
  token : token_id;
  complement : token_id;
  side : Side.t;
  size_in : float;
  size_out : float;
  price : float;
}
(** A single RFQ quote in the list response. *)

val rfq_quote_of_yojson : Yojson.Safe.t -> rfq_quote
val yojson_of_rfq_quote : rfq_quote -> Yojson.Safe.t
val pp_rfq_quote : Format.formatter -> rfq_quote -> unit
val show_rfq_quote : rfq_quote -> string
val equal_rfq_quote : rfq_quote -> rfq_quote -> bool

type get_quotes_response = {
  data : rfq_quote list;
  next_cursor : string;
  limit : int;
  count : int;
}
(** Response from getting RFQ quotes. *)

val get_quotes_response_of_yojson : Yojson.Safe.t -> get_quotes_response
val yojson_of_get_quotes_response : get_quotes_response -> Yojson.Safe.t
val pp_get_quotes_response : Format.formatter -> get_quotes_response -> unit
val show_get_quotes_response : get_quotes_response -> string

val equal_get_quotes_response :
  get_quotes_response -> get_quotes_response -> bool

(** {1 Execution Types} *)

type accept_quote_body = {
  request_id : request_id;
  quote_id : quote_id;
  maker_amount : string;
  taker_amount : string;
  token_id : token_id;
  maker : address;
  signer : address;
  taker : address;
  nonce : string;
  expiration : int;
  side : Side.t;
  fee_rate_bps : string;
  signature : string;
  salt : string;
  owner : string;
}
(** Request body for accepting a quote (creates an order). *)

val accept_quote_body_of_yojson : Yojson.Safe.t -> accept_quote_body
val yojson_of_accept_quote_body : accept_quote_body -> Yojson.Safe.t
val pp_accept_quote_body : Format.formatter -> accept_quote_body -> unit
val show_accept_quote_body : accept_quote_body -> string
val equal_accept_quote_body : accept_quote_body -> accept_quote_body -> bool

type approve_order_body = accept_quote_body
(** Request body for approving an order (same as accept_quote_body). *)

val approve_order_body_of_yojson : Yojson.Safe.t -> approve_order_body
val yojson_of_approve_order_body : approve_order_body -> Yojson.Safe.t
val pp_approve_order_body : Format.formatter -> approve_order_body -> unit
val show_approve_order_body : approve_order_body -> string
val equal_approve_order_body : approve_order_body -> approve_order_body -> bool

type approve_order_response = { trade_ids : trade_id list }
(** Response from approving an order. *)

val approve_order_response_of_yojson : Yojson.Safe.t -> approve_order_response
val yojson_of_approve_order_response : approve_order_response -> Yojson.Safe.t

val pp_approve_order_response :
  Format.formatter -> approve_order_response -> unit

val show_approve_order_response : approve_order_response -> string

val equal_approve_order_response :
  approve_order_response -> approve_order_response -> bool

(** {1 Error Type} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors. *)

val error_to_string : error -> string
(** Convert error to human-readable string. *)

val pp_error : Format.formatter -> error -> unit
(** Pretty printer for errors. *)
