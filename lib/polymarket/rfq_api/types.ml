(** RFQ API types for Polymarket.

    These types correspond to the Polymarket RFQ (Request for Quote) API at
    https://clob.polymarket.com/rfq. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Primitive Types} *)

type address = string [@@deriving yojson, show, eq]
(** Ethereum address (0x-prefixed, 40 hex chars). *)

type token_id = string [@@deriving yojson, show, eq]
(** ERC1155 token ID or "0" for USDC. *)

type request_id = string [@@deriving yojson, show, eq]
(** UUID for an RFQ request. *)

type quote_id = string [@@deriving yojson, show, eq]
(** UUID for an RFQ quote. *)

type trade_id = string [@@deriving yojson, show, eq]
(** UUID for a trade. *)

type condition_id = string [@@deriving yojson, show, eq]
(** Market condition ID. *)

(** {1 Enum Modules} *)

module User_type = Polymarket_clob.Types.Signature_type
(** Reuse Signature_type from CLOB as User_type. EOA = 0, POLY_PROXY = 1,
    POLY_GNOSIS_SAFE = 2 *)

module Side = Polymarket_common.Primitives.Side

(** State filter for GET requests. *)
module State_filter = struct
  type t = Active | Inactive [@@deriving enum]
end

(** Request lifecycle states. *)
module Request_state = struct
  type t =
    | Accepting_quotes [@value "STATE_ACCEPTING_QUOTES"]
    | Quote_accepted [@value "STATE_QUOTE_ACCEPTED"]
    | Maker_order_approved [@value "STATE_MAKER_ORDER_APPROVED"]
    | Completed [@value "STATE_COMPLETED"]
    | User_canceled [@value "STATE_USER_CANCELED"]
    | Internal_canceled [@value "STATE_INTERNAL_CANCELED"]
    | Request_expired [@value "STATE_REQUEST_EXPIRED"]
    | Request_execution_failed [@value "STATE_REQUEST_EXECUTION_FAILED"]
  [@@deriving enum]
end

(** Quote lifecycle states. *)
module Quote_state = struct
  type t =
    | Request_quoted [@value "STATE_REQUEST_QUOTED"]
    | Request_accepted_quote [@value "STATE_REQUEST_ACCEPTED_QUOTE"]
    | Maker_approved [@value "STATE_MAKER_APPROVED"]
    | Completed [@value "STATE_COMPLETED"]
    | Maker_canceled [@value "STATE_MAKER_CANCELED"]
    | Request_canceled [@value "STATE_REQUEST_CANCELED"]
    | Request_expired [@value "STATE_REQUEST_EXPIRED"]
    | Execution_failed [@value "STATE_EXECUTION_FAILED"]
    | Maker_rejected_canceled [@value "STATE_MAKER_REJECTED_CANCELED"]
    | Maker_rejected_expired [@value "STATE_MAKER_REJECTED_EXPIRED"]
  [@@deriving enum]
end

(** Sort field for requests and quotes. *)
module Sort_by = struct
  type t = Price | Expiry | Size | Created [@@deriving enum]
end

(** Sort direction. *)
module Sort_dir = struct
  type t = Asc | Desc [@@deriving enum]
end

(** {1 Request Types} *)

type create_request_body = {
  asset_in : token_id; [@key "assetIn"]
  asset_out : token_id; [@key "assetOut"]
  amount_in : string; [@key "amountIn"]
  amount_out : string; [@key "amountOut"]
  user_type : User_type.t; [@key "userType"]
}
[@@deriving yojson, show, eq]
(** Request body for creating an RFQ request. *)

type create_request_response = {
  request_id : request_id; [@key "requestId"]
  expiry : int;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Response from creating an RFQ request. *)

type cancel_request_body = { request_id : request_id [@key "requestId"] }
[@@deriving yojson, show, eq]
(** Request body for canceling an RFQ request. *)

type rfq_request = {
  request_id : request_id; [@key "requestId"]
  user : address;
  proxy : address;
  market : condition_id;
  token : token_id;
  complement : token_id;
  side : Side.t;
  size_in : float; [@key "sizeIn"]
  size_out : float; [@key "sizeOut"]
  price : float;
  expiry : int;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** A single RFQ request in the list response. *)

type get_requests_response = {
  data : rfq_request list;
  next_cursor : string; [@key "next_cursor"]
  limit : int;
  count : int;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Response from getting RFQ requests. *)

(** {1 Quote Types} *)

type create_quote_body = {
  request_id : request_id; [@key "requestId"]
  asset_in : token_id; [@key "assetIn"]
  asset_out : token_id; [@key "assetOut"]
  amount_in : string; [@key "amountIn"]
  amount_out : string; [@key "amountOut"]
  user_type : User_type.t; [@key "userType"]
}
[@@deriving yojson, show, eq]
(** Request body for creating an RFQ quote. *)

type create_quote_response = { quote_id : quote_id [@key "quoteId"] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Response from creating an RFQ quote. *)

type cancel_quote_body = { quote_id : quote_id [@key "quoteId"] }
[@@deriving yojson, show, eq]
(** Request body for canceling an RFQ quote. *)

type rfq_quote = {
  quote_id : quote_id; [@key "quoteId"]
  request_id : request_id; [@key "requestId"]
  user : address;
  proxy : address;
  market : condition_id;
  token : token_id;
  complement : token_id;
  side : Side.t;
  size_in : float; [@key "sizeIn"]
  size_out : float; [@key "sizeOut"]
  price : float;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** A single RFQ quote in the list response. *)

type get_quotes_response = {
  data : rfq_quote list;
  next_cursor : string; [@key "next_cursor"]
  limit : int;
  count : int;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Response from getting RFQ quotes. *)

(** {1 Execution Types} *)

type accept_quote_body = {
  request_id : request_id; [@key "requestId"]
  quote_id : quote_id; [@key "quoteId"]
  maker_amount : string; [@key "makerAmount"]
  taker_amount : string; [@key "takerAmount"]
  token_id : token_id; [@key "tokenId"]
  maker : address;
  signer : address;
  taker : address;
  nonce : string;
  expiration : int;
  side : Side.t;
  fee_rate_bps : string; [@key "feeRateBps"]
  signature : string;
  salt : string;
  owner : string;
}
[@@deriving yojson, show, eq]
(** Request body for accepting a quote (creates an order). *)

type approve_order_body = accept_quote_body [@@deriving yojson, show, eq]
(** Request body for approving an order (same as accept_quote_body). *)

type approve_order_response = { trade_ids : trade_id list [@key "tradeIds"] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Response from approving an order. *)

(** {1 Error Type} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors. *)

let error_to_string = Polymarket_http.Client.error_to_string
let pp_error = Polymarket_http.Client.pp_error
