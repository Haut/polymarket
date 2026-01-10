(** Real-Time Data Socket (RTDS) message types for Polymarket.

    This module defines types for the RTDS WebSocket streaming service,
    including crypto prices (Binance and Chainlink) and comments. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module P = Common.Primitives

(** {1 Topic Types} *)

module Topic = struct
  type t =
    | Crypto_prices [@value "crypto_prices"]
    | Crypto_prices_chainlink [@value "crypto_prices_chainlink"]
    | Comments [@value "comments"]
  [@@deriving enum]
end

(** {1 Message Types} *)

module Message_type = struct
  type t =
    | Update [@value "update"]
    | Comment_created [@value "comment_created"]
    | Comment_removed [@value "comment_removed"]
    | Reaction_created [@value "reaction_created"]
    | Reaction_removed [@value "reaction_removed"]
    | All [@value "*"]
  [@@deriving enum]
end

(** {1 Crypto Price Types} *)

type crypto_price_payload = {
  symbol : string;
  timestamp : int;
  value : P.Decimal.t;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Payload for crypto price updates (both Binance and Chainlink sources) *)

type crypto_price_message = {
  topic : string;
  type_ : string; [@key "type"]
  timestamp : int;
  payload : crypto_price_payload;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Crypto price message envelope *)

(** {1 Comment Types} *)

type comment_profile = {
  base_address : string; [@key "baseAddress"]
  display_username_public : bool; [@key "displayUsernamePublic"]
  name : string;
  proxy_wallet : string; [@key "proxyWallet"]
  pseudonym : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** User profile in comment messages *)

type comment_payload = {
  body : string;
  created_at : string; [@key "createdAt"]
  id : string;
  parent_comment_id : string option; [@key "parentCommentID"] [@default None]
  parent_entity_id : int; [@key "parentEntityID"]
  parent_entity_type : string; [@key "parentEntityType"]
  profile : comment_profile;
  reaction_count : int; [@key "reactionCount"]
  reply_address : string option; [@key "replyAddress"] [@default None]
  report_count : int; [@key "reportCount"]
  user_address : string; [@key "userAddress"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Payload for comment messages *)

type comment_message = {
  topic : string;
  type_ : string; [@key "type"]
  timestamp : int;
  payload : comment_payload;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Comment message envelope *)

(** {1 Unified Message Types} *)

(** Crypto price messages distinguished by source *)
type crypto_message =
  | Binance of crypto_price_message
  | Chainlink of crypto_price_message
[@@deriving show, eq]

(** Comment-related messages *)
type comment =
  | Comment_created of comment_message
  | Comment_removed of comment_message
  | Reaction_created of comment_message
  | Reaction_removed of comment_message
[@@deriving show, eq]

(** Top-level message type for all RTDS messages *)
type message =
  | Crypto of crypto_message
  | Comment of comment
  | Unknown of string
[@@deriving show, eq]

(** {1 Message Parsing} *)

let parse_crypto_message (json : Yojson.Safe.t) :
    (crypto_message, string) result =
  let msg = crypto_price_message_of_yojson json in
  match msg.topic with
  | "crypto_prices" -> Ok (Binance msg)
  | "crypto_prices_chainlink" -> Ok (Chainlink msg)
  | topic -> Error ("Unknown crypto topic: " ^ topic)

let parse_comment_message (json : Yojson.Safe.t) : (comment, string) result =
  match json with
  | `Assoc fields -> (
      let msg = comment_message_of_yojson json in
      match List.assoc_opt "type" fields with
      | Some (`String "comment_created") -> Ok (Comment_created msg)
      | Some (`String "comment_removed") -> Ok (Comment_removed msg)
      | Some (`String "reaction_created") -> Ok (Reaction_created msg)
      | Some (`String "reaction_removed") -> Ok (Reaction_removed msg)
      | Some (`String s) -> Error ("Unknown comment type: " ^ s)
      | _ -> Error "Missing or invalid type in comment message")
  | _ -> Error "Comment message must be a JSON object"

let parse_message (raw : string) : message list =
  try
    let json = Yojson.Safe.from_string raw in
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "topic" fields with
        | Some (`String "crypto_prices")
        | Some (`String "crypto_prices_chainlink") -> (
            match parse_crypto_message json with
            | Ok msg -> [ Crypto msg ]
            | Error e -> [ Unknown e ])
        | Some (`String "comments") -> (
            match parse_comment_message json with
            | Ok msg -> [ Comment msg ]
            | Error e -> [ Unknown e ])
        | Some (`String topic) ->
            [ Unknown (Printf.sprintf "Unknown topic: %s" topic) ]
        | _ -> [ Unknown (Printf.sprintf "No topic in message: %s" raw) ])
    | _ -> [ Unknown (Printf.sprintf "Expected JSON object: %s" raw) ]
  with exn ->
    [ Unknown (Printf.sprintf "Parse error: %s" (Printexc.to_string exn)) ]

(** {1 Authentication Types} *)

type clob_auth = { key : string; secret : string; passphrase : string }
[@@deriving yojson, show, eq]
(** CLOB authentication for trading-related subscriptions *)

type gamma_auth = { address : string } [@@deriving yojson, show, eq]
(** Gamma authentication for user-specific data *)

(** {1 Subscription Types} *)

type subscription = {
  topic : string;
  type_ : string; [@key "type"]
  filters : string; [@default ""]
  clob_auth : clob_auth option; [@yojson.option]
  gamma_auth : gamma_auth option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Single subscription request *)

type subscribe_request = { action : string; subscriptions : subscription list }
[@@deriving yojson]
(** Subscribe/unsubscribe request message *)

(** {1 Subscription Builders} *)

let crypto_prices_subscription ?(filters = "") () : subscription =
  {
    topic = "crypto_prices";
    type_ = "*";
    filters;
    clob_auth = None;
    gamma_auth = None;
  }

let crypto_prices_chainlink_subscription ?(filters = "") () : subscription =
  {
    topic = "crypto_prices_chainlink";
    type_ = "*";
    filters;
    clob_auth = None;
    gamma_auth = None;
  }

let comments_subscription ?gamma_auth () : subscription =
  {
    topic = "comments";
    type_ = "*";
    filters = "";
    clob_auth = None;
    gamma_auth;
  }

let subscribe_json ~subscriptions =
  yojson_of_subscribe_request { action = "subscribe"; subscriptions }
  |> Yojson.Safe.to_string

let unsubscribe_json ~subscriptions =
  yojson_of_subscribe_request { action = "unsubscribe"; subscriptions }
  |> Yojson.Safe.to_string

(** {1 Filter Builders} *)

let binance_symbol_filter symbols = String.concat "," symbols
let chainlink_symbol_filter symbol = Printf.sprintf "{\"symbol\":\"%s\"}" symbol
