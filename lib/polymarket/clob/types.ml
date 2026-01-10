(** CLOB API types for Polymarket.

    These types correspond to the Polymarket CLOB API
    (https://clob.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Primitives Module Alias} *)

module P = Common.Primitives

(** {1 Enum Modules} *)

module Side = Common.Primitives.Side
(** Re-export shared Side module from Common.Primitives *)

(** Gtc: Good Till Cancelled, Gtd: Good Till Date, Fok: Fill or Kill, Fak: Fill
    and Kill *)
module Order_type = struct
  type t = Gtc | Gtd | Fok | Fak [@@deriving enum]
end

module Interval = struct
  type t =
    | Min_1 [@value "1m"]
    | Min_5 [@value "5m"]
    | Min_15 [@value "15m"]
    | Hour_1 [@value "1h"]
    | Hour_6 [@value "6h"]
    | Day_1 [@value "1d"]
    | Week_1 [@value "1w"]
    | Max [@value "max"]
  [@@deriving enum]
end

module Status = struct
  type t = Live | Matched | Delayed | Unmatched | Cancelled | Expired
  [@@deriving enum]
end

(** Eoa: EIP712 from externally owned account (0), Poly_proxy: EIP712 from
    Polymarket proxy wallet signer (1), Poly_gnosis_safe: EIP712 from Polymarket
    Gnosis Safe signer (2) *)
module Signature_type = struct
  type t = Eoa | Poly_proxy | Poly_gnosis_safe

  let to_int = function Eoa -> 0 | Poly_proxy -> 1 | Poly_gnosis_safe -> 2

  let of_int_opt = function
    | 0 -> Some Eoa
    | 1 -> Some Poly_proxy
    | 2 -> Some Poly_gnosis_safe
    | _ -> None

  let t_of_yojson json =
    let error msg =
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (Failure msg, json))
    in
    match json with
    | `Int n -> (
        match of_int_opt n with
        | Some v -> v
        | None -> error (Printf.sprintf "Unknown Signature_type: %d" n))
    | `String s -> (
        match int_of_string_opt s with
        | Some n -> (
            match of_int_opt n with
            | Some v -> v
            | None -> error (Printf.sprintf "Unknown Signature_type: %d" n))
        | None -> error ("Expected int for Signature_type, got: " ^ s))
    | _ -> error "Expected int for Signature_type"

  let yojson_of_t t = `Int (to_int t)
  let pp fmt t = Format.fprintf fmt "%d" (to_int t)
  let equal a b = Int.equal (to_int a) (to_int b)
end

module Trade_type = struct
  type t = Taker | Maker [@@deriving enum]
end

(** {1 Order Book Types} *)

type order_book_level = {
  price : string option; [@yojson.option]
  size : string option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
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
  last_trade_price : string option; [@yojson.option] [@key "last_trade_price"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Order book summary for a token *)

(** {1 Signed Order Types} *)

type signed_order = {
  salt : string option; [@yojson.option]
  maker : P.Address.t option; [@yojson.option]
  signer : P.Address.t option; [@yojson.option]
  taker : P.Address.t option; [@yojson.option]
  token_id : P.Token_id.t option; [@yojson.option] [@key "tokenId"]
  maker_amount : string option; [@yojson.option] [@key "makerAmount"]
  taker_amount : string option; [@yojson.option] [@key "takerAmount"]
  expiration : string option; [@yojson.option]
  nonce : string option; [@yojson.option]
  fee_rate_bps : string option; [@yojson.option] [@key "feeRateBps"]
  side : Side.t option; [@yojson.option]
  signature_type : Signature_type.t option;
      [@yojson.option] [@key "signatureType"]
  signature : P.Signature.t option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Cryptographically signed order for the CLOB *)

type order_request = {
  order : signed_order option; [@yojson.option]
  owner : string option; [@yojson.option]
  order_type : Order_type.t option; [@yojson.option] [@key "orderType"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Request body for creating an order *)

type create_order_response = {
  success : bool option; [@yojson.option]
  error_msg : string option; [@yojson.option] [@key "errorMsg"]
  order_id : string option; [@yojson.option] [@key "orderId"]
  order_hashes : string list; [@default []] [@key "orderHashes"]
  status : Status.t option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from creating an order *)

(** {1 Open Order Types} *)

type open_order = {
  id : string option; [@yojson.option]
  status : Status.t option; [@yojson.option]
  market : string option; [@yojson.option]
  asset_id : P.Token_id.t option; [@yojson.option] [@key "asset_id"]
  original_size : string option; [@yojson.option] [@key "original_size"]
  size_matched : string option; [@yojson.option] [@key "size_matched"]
  price : string option; [@yojson.option]
  side : Side.t option; [@yojson.option]
  outcome : string option; [@yojson.option]
  maker_address : P.Address.t option; [@yojson.option] [@key "maker_address"]
  owner : string option; [@yojson.option]
  expiration : string option; [@yojson.option]
  order_type : Order_type.t option; [@yojson.option] [@key "type"]
  created_at : string option; [@yojson.option] [@key "created_at"]
  associate_trades : string list; [@default []] [@key "associate_trades"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
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
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "cancel_response: expected object", json))

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
  maker_address : P.Address.t option; [@yojson.option] [@key "maker_address"]
  owner : string option; [@yojson.option]
  matched_amount : string option; [@yojson.option] [@key "matched_amount"]
  fee_rate_bps : string option; [@yojson.option] [@key "fee_rate_bps"]
  price : string option; [@yojson.option]
  asset_id : P.Token_id.t option; [@yojson.option] [@key "asset_id"]
  outcome : string option; [@yojson.option]
  side : Side.t option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Maker order that was filled in a trade *)

type clob_trade = {
  id : string option; [@yojson.option]
  taker_order_id : string option; [@yojson.option] [@key "taker_order_id"]
  market : string option; [@yojson.option]
  asset_id : P.Token_id.t option; [@yojson.option] [@key "asset_id"]
  side : Side.t option; [@yojson.option]
  size : string option; [@yojson.option]
  fee_rate_bps : string option; [@yojson.option] [@key "fee_rate_bps"]
  price : string option; [@yojson.option]
  status : string option; [@yojson.option]
  match_time : string option; [@yojson.option] [@key "match_time"]
  last_update : string option; [@yojson.option] [@key "last_update"]
  outcome : string option; [@yojson.option]
  maker_address : P.Address.t option; [@yojson.option] [@key "maker_address"]
  owner : string option; [@yojson.option]
  transaction_hash : string option; [@yojson.option] [@key "transaction_hash"]
  bucket_index : int option; [@yojson.option] [@key "bucket_index"]
  maker_orders : maker_order_fill list; [@default []] [@key "maker_orders"]
  trade_type : Trade_type.t option; [@yojson.option] [@key "type"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** A trade on the CLOB *)

(** {1 Price Types} *)

type price_response = { price : string option [@yojson.option] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from get price endpoint *)

type midpoint_response = { mid : string option [@yojson.option] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from get midpoint endpoint *)

type token_price = {
  buy : string option; [@yojson.option] [@key "BUY"]
  sell : string option; [@yojson.option] [@key "SELL"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Token prices for buy and sell sides *)

type prices_response = (P.Token_id.t * token_price) list

let equal_prices_response a b =
  List.length a = List.length b
  && List.for_all2
       (fun (t1, p1) (t2, p2) ->
         P.Token_id.equal t1 t2 && equal_token_price p1 p2)
       a b

let pp_prices_response fmt resp =
  Format.fprintf fmt "[%a]"
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.fprintf fmt "; ")
       (fun fmt (tid, tp) ->
         Format.fprintf fmt "(%a, %a)" P.Token_id.pp tid pp_token_price tp))
    resp

let show_prices_response resp = Format.asprintf "%a" pp_prices_response resp

(** prices_response is a map from token_id to token_price *)

let prices_response_of_yojson json =
  match json with
  | `Assoc pairs ->
      List.map
        (fun (tid_str, v) ->
          (P.Token_id.unsafe_of_string tid_str, token_price_of_yojson v))
        pairs
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "prices_response: expected object", json))

let yojson_of_prices_response resp =
  `Assoc
    (List.map
       (fun (tid, tp) -> (P.Token_id.to_string tid, yojson_of_token_price tp))
       resp)

type spreads_response = (P.Token_id.t * string) list

let equal_spreads_response a b =
  List.length a = List.length b
  && List.for_all2
       (fun (t1, s1) (t2, s2) -> P.Token_id.equal t1 t2 && String.equal s1 s2)
       a b

let pp_spreads_response fmt resp =
  Format.fprintf fmt "[%a]"
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.fprintf fmt "; ")
       (fun fmt (tid, s) -> Format.fprintf fmt "(%a, %s)" P.Token_id.pp tid s))
    resp

let show_spreads_response resp = Format.asprintf "%a" pp_spreads_response resp

(** spreads_response is a map from token_id to spread value *)

let spreads_response_of_yojson json =
  match json with
  | `Assoc pairs ->
      List.filter_map
        (fun (tid_str, v) ->
          match v with
          | `String s -> Some (P.Token_id.unsafe_of_string tid_str, s)
          | _ -> None)
        pairs
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "spreads_response: expected object", json))

let yojson_of_spreads_response resp =
  `Assoc (List.map (fun (tid, s) -> (P.Token_id.to_string tid, `String s)) resp)

(** {1 Timeseries Types} *)

type price_point = {
  t : int64 option; [@yojson.option]
  p : P.Decimal.t option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Single price point with timestamp and price *)

type price_history = { history : price_point list [@default []] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Historical price data *)

(** {1 Error Response} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors *)

let error_to_string = Polymarket_http.Client.error_to_string
let pp_error = Polymarket_http.Client.pp_error
