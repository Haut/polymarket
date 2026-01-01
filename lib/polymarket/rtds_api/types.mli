(** Real-Time Data Socket (RTDS) message types for Polymarket.

    This module defines types for the RTDS WebSocket streaming service,
    including crypto prices (Binance and Chainlink) and comments. *)

(** {1 Topic Types} *)

module Topic : sig
  type t = Crypto_prices | Crypto_prices_chainlink | Comments

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Message Types} *)

module Message_type : sig
  type t =
    | Update
    | Comment_created
    | Comment_removed
    | Reaction_created
    | Reaction_removed
    | All

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Crypto Price Types} *)

type crypto_price_payload = { symbol : string; timestamp : int; value : float }
[@@deriving yojson, eq]
(** Payload for crypto price updates (both Binance and Chainlink sources) *)

type crypto_price_message = {
  topic : string;
  type_ : string;
  timestamp : int;
  payload : crypto_price_payload;
}
[@@deriving yojson, eq]
(** Crypto price message envelope *)

(** {1 Comment Types} *)

type comment_profile = {
  base_address : string;
  display_username_public : bool;
  name : string;
  proxy_wallet : string;
  pseudonym : string;
}
[@@deriving yojson, eq]
(** User profile in comment messages *)

type comment_payload = {
  body : string;
  created_at : string;
  id : string;
  parent_comment_id : string option;
  parent_entity_id : int;
  parent_entity_type : string;
  profile : comment_profile;
  reaction_count : int;
  reply_address : string option;
  report_count : int;
  user_address : string;
}
[@@deriving yojson, eq]
(** Payload for comment messages *)

type comment_message = {
  topic : string;
  type_ : string;
  timestamp : int;
  payload : comment_payload;
}
[@@deriving yojson, eq]
(** Comment message envelope *)

(** {1 Unified Message Types} *)

type crypto_message =
  [ `Binance of crypto_price_message | `Chainlink of crypto_price_message ]
(** Crypto price messages distinguished by source *)

val pp_crypto_message : Format.formatter -> crypto_message -> unit
val equal_crypto_message : crypto_message -> crypto_message -> bool

type comment =
  [ `Comment_created of comment_message
  | `Comment_removed of comment_message
  | `Reaction_created of comment_message
  | `Reaction_removed of comment_message ]
(** Comment-related messages *)

val pp_comment : Format.formatter -> comment -> unit
val equal_comment : comment -> comment -> bool

type message =
  [ `Crypto of crypto_message | `Comment of comment | `Unknown of string ]
(** Top-level message type for all RTDS messages *)

val pp_message : Format.formatter -> message -> unit
val equal_message : message -> message -> bool

(** {1 Message Parsing} *)

val parse_message : string -> message list
(** Parse a raw WebSocket message into typed messages. *)

(** {1 Authentication Types} *)

type clob_auth = { key : string; secret : string; passphrase : string }
[@@deriving yojson, eq]
(** CLOB authentication for trading-related subscriptions *)

type gamma_auth = { address : string } [@@deriving yojson, eq]
(** Gamma authentication for user-specific data *)

(** {1 Subscription Types} *)

type subscription = {
  topic : string;
  type_ : string;
  filters : string option;
  clob_auth : clob_auth option;
  gamma_auth : gamma_auth option;
}
[@@deriving yojson, eq]
(** Single subscription request *)

(** {1 Subscription Builders} *)

val crypto_prices_subscription : ?filters:string -> unit -> subscription
(** Create a Binance crypto prices subscription. *)

val crypto_prices_chainlink_subscription :
  ?filters:string -> unit -> subscription
(** Create a Chainlink crypto prices subscription. *)

val comments_subscription : ?gamma_auth:gamma_auth -> unit -> subscription
(** Create a comments subscription. *)

val subscribe_json : subscriptions:subscription list -> string
(** Create a JSON subscribe message. *)

val unsubscribe_json : subscriptions:subscription list -> string
(** Create a JSON unsubscribe message. *)

(** {1 Filter Builders} *)

val binance_symbol_filter : string list -> string
(** Build a Binance symbol filter from a list of symbols. *)

val chainlink_symbol_filter : string -> string
(** Build a Chainlink symbol filter from a symbol. *)
