(** CLOB API types for Polymarket.

    These types correspond to the Polymarket CLOB API
    (https://clob.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Primitive Types} *)

type address = string [@@deriving yojson, show, eq]
(** Ethereum address (0x-prefixed, 40 hex chars). *)

type signature = string [@@deriving yojson, show, eq]
(** Hex-encoded signature (0x-prefixed). *)

type token_id = string [@@deriving yojson, show, eq]
(** ERC1155 token ID. *)

(** {1 Validation Errors} *)

exception Invalid_address of string
exception Invalid_signature of string

(** {1 Query Parameter Enums} *)

type time_interval =
  | MIN_1
  | MIN_5
  | MIN_15
  | HOUR_1
  | HOUR_6
  | DAY_1
  | WEEK_1
  | MAX
[@@deriving show, eq]

let string_of_time_interval = function
  | MIN_1 -> "1m"
  | MIN_5 -> "5m"
  | MIN_15 -> "15m"
  | HOUR_1 -> "1h"
  | HOUR_6 -> "6h"
  | DAY_1 -> "1d"
  | WEEK_1 -> "1w"
  | MAX -> "max"

let time_interval_of_string = function
  | "1m" -> MIN_1
  | "5m" -> MIN_5
  | "15m" -> MIN_15
  | "1h" -> HOUR_1
  | "6h" -> HOUR_6
  | "1d" -> DAY_1
  | "1w" -> WEEK_1
  | "max" -> MAX
  | s -> failwith ("Unknown time_interval: " ^ s)

(** {1 Domain Enums} *)

(** Order side enum *)
type order_side = BUY | SELL [@@deriving show, eq]

let string_of_order_side = function BUY -> "BUY" | SELL -> "SELL"

let order_side_of_string = function
  | "BUY" | "buy" -> BUY
  | "SELL" | "sell" -> SELL
  | s -> failwith ("Unknown order_side: " ^ s)

let order_side_of_yojson = function
  | `String s -> order_side_of_string s
  | _ -> failwith "order_side_of_yojson: expected string"

let yojson_of_order_side side = `String (string_of_order_side side)

(** Order type enum - time in force *)
type order_type = GTC | GTD | FOK | FAK [@@deriving show, eq]
(** GTC: Good Till Cancelled GTD: Good Till Date FOK: Fill or Kill FAK: Fill and
    Kill *)

let string_of_order_type = function
  | GTC -> "GTC"
  | GTD -> "GTD"
  | FOK -> "FOK"
  | FAK -> "FAK"

let order_type_of_string = function
  | "GTC" | "gtc" -> GTC
  | "GTD" | "gtd" -> GTD
  | "FOK" | "fok" -> FOK
  | "FAK" | "fak" -> FAK
  | s -> failwith ("Unknown order_type: " ^ s)

let order_type_of_yojson = function
  | `String s -> order_type_of_string s
  | _ -> failwith "order_type_of_yojson: expected string"

let yojson_of_order_type t = `String (string_of_order_type t)

(** Signature type enum *)
type signature_type = EOA | POLY_PROXY | POLY_GNOSIS_SAFE
[@@deriving show, eq]
(** EOA: EIP712 signature from externally owned account (0) POLY_PROXY: EIP712
    from Polymarket proxy wallet signer (1) POLY_GNOSIS_SAFE: EIP712 from
    Polymarket Gnosis Safe signer (2) *)

let int_of_signature_type = function
  | EOA -> 0
  | POLY_PROXY -> 1
  | POLY_GNOSIS_SAFE -> 2

let signature_type_of_int = function
  | 0 -> EOA
  | 1 -> POLY_PROXY
  | 2 -> POLY_GNOSIS_SAFE
  | n -> failwith (Printf.sprintf "Unknown signature_type: %d" n)

let signature_type_of_yojson = function
  | `Int n -> signature_type_of_int n
  | `String "0" -> EOA
  | `String "1" -> POLY_PROXY
  | `String "2" -> POLY_GNOSIS_SAFE
  | _ -> failwith "signature_type_of_yojson: expected int or string"

let yojson_of_signature_type t = `Int (int_of_signature_type t)

(** Order status enum *)
type order_status = LIVE | MATCHED | DELAYED | UNMATCHED | CANCELLED | EXPIRED
[@@deriving show, eq]

let string_of_order_status = function
  | LIVE -> "LIVE"
  | MATCHED -> "MATCHED"
  | DELAYED -> "DELAYED"
  | UNMATCHED -> "UNMATCHED"
  | CANCELLED -> "CANCELLED"
  | EXPIRED -> "EXPIRED"

let order_status_of_string = function
  | "live" | "LIVE" -> LIVE
  | "matched" | "MATCHED" -> MATCHED
  | "delayed" | "DELAYED" -> DELAYED
  | "unmatched" | "UNMATCHED" -> UNMATCHED
  | "cancelled" | "CANCELLED" -> CANCELLED
  | "expired" | "EXPIRED" -> EXPIRED
  | s -> failwith ("Unknown order_status: " ^ s)

let order_status_of_yojson = function
  | `String s -> order_status_of_string s
  | _ -> failwith "order_status_of_yojson: expected string"

let yojson_of_order_status s = `String (string_of_order_status s)

(** Trade type enum *)
type trade_type = TAKER | MAKER [@@deriving show, eq]

let string_of_trade_type = function TAKER -> "TAKER" | MAKER -> "MAKER"

let trade_type_of_string = function
  | "TAKER" | "taker" -> TAKER
  | "MAKER" | "maker" -> MAKER
  | s -> failwith ("Unknown trade_type: " ^ s)

let trade_type_of_yojson = function
  | `String s -> trade_type_of_string s
  | _ -> failwith "trade_type_of_yojson: expected string"

let yojson_of_trade_type t = `String (string_of_trade_type t)

(** {1 Order Book Types} *)

type order_book_level = {
  price : string option; [@yojson.option]
  size : string option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Order book price level with price and size *)

type order_book_summary = {
  market : string option; [@yojson.option]
  asset_id : string option; [@yojson.option] [@key "asset_id"]
  timestamp : string option; [@yojson.option]
  hash : string option; [@yojson.option]
  bids : order_book_level list; [@default []]
  asks : order_book_level list; [@default []]
  min_order_size : string option; [@yojson.option] [@key "min_order_size"]
  tick_size : string option; [@yojson.option] [@key "tick_size"]
  neg_risk : bool option; [@yojson.option] [@key "neg_risk"]
}
[@@deriving yojson, show, eq]
(** Order book summary for a token *)

(** {1 Signed Order Types} *)

type signed_order = {
  salt : string option; [@yojson.option]
  maker : address option; [@yojson.option]
  signer : address option; [@yojson.option]
  taker : address option; [@yojson.option]
  token_id : token_id option; [@yojson.option] [@key "tokenId"]
  maker_amount : string option; [@yojson.option] [@key "makerAmount"]
  taker_amount : string option; [@yojson.option] [@key "takerAmount"]
  expiration : string option; [@yojson.option]
  nonce : string option; [@yojson.option]
  fee_rate_bps : string option; [@yojson.option] [@key "feeRateBps"]
  side : order_side option; [@yojson.option]
  signature_type : signature_type option;
      [@yojson.option] [@key "signatureType"]
  signature : signature option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Cryptographically signed order for the CLOB *)

type order_request = {
  order : signed_order option; [@yojson.option]
  owner : string option; [@yojson.option]
  order_type : order_type option; [@yojson.option] [@key "orderType"]
}
[@@deriving yojson, show, eq]
(** Request body for creating an order *)

type create_order_response = {
  success : bool option; [@yojson.option]
  error_msg : string option; [@yojson.option] [@key "errorMsg"]
  order_id : string option; [@yojson.option] [@key "orderId"]
  order_hashes : string list; [@default []] [@key "orderHashes"]
  status : order_status option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Response from creating an order *)

(** {1 Open Order Types} *)

type open_order = {
  id : string option; [@yojson.option]
  status : order_status option; [@yojson.option]
  market : string option; [@yojson.option]
  asset_id : token_id option; [@yojson.option] [@key "asset_id"]
  original_size : string option; [@yojson.option] [@key "original_size"]
  size_matched : string option; [@yojson.option] [@key "size_matched"]
  price : string option; [@yojson.option]
  side : order_side option; [@yojson.option]
  outcome : string option; [@yojson.option]
  maker_address : address option; [@yojson.option] [@key "maker_address"]
  owner : string option; [@yojson.option]
  expiration : string option; [@yojson.option]
  order_type : order_type option; [@yojson.option] [@key "type"]
  created_at : string option; [@yojson.option] [@key "created_at"]
  associate_trades : string list; [@default []] [@key "associate_trades"]
}
[@@deriving yojson, show, eq]
(** An open/active order *)

(** {1 Cancel Types} *)

type cancel_response = {
  canceled : string list; [@default []]
  not_canceled : (string * string) list; [@default []] [@key "not_canceled"]
}
[@@deriving show, eq]
(** Response from canceling orders *)

(** Custom JSON handling for cancel_response due to map structure *)
let cancel_response_of_yojson json =
  match json with
  | `Assoc fields ->
      let canceled =
        match List.assoc_opt "canceled" fields with
        | Some (`List items) ->
            List.filter_map (function `String s -> Some s | _ -> None) items
        | _ -> []
      in
      let not_canceled =
        match List.assoc_opt "not_canceled" fields with
        | Some (`Assoc pairs) ->
            List.filter_map
              (fun (k, v) ->
                match v with `String s -> Some (k, s) | _ -> None)
              pairs
        | _ -> []
      in
      { canceled; not_canceled }
  | _ -> failwith "cancel_response_of_yojson: expected object"

let yojson_of_cancel_response resp =
  `Assoc
    [
      ("canceled", `List (List.map (fun s -> `String s) resp.canceled));
      ( "not_canceled",
        `Assoc (List.map (fun (k, v) -> (k, `String v)) resp.not_canceled) );
    ]

(** {1 Trade Types} *)

type maker_order_fill = {
  order_id : string option; [@yojson.option] [@key "order_id"]
  maker_address : address option; [@yojson.option] [@key "maker_address"]
  owner : string option; [@yojson.option]
  matched_amount : string option; [@yojson.option] [@key "matched_amount"]
  fee_rate_bps : string option; [@yojson.option] [@key "fee_rate_bps"]
  price : string option; [@yojson.option]
  asset_id : token_id option; [@yojson.option] [@key "asset_id"]
  outcome : string option; [@yojson.option]
  side : order_side option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Maker order that was filled in a trade *)

type clob_trade = {
  id : string option; [@yojson.option]
  taker_order_id : string option; [@yojson.option] [@key "taker_order_id"]
  market : string option; [@yojson.option]
  asset_id : token_id option; [@yojson.option] [@key "asset_id"]
  side : order_side option; [@yojson.option]
  size : string option; [@yojson.option]
  fee_rate_bps : string option; [@yojson.option] [@key "fee_rate_bps"]
  price : string option; [@yojson.option]
  status : string option; [@yojson.option]
  match_time : string option; [@yojson.option] [@key "match_time"]
  last_update : string option; [@yojson.option] [@key "last_update"]
  outcome : string option; [@yojson.option]
  maker_address : address option; [@yojson.option] [@key "maker_address"]
  owner : string option; [@yojson.option]
  transaction_hash : string option; [@yojson.option] [@key "transaction_hash"]
  bucket_index : int option; [@yojson.option] [@key "bucket_index"]
  maker_orders : maker_order_fill list; [@default []] [@key "maker_orders"]
  trade_type : trade_type option; [@yojson.option] [@key "type"]
}
[@@deriving yojson, show, eq]
(** A trade on the CLOB *)

(** {1 Price Types} *)

type price_response = { price : string option [@yojson.option] }
[@@deriving yojson, show, eq]
(** Response from get price endpoint *)

type midpoint_response = { mid : string option [@yojson.option] }
[@@deriving yojson, show, eq]
(** Response from get midpoint endpoint *)

type token_price = {
  buy : string option; [@yojson.option] [@key "BUY"]
  sell : string option; [@yojson.option] [@key "SELL"]
}
[@@deriving yojson, show, eq]
(** Token prices for buy and sell sides *)

type prices_response = (token_id * token_price) list [@@deriving show, eq]
(** prices_response is a map from token_id to token_price *)

let prices_response_of_yojson = function
  | `Assoc pairs ->
      List.map (fun (token_id, v) -> (token_id, token_price_of_yojson v)) pairs
  | _ -> failwith "prices_response_of_yojson: expected object"

let yojson_of_prices_response resp =
  `Assoc (List.map (fun (tid, tp) -> (tid, yojson_of_token_price tp)) resp)

type spreads_response = (token_id * string) list [@@deriving show, eq]
(** spreads_response is a map from token_id to spread value *)

let spreads_response_of_yojson = function
  | `Assoc pairs ->
      List.filter_map
        (fun (token_id, v) ->
          match v with `String s -> Some (token_id, s) | _ -> None)
        pairs
  | _ -> failwith "spreads_response_of_yojson: expected object"

let yojson_of_spreads_response resp =
  `Assoc (List.map (fun (tid, s) -> (tid, `String s)) resp)

(** {1 Timeseries Types} *)

type price_point = {
  t : int64 option; [@yojson.option]
  p : float option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Single price point with timestamp and price *)

type price_history = { history : price_point list [@default []] }
[@@deriving yojson, show, eq]
(** Historical price data *)

(** {1 Error Response} *)

type error_response = Polymarket_http.Client.error_response = { error : string }
[@@deriving yojson, show, eq]
(** Error response (alias to Polymarket_http.Client.error_response) *)

(** {1 Validation Functions}

    These functions delegate to Polymarket_common.Primitives for validation
    logic. This ensures a single source of truth for validation rules. *)

(** Validates an address string (0x-prefixed, 40 hex chars). *)
let is_valid_address s =
  match Polymarket_common.Primitives.Address.make s with
  | Ok _ -> true
  | Error _ -> false

(** Validates a hex signature string (0x-prefixed). *)
let is_valid_signature s =
  match Polymarket_common.Primitives.Hash.make s with
  | Ok _ -> true
  | Error _ -> false

(** {1 Validating Deserializers} *)

(** Deserialize an address with validation.
    @raise Invalid_address if the address doesn't match the expected pattern *)
let address_of_yojson_exn json =
  let addr = address_of_yojson json in
  if is_valid_address addr then addr else raise (Invalid_address addr)

(** Deserialize a signature with validation.
    @raise Invalid_signature if the signature is invalid *)
let signature_of_yojson_exn json =
  let sig_ = signature_of_yojson json in
  if is_valid_signature sig_ then sig_ else raise (Invalid_signature sig_)

(** Deserialize an address with validation, returning a result. *)
let address_of_yojson_result json =
  try
    let addr = address_of_yojson json in
    if is_valid_address addr then Ok addr
    else Error ("Invalid address format: " ^ addr)
  with Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _) ->
    Error ("JSON parse error: " ^ Printexc.to_string exn)

(** Deserialize a signature with validation, returning a result. *)
let signature_of_yojson_result json =
  try
    let sig_ = signature_of_yojson json in
    if is_valid_signature sig_ then Ok sig_
    else Error ("Invalid signature format: " ^ sig_)
  with Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _) ->
    Error ("JSON parse error: " ^ Printexc.to_string exn)
