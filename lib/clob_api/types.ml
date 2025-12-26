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

(** {1 Enum Modules} *)

module Side = struct
  type t = Buy | Sell [@@deriving show, eq]

  let to_string = function Buy -> "BUY" | Sell -> "SELL"

  let of_string = function
    | "BUY" | "buy" -> Buy
    | "SELL" | "sell" -> Sell
    | s -> failwith ("Unknown side: " ^ s)

  let t_of_yojson = function
    | `String s -> of_string s
    | _ -> failwith "Side.t_of_yojson: expected string"

  let yojson_of_t t = `String (to_string t)
end

module Order_type = struct
  (** Gtc: Good Till Cancelled, Gtd: Good Till Date, Fok: Fill or Kill, Fak:
      Fill and Kill *)
  type t = Gtc | Gtd | Fok | Fak [@@deriving show, eq]

  let to_string = function
    | Gtc -> "GTC"
    | Gtd -> "GTD"
    | Fok -> "FOK"
    | Fak -> "FAK"

  let of_string = function
    | "GTC" | "gtc" -> Gtc
    | "GTD" | "gtd" -> Gtd
    | "FOK" | "fok" -> Fok
    | "FAK" | "fak" -> Fak
    | s -> failwith ("Unknown order_type: " ^ s)

  let t_of_yojson = function
    | `String s -> of_string s
    | _ -> failwith "Order_type.t_of_yojson: expected string"

  let yojson_of_t t = `String (to_string t)
end

module Interval = struct
  type t = Min_1 | Min_5 | Min_15 | Hour_1 | Hour_6 | Day_1 | Week_1 | Max
  [@@deriving show, eq]

  let to_string = function
    | Min_1 -> "1m"
    | Min_5 -> "5m"
    | Min_15 -> "15m"
    | Hour_1 -> "1h"
    | Hour_6 -> "6h"
    | Day_1 -> "1d"
    | Week_1 -> "1w"
    | Max -> "max"

  let of_string = function
    | "1m" -> Min_1
    | "5m" -> Min_5
    | "15m" -> Min_15
    | "1h" -> Hour_1
    | "6h" -> Hour_6
    | "1d" -> Day_1
    | "1w" -> Week_1
    | "max" -> Max
    | s -> failwith ("Unknown interval: " ^ s)
end

module Status = struct
  type t = Live | Matched | Delayed | Unmatched | Cancelled | Expired
  [@@deriving show, eq]

  let to_string = function
    | Live -> "LIVE"
    | Matched -> "MATCHED"
    | Delayed -> "DELAYED"
    | Unmatched -> "UNMATCHED"
    | Cancelled -> "CANCELLED"
    | Expired -> "EXPIRED"

  let of_string = function
    | "live" | "LIVE" -> Live
    | "matched" | "MATCHED" -> Matched
    | "delayed" | "DELAYED" -> Delayed
    | "unmatched" | "UNMATCHED" -> Unmatched
    | "cancelled" | "CANCELLED" -> Cancelled
    | "expired" | "EXPIRED" -> Expired
    | s -> failwith ("Unknown status: " ^ s)

  let t_of_yojson = function
    | `String s -> of_string s
    | _ -> failwith "Status.t_of_yojson: expected string"

  let yojson_of_t t = `String (to_string t)
end

module Signature_type = struct
  (** Eoa: EIP712 from externally owned account (0), Poly_proxy: EIP712 from
      Polymarket proxy wallet signer (1), Poly_gnosis_safe: EIP712 from
      Polymarket Gnosis Safe signer (2) *)
  type t = Eoa | Poly_proxy | Poly_gnosis_safe [@@deriving show, eq]

  let to_int = function Eoa -> 0 | Poly_proxy -> 1 | Poly_gnosis_safe -> 2

  let of_int = function
    | 0 -> Eoa
    | 1 -> Poly_proxy
    | 2 -> Poly_gnosis_safe
    | n -> failwith (Printf.sprintf "Unknown signature_type: %d" n)

  let t_of_yojson = function
    | `Int n -> of_int n
    | `String "0" -> Eoa
    | `String "1" -> Poly_proxy
    | `String "2" -> Poly_gnosis_safe
    | _ -> failwith "Signature_type.t_of_yojson: expected int or string"

  let yojson_of_t t = `Int (to_int t)
end

module Trade_type = struct
  type t = Taker | Maker [@@deriving show, eq]

  let to_string = function Taker -> "TAKER" | Maker -> "MAKER"

  let of_string = function
    | "TAKER" | "taker" -> Taker
    | "MAKER" | "maker" -> Maker
    | s -> failwith ("Unknown trade_type: " ^ s)

  let t_of_yojson = function
    | `String s -> of_string s
    | _ -> failwith "Trade_type.t_of_yojson: expected string"

  let yojson_of_t t = `String (to_string t)
end

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
  side : Side.t option; [@yojson.option]
  signature_type : Signature_type.t option;
      [@yojson.option] [@key "signatureType"]
  signature : signature option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Cryptographically signed order for the CLOB *)

type order_request = {
  order : signed_order option; [@yojson.option]
  owner : string option; [@yojson.option]
  order_type : Order_type.t option; [@yojson.option] [@key "orderType"]
}
[@@deriving yojson, show, eq]
(** Request body for creating an order *)

type create_order_response = {
  success : bool option; [@yojson.option]
  error_msg : string option; [@yojson.option] [@key "errorMsg"]
  order_id : string option; [@yojson.option] [@key "orderId"]
  order_hashes : string list; [@default []] [@key "orderHashes"]
  status : Status.t option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Response from creating an order *)

(** {1 Open Order Types} *)

type open_order = {
  id : string option; [@yojson.option]
  status : Status.t option; [@yojson.option]
  market : string option; [@yojson.option]
  asset_id : token_id option; [@yojson.option] [@key "asset_id"]
  original_size : string option; [@yojson.option] [@key "original_size"]
  size_matched : string option; [@yojson.option] [@key "size_matched"]
  price : string option; [@yojson.option]
  side : Side.t option; [@yojson.option]
  outcome : string option; [@yojson.option]
  maker_address : address option; [@yojson.option] [@key "maker_address"]
  owner : string option; [@yojson.option]
  expiration : string option; [@yojson.option]
  order_type : Order_type.t option; [@yojson.option] [@key "type"]
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
  side : Side.t option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Maker order that was filled in a trade *)

type clob_trade = {
  id : string option; [@yojson.option]
  taker_order_id : string option; [@yojson.option] [@key "taker_order_id"]
  market : string option; [@yojson.option]
  asset_id : token_id option; [@yojson.option] [@key "asset_id"]
  side : Side.t option; [@yojson.option]
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
  trade_type : Trade_type.t option; [@yojson.option] [@key "type"]
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
