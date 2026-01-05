(** WebSocket message types for Polymarket WSS API.

    This module defines types for the Market and User WebSocket channels. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Channel Types} *)

module Channel = struct
  type t = Market [@value "market"] | User [@value "user"] [@@deriving enum]
end

(** {1 Common Types} *)

type order_summary = { price : string; size : string }
[@@deriving yojson, show, eq]

(** {1 Market Channel Message Types} *)

module Market_event = struct
  type t =
    | Book [@value "book"]
    | Price_change [@value "price_change"]
    | Tick_size_change [@value "tick_size_change"]
    | Last_trade_price [@value "last_trade_price"]
    | Best_bid_ask [@value "best_bid_ask"]
  [@@deriving enum]
end

type book_message = {
  event_type : string; [@key "event_type"]
  asset_id : string; [@key "asset_id"]
  market : string;
  timestamp : string;
  hash : string;
  bids : order_summary list;
  asks : order_summary list;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Book message - full orderbook snapshot *)

type price_change_entry = {
  asset_id : string; [@key "asset_id"]
  price : string;
  size : string;
  side : string;
  hash : string;
  best_bid : string; [@key "best_bid"]
  best_ask : string; [@key "best_ask"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Price change entry within a price_change message *)

type price_change_message = {
  event_type : string; [@key "event_type"]
  market : string;
  price_changes : price_change_entry list; [@key "price_changes"]
  timestamp : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Price change message - incremental orderbook update *)

type tick_size_change_message = {
  event_type : string; [@key "event_type"]
  asset_id : string; [@key "asset_id"]
  market : string;
  old_tick_size : string; [@key "old_tick_size"]
  new_tick_size : string; [@key "new_tick_size"]
  side : string option; [@default None]
  timestamp : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Tick size change message *)

type last_trade_price_message = {
  event_type : string; [@key "event_type"]
  asset_id : string; [@key "asset_id"]
  market : string;
  price : string;
  side : string;
  size : string;
  fee_rate_bps : string; [@key "fee_rate_bps"]
  timestamp : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Last trade price message *)

type best_bid_ask_message = {
  event_type : string; [@key "event_type"]
  asset_id : string; [@key "asset_id"]
  market : string;
  best_bid : string; [@key "best_bid"]
  best_ask : string; [@key "best_ask"]
  timestamp : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Best bid/ask message *)

(** {1 User Channel Message Types} *)

module User_event = struct
  type t = Trade [@value "trade"] | Order [@value "order"] [@@deriving enum]
end

module Trade_status = struct
  type t = Matched | Mined | Confirmed | Retrying | Failed [@@deriving enum]
end

module Order_event_type = struct
  type t = Placement | Update | Cancellation [@@deriving enum]
end

type maker_order = {
  asset_id : string; [@key "asset_id"]
  matched_amount : string; [@key "matched_amount"]
  order_id : string; [@key "order_id"]
  outcome : string;
  owner : string;
  price : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Maker order in a trade *)

type trade_message = {
  event_type : string; [@key "event_type"]
  id : string;
  asset_id : string; [@key "asset_id"]
  market : string;
  side : string;
  size : string;
  price : string;
  status : Trade_status.t;
  outcome : string;
  owner : string;
  trade_owner : string; [@key "trade_owner"]
  taker_order_id : string; [@key "taker_order_id"]
  maker_orders : maker_order list; [@key "maker_orders"]
  matchtime : string;
  last_update : string; [@key "last_update"]
  timestamp : string;
  type_ : string; [@key "type"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Trade message from user channel *)

type order_message = {
  event_type : string; [@key "event_type"]
  id : string;
  asset_id : string; [@key "asset_id"]
  market : string;
  side : string;
  price : string;
  original_size : string; [@key "original_size"]
  size_matched : string; [@key "size_matched"]
  outcome : string;
  owner : string;
  order_owner : string; [@key "order_owner"]
  associate_trades : string list option;
      [@key "associate_trades"] [@default None]
  timestamp : string;
  type_ : Order_event_type.t; [@key "type"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Order message from user channel *)

(** {1 Unified Message Types} *)

(** Market channel messages. *)
type market_message =
  | Book of book_message
  | Price_change of price_change_message
  | Tick_size_change of tick_size_change_message
  | Last_trade_price of last_trade_price_message
  | Best_bid_ask of best_bid_ask_message
[@@deriving show, eq]

(** User channel messages. *)
type user_message = Trade of trade_message | Order of order_message
[@@deriving show, eq]

(** Top-level message type. *)
type message =
  | Market of market_message
  | User of user_message
  | Unknown of string
[@@deriving show, eq]

(** {1 Message Parsing} *)

let parse_market_message (json : Yojson.Safe.t) :
    (market_message, string) result =
  match json with
  | `Assoc fields -> (
      match List.assoc_opt "event_type" fields with
      | Some (`String "book") -> Ok (Book (book_message_of_yojson json))
      | Some (`String "price_change") ->
          Ok (Price_change (price_change_message_of_yojson json))
      | Some (`String "tick_size_change") ->
          Ok (Tick_size_change (tick_size_change_message_of_yojson json))
      | Some (`String "last_trade_price") ->
          Ok (Last_trade_price (last_trade_price_message_of_yojson json))
      | Some (`String "best_bid_ask") ->
          Ok (Best_bid_ask (best_bid_ask_message_of_yojson json))
      | Some (`String s) -> Error ("Unknown market event_type: " ^ s)
      | _ -> Error "Missing or invalid event_type in market message")
  | _ -> Error "Market message must be a JSON object"

let parse_user_message (json : Yojson.Safe.t) : (user_message, string) result =
  match json with
  | `Assoc fields -> (
      match List.assoc_opt "event_type" fields with
      | Some (`String "trade") -> Ok (Trade (trade_message_of_yojson json))
      | Some (`String "order") -> Ok (Order (order_message_of_yojson json))
      | Some (`String s) -> Error ("Unknown user event_type: " ^ s)
      | _ -> Error "Missing or invalid event_type in user message")
  | _ -> Error "User message must be a JSON object"

let parse_message ~channel (raw : string) : message list =
  let parse_single json =
    match channel with
    | Channel.Market -> (
        match parse_market_message json with
        | Ok msg -> Some (Market msg)
        | Error e -> Some (Unknown e))
    | Channel.User -> (
        match parse_user_message json with
        | Ok msg -> Some (User msg)
        | Error e -> Some (Unknown e))
  in
  try
    let json = Yojson.Safe.from_string raw in
    match json with
    | `List [] -> [] (* Empty array is subscription ack, skip it *)
    | `List items ->
        (* Array of messages - parse each one *)
        List.filter_map
          (fun item -> try parse_single item with _ -> None)
          items
    | _ -> (
        (* Single message object *)
        match parse_single json with
        | Some msg -> [ msg ]
        | None -> [])
  with _ -> [ Unknown (Printf.sprintf "Parse error: %s" raw) ]

(** {1 Subscription Request Types} *)

type auth = {
  apiKey : string; [@key "apiKey"]
  secret : string;
  passphrase : string;
}
[@@deriving yojson, show]

type market_subscribe_request = {
  assets_ids : string list; [@key "assets_ids"]
  type_ : string; [@key "type"]
  custom_feature_enabled : bool; [@key "custom_feature_enabled"]
}
[@@deriving yojson]

type user_subscribe_request = {
  markets : string list;
  auth : auth;
  type_ : string; [@key "type"]
}
[@@deriving yojson]

type asset_subscription_request = {
  assets_ids : string list; [@key "assets_ids"]
  operation : string;
  custom_feature_enabled : bool; [@key "custom_feature_enabled"]
}
[@@deriving yojson]

let market_subscribe_json ~asset_ids =
  yojson_of_market_subscribe_request
    { assets_ids = asset_ids; type_ = "MARKET"; custom_feature_enabled = true }
  |> Yojson.Safe.to_string

let user_subscribe_json ~(credentials : Common.Auth.credentials) ~markets =
  let auth =
    {
      apiKey = credentials.api_key;
      secret = credentials.secret;
      passphrase = credentials.passphrase;
    }
  in
  yojson_of_user_subscribe_request { markets; auth; type_ = "USER" }
  |> Yojson.Safe.to_string

let subscribe_assets_json ~asset_ids =
  yojson_of_asset_subscription_request
    {
      assets_ids = asset_ids;
      operation = "subscribe";
      custom_feature_enabled = true;
    }
  |> Yojson.Safe.to_string

let unsubscribe_assets_json ~asset_ids =
  yojson_of_asset_subscription_request
    {
      assets_ids = asset_ids;
      operation = "unsubscribe";
      custom_feature_enabled = true;
    }
  |> Yojson.Safe.to_string
