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

module Order_status = struct
  type t =
    | Live [@value "ORDER_STATUS_LIVE"]
    | Invalid [@value "ORDER_STATUS_INVALID"]
    | Canceled_market_resolved [@value "ORDER_STATUS_CANCELED_MARKET_RESOLVED"]
    | Canceled [@value "ORDER_STATUS_CANCELED"]
    | Matched [@value "ORDER_STATUS_MATCHED"]
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

module Trade_status = struct
  type t =
    | Confirmed [@value "TRADE_STATUS_CONFIRMED"]
    | Failed [@value "TRADE_STATUS_FAILED"]
    | Retrying [@value "TRADE_STATUS_RETRYING"]
    | Matched [@value "TRADE_STATUS_MATCHED"]
    | Mined [@value "TRADE_STATUS_MINED"]
  [@@deriving enum]
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
  token_id : P.U256.t option; [@yojson.option] [@key "tokenId"]
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
  defer_exec : bool option; [@yojson.option] [@key "deferExec"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Request body for creating an order *)

type create_order_response = {
  success : bool option; [@yojson.option]
  error_msg : string option; [@yojson.option] [@key "errorMsg"]
  order_id : string option; [@yojson.option] [@key "orderID"]
  order_hashes : string list; [@default []] [@key "orderHashes"]
  status : Status.t option; [@yojson.option]
  making_amount : string option; [@yojson.option] [@key "makingAmount"]
  taking_amount : string option; [@yojson.option] [@key "takingAmount"]
  transactions_hashes : string list; [@default []] [@key "transactionsHashes"]
  trade_ids : string list; [@default []] [@key "tradeIDs"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from creating an order *)

(** {1 Open Order Types} *)

type open_order = {
  id : string option; [@yojson.option]
  status : Order_status.t option; [@yojson.option]
  market : string option; [@yojson.option]
  asset_id : P.U256.t option; [@yojson.option] [@key "asset_id"]
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

type orders_response = {
  limit : int;
  next_cursor : string; [@key "next_cursor"]
  count : int;
  data : open_order list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Paginated response from get orders endpoint *)

type order_scoring_response = { scoring : bool }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response indicating whether an order is currently scoring for rewards *)

type heartbeat_response = { status : string }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from heartbeat endpoint *)

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
  asset_id : P.U256.t option; [@yojson.option] [@key "asset_id"]
  outcome : string option; [@yojson.option]
  side : Side.t option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Maker order that was filled in a trade *)

type clob_trade = {
  id : string option; [@yojson.option]
  taker_order_id : string option; [@yojson.option] [@key "taker_order_id"]
  market : string option; [@yojson.option]
  asset_id : P.U256.t option; [@yojson.option] [@key "asset_id"]
  side : Side.t option; [@yojson.option]
  size : string option; [@yojson.option]
  fee_rate_bps : string option; [@yojson.option] [@key "fee_rate_bps"]
  price : string option; [@yojson.option]
  status : Trade_status.t option; [@yojson.option]
  match_time : string option; [@yojson.option] [@key "match_time"]
  match_time_nano : string option; [@yojson.option] [@key "match_time_nano"]
  last_update : string option; [@yojson.option] [@key "last_update"]
  outcome : string option; [@yojson.option]
  bucket_index : int option; [@yojson.option] [@key "bucket_index"]
  owner : string option; [@yojson.option]
  maker_address : P.Address.t option; [@yojson.option] [@key "maker_address"]
  transaction_hash : string option; [@yojson.option] [@key "transaction_hash"]
  err_msg : string option; [@yojson.option] [@key "err_msg"]
  maker_orders : maker_order_fill list; [@default []] [@key "maker_orders"]
  trader_side : Trade_type.t option; [@yojson.option] [@key "trader_side"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** A trade on the CLOB *)

type trades_response = {
  limit : int;
  next_cursor : string; [@key "next_cursor"]
  count : int;
  data : clob_trade list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Paginated response from get trades endpoint *)

(** {1 Builder Trade Types} *)

type builder_trade = {
  id : string option; [@yojson.option]
  trade_type : string option; [@yojson.option] [@key "tradeType"]
  taker_order_hash : string option; [@yojson.option] [@key "takerOrderHash"]
  builder : string option; [@yojson.option]
  market : string option; [@yojson.option]
  asset_id : string option; [@yojson.option] [@key "assetId"]
  side : Side.t option; [@yojson.option]
  size : string option; [@yojson.option]
  size_usdc : string option; [@yojson.option] [@key "sizeUsdc"]
  price : string option; [@yojson.option]
  status : string option; [@yojson.option]
  outcome : string option; [@yojson.option]
  outcome_index : int option; [@yojson.option] [@key "outcomeIndex"]
  owner : string option; [@yojson.option]
  maker : P.Address.t option; [@yojson.option]
  transaction_hash : string option; [@yojson.option] [@key "transactionHash"]
  match_time : string option; [@yojson.option] [@key "matchTime"]
  bucket_index : int option; [@yojson.option] [@key "bucketIndex"]
  fee : string option; [@yojson.option]
  fee_usdc : string option; [@yojson.option] [@key "feeUsdc"]
  err_msg : string option; [@yojson.option] [@key "err_msg"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** A builder-originated trade *)

type builder_trades_response = {
  limit : int;
  next_cursor : string; [@key "next_cursor"]
  count : int;
  data : builder_trade list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Paginated response from get builder trades endpoint *)

(** {1 Simplified Market Types} *)

type reward_rate = {
  asset_address : string option; [@yojson.option] [@key "asset_address"]
  rewards_daily_rate : float option; [@yojson.option] [@key "rewards_daily_rate"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Reward rate for a specific asset *)

type rewards = {
  rates : reward_rate list; [@default []]
  min_size : float option; [@yojson.option] [@key "min_size"]
  max_spread : float option; [@yojson.option] [@key "max_spread"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Rewards configuration for a market *)

type market_token = {
  token_id : string option; [@yojson.option] [@key "token_id"]
  outcome : string option; [@yojson.option]
  price : float option; [@yojson.option]
  winner : bool option; [@yojson.option]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Token within a simplified market *)

type simplified_market = {
  condition_id : string option; [@yojson.option] [@key "condition_id"]
  rewards : rewards option; [@yojson.option]
  tokens : market_token list; [@default []]
  active : bool option; [@yojson.option]
  closed : bool option; [@yojson.option]
  archived : bool option; [@yojson.option]
  accepting_orders : bool option; [@yojson.option] [@key "accepting_orders"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** A simplified market from the CLOB *)

type simplified_markets_response = {
  limit : int option; [@yojson.option]
  next_cursor : string option; [@yojson.option] [@key "next_cursor"]
  count : int option; [@yojson.option]
  data : simplified_market list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Paginated response from get simplified markets endpoint *)

type clob_market = {
  enable_order_book : bool option; [@yojson.option] [@key "enable_order_book"]
  active : bool option; [@yojson.option]
  closed : bool option; [@yojson.option]
  archived : bool option; [@yojson.option]
  accepting_orders : bool option; [@yojson.option] [@key "accepting_orders"]
  accepting_order_timestamp : string option;
      [@yojson.option] [@key "accepting_order_timestamp"]
  minimum_order_size : float option;
      [@yojson.option] [@key "minimum_order_size"]
  minimum_tick_size : float option; [@yojson.option] [@key "minimum_tick_size"]
  condition_id : string option; [@yojson.option] [@key "condition_id"]
  question_id : string option; [@yojson.option] [@key "question_id"]
  question : string option; [@yojson.option]
  description : string option; [@yojson.option]
  market_slug : string option; [@yojson.option] [@key "market_slug"]
  end_date_iso : string option; [@yojson.option] [@key "end_date_iso"]
  game_start_time : string option; [@yojson.option] [@key "game_start_time"]
  seconds_delay : int option; [@yojson.option] [@key "seconds_delay"]
  fpmm : string option; [@yojson.option]
  maker_base_fee : int64 option; [@yojson.option] [@key "maker_base_fee"]
  taker_base_fee : int64 option; [@yojson.option] [@key "taker_base_fee"]
  notifications_enabled : bool option;
      [@yojson.option] [@key "notifications_enabled"]
  neg_risk : bool option; [@yojson.option] [@key "neg_risk"]
  neg_risk_market_id : string option;
      [@yojson.option] [@key "neg_risk_market_id"]
  neg_risk_request_id : string option;
      [@yojson.option] [@key "neg_risk_request_id"]
  icon : string option; [@yojson.option]
  image : string option; [@yojson.option]
  rewards : rewards option; [@yojson.option]
  is_50_50_outcome : bool option; [@yojson.option] [@key "is_50_50_outcome"]
  tokens : market_token list; [@default []]
  tags : string list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** A full market from the CLOB *)

type markets_response = {
  limit : int option; [@yojson.option]
  next_cursor : string option; [@yojson.option] [@key "next_cursor"]
  count : int option; [@yojson.option]
  data : clob_market list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Paginated response from get markets endpoint *)

(** {1 Price Types} *)

type price_response = { price : string option [@yojson.option] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from get price endpoint *)

type midpoint_response = {
  mid_price : string option; [@yojson.option] [@key "mid_price"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from get midpoint endpoint *)

type spread_response = { spread : string option [@yojson.option] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from get spread endpoint *)

type token_price = {
  buy : string option; [@yojson.option] [@key "BUY"]
  sell : string option; [@yojson.option] [@key "SELL"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Token prices for buy and sell sides *)

type prices_response = (P.U256.t * token_price) list

let equal_prices_response a b =
  List.length a = List.length b
  && List.for_all2
       (fun (t1, p1) (t2, p2) -> P.U256.equal t1 t2 && equal_token_price p1 p2)
       a b

let pp_prices_response fmt resp =
  Format.fprintf fmt "[%a]"
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.fprintf fmt "; ")
       (fun fmt (tid, tp) ->
         Format.fprintf fmt "(%a, %a)" P.U256.pp tid pp_token_price tp))
    resp

let show_prices_response resp = Format.asprintf "%a" pp_prices_response resp

(** prices_response is a map from token_id to token_price *)

let prices_response_of_yojson json =
  match json with
  | `Assoc pairs ->
      List.map
        (fun (tid_str, v) ->
          (P.U256.unsafe_of_string tid_str, token_price_of_yojson v))
        pairs
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "prices_response: expected object", json))

let yojson_of_prices_response resp =
  `Assoc
    (List.map
       (fun (tid, tp) -> (P.U256.to_string tid, yojson_of_token_price tp))
       resp)

type midpoints_response = (P.U256.t * string) list

let equal_midpoints_response a b =
  List.length a = List.length b
  && List.for_all2
       (fun (t1, s1) (t2, s2) -> P.U256.equal t1 t2 && String.equal s1 s2)
       a b

let pp_midpoints_response fmt resp =
  Format.fprintf fmt "[%a]"
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.fprintf fmt "; ")
       (fun fmt (tid, s) -> Format.fprintf fmt "(%a, %s)" P.U256.pp tid s))
    resp

let show_midpoints_response resp =
  Format.asprintf "%a" pp_midpoints_response resp

(** midpoints_response is a map from token_id to midpoint price *)

let midpoints_response_of_yojson json =
  match json with
  | `Assoc pairs ->
      List.filter_map
        (fun (tid_str, v) ->
          match v with
          | `String s -> Some (P.U256.unsafe_of_string tid_str, s)
          | _ -> None)
        pairs
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "midpoints_response: expected object", json))

let yojson_of_midpoints_response resp =
  `Assoc (List.map (fun (tid, s) -> (P.U256.to_string tid, `String s)) resp)

type spreads_response = (P.U256.t * string) list

let equal_spreads_response a b =
  List.length a = List.length b
  && List.for_all2
       (fun (t1, s1) (t2, s2) -> P.U256.equal t1 t2 && String.equal s1 s2)
       a b

let pp_spreads_response fmt resp =
  Format.fprintf fmt "[%a]"
    (Format.pp_print_list
       ~pp_sep:(fun fmt () -> Format.fprintf fmt "; ")
       (fun fmt (tid, s) -> Format.fprintf fmt "(%a, %s)" P.U256.pp tid s))
    resp

let show_spreads_response resp = Format.asprintf "%a" pp_spreads_response resp

(** spreads_response is a map from token_id to spread value *)

let spreads_response_of_yojson json =
  match json with
  | `Assoc pairs ->
      List.filter_map
        (fun (tid_str, v) ->
          match v with
          | `String s -> Some (P.U256.unsafe_of_string tid_str, s)
          | _ -> None)
        pairs
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "spreads_response: expected object", json))

let yojson_of_spreads_response resp =
  `Assoc (List.map (fun (tid, s) -> (P.U256.to_string tid, `String s)) resp)

type last_trade_price_entry = {
  token_id : string; [@key "token_id"]
  price : string; [@key "price"]
  side : Side.t; [@key "side"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Entry in last trade prices response *)

type fee_rate_response = { base_fee : int64 [@key "base_fee"] }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from get fee rate endpoint *)

type tick_size_response = {
  minimum_tick_size : float; [@key "minimum_tick_size"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from get tick size endpoint *)

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

type rebated_fees = {
  date : string;
  condition_id : string;
  asset_address : string;
  maker_address : string;
  rebated_fees_usdc : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Rebated fees for a maker on a specific market and date *)

(** {1 Error Response} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors *)

let error_to_string = Polymarket_http.Client.error_to_string
let pp_error = Polymarket_http.Client.pp_error
