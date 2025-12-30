(** Real-Time Data Socket (RTDS) message types for Polymarket.

    This module defines types for the RTDS WebSocket streaming service,
    including crypto prices (Binance and Chainlink) and comments. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

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

type crypto_price_payload = { symbol : string; timestamp : int; value : float }
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

(** {1 Unified Message Type (Polymorphic Variants)} *)

type crypto_message =
  [ `Binance of crypto_price_message | `Chainlink of crypto_price_message ]
(** Crypto price messages distinguished by source *)

let show_crypto_message : crypto_message -> string = function
  | `Binance m -> "Binance " ^ show_crypto_price_message m
  | `Chainlink m -> "Chainlink " ^ show_crypto_price_message m

let pp_crypto_message fmt m = Format.fprintf fmt "%s" (show_crypto_message m)

let equal_crypto_message (a : crypto_message) (b : crypto_message) =
  match (a, b) with
  | `Binance a, `Binance b -> equal_crypto_price_message a b
  | `Chainlink a, `Chainlink b -> equal_crypto_price_message a b
  | _ -> false

type comment =
  [ `Comment_created of comment_message
  | `Comment_removed of comment_message
  | `Reaction_created of comment_message
  | `Reaction_removed of comment_message ]
(** Comment-related messages *)

let show_comment : comment -> string = function
  | `Comment_created m -> "Comment_created " ^ show_comment_message m
  | `Comment_removed m -> "Comment_removed " ^ show_comment_message m
  | `Reaction_created m -> "Reaction_created " ^ show_comment_message m
  | `Reaction_removed m -> "Reaction_removed " ^ show_comment_message m

let pp_comment fmt m = Format.fprintf fmt "%s" (show_comment m)

let equal_comment (a : comment) (b : comment) =
  match (a, b) with
  | `Comment_created a, `Comment_created b -> equal_comment_message a b
  | `Comment_removed a, `Comment_removed b -> equal_comment_message a b
  | `Reaction_created a, `Reaction_created b -> equal_comment_message a b
  | `Reaction_removed a, `Reaction_removed b -> equal_comment_message a b
  | _ -> false

type message =
  [ `Crypto of crypto_message | `Comment of comment | `Unknown of string ]
(** Top-level message type for all RTDS messages *)

let show_message : message -> string = function
  | `Crypto m -> "Crypto (" ^ show_crypto_message m ^ ")"
  | `Comment m -> "Comment (" ^ show_comment m ^ ")"
  | `Unknown s -> "Unknown " ^ s

let pp_message fmt m = Format.fprintf fmt "%s" (show_message m)

let equal_message (a : message) (b : message) =
  match (a, b) with
  | `Crypto a, `Crypto b -> equal_crypto_message a b
  | `Comment a, `Comment b -> equal_comment a b
  | `Unknown a, `Unknown b -> String.equal a b
  | _ -> false

(** {1 Message Parsing} *)

let parse_crypto_message (json : Yojson.Safe.t) : crypto_message =
  let msg = crypto_price_message_of_yojson json in
  match msg.topic with
  | "crypto_prices" -> `Binance msg
  | "crypto_prices_chainlink" -> `Chainlink msg
  | topic -> failwith ("Unknown crypto topic: " ^ topic)

let parse_comment_message (json : Yojson.Safe.t) : comment =
  match json with
  | `Assoc fields -> (
      let msg = comment_message_of_yojson json in
      match List.assoc_opt "type" fields with
      | Some (`String "comment_created") -> `Comment_created msg
      | Some (`String "comment_removed") -> `Comment_removed msg
      | Some (`String "reaction_created") -> `Reaction_created msg
      | Some (`String "reaction_removed") -> `Reaction_removed msg
      | Some (`String s) -> failwith ("Unknown comment type: " ^ s)
      | _ -> failwith "Missing or invalid type in comment message")
  | _ -> failwith "Comment message must be a JSON object"

let parse_message (raw : string) : message list =
  try
    let json = Yojson.Safe.from_string raw in
    match json with
    | `Assoc fields -> (
        match List.assoc_opt "topic" fields with
        | Some (`String "crypto_prices")
        | Some (`String "crypto_prices_chainlink") ->
            [ `Crypto (parse_crypto_message json) ]
        | Some (`String "comments") -> [ `Comment (parse_comment_message json) ]
        | Some (`String topic) ->
            [ `Unknown (Printf.sprintf "Unknown topic: %s" topic) ]
        | _ -> [ `Unknown (Printf.sprintf "No topic in message: %s" raw) ])
    | _ -> [ `Unknown (Printf.sprintf "Expected JSON object: %s" raw) ]
  with exn ->
    [ `Unknown (Printf.sprintf "Parse error: %s" (Printexc.to_string exn)) ]

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
  filters : string option; [@yojson.option]
  clob_auth : clob_auth option; [@yojson.option]
  gamma_auth : gamma_auth option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Single subscription request *)

type subscribe_request = { action : string; subscriptions : subscription list }
[@@deriving yojson]
(** Subscribe/unsubscribe request message *)

(** {1 Subscription Builders} *)

let crypto_prices_subscription ?filters () : subscription =
  {
    topic = "crypto_prices";
    type_ = "update";
    filters;
    clob_auth = None;
    gamma_auth = None;
  }

let crypto_prices_chainlink_subscription ?filters () : subscription =
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
    type_ = "comment_created";
    filters = None;
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
