(** Typestate-authenticated HTTP client for the Polymarket CLOB API.

    This module provides compile-time enforcement of authentication requirements
    for the CLOB API. Three authentication levels are available:

    - {!Unauthed}: Public endpoints only (order book, pricing, timeseries)
    - {!L1}: L1 wallet authentication (create/derive API keys) + public
      endpoints
    - {!L2}: L2 API key authentication (orders, trades) + L1 + public endpoints

    The typestate pattern ensures that authentication-required endpoints can
    only be called on clients with the appropriate credentials configured.

    {2 Typical Usage}

    {[
      (* Start with an unauthenticated client for public data *)
      let client = Unauthed.create ~sw ~net ~rate_limiter () in
      let order_book = Unauthed.get_order_book client ~token_id () in

      (* Upgrade to L1 for wallet-based operations *)
      let l1_client = upgrade_to_l1 client ~private_key in

      (* Derive API credentials and upgrade to L2 *)
      match L1.derive_api_key l1_client ~nonce:0 with
      | Ok (l2_client, _resp) ->
          (* Now we can create orders *)
          let _ = L2.create_order l2_client ~order ~owner ~order_type () in
          ()
      | Error e -> error_to_string e |> failwith
    ]} *)

(** {1 Types from Internal Libraries}

    These types are re-exported for convenience. *)

type private_key = Polymarket_common.Crypto.private_key
(** Ethereum private key (hex string, without 0x prefix). *)

type credentials = Polymarket_common.Auth.credentials = {
  api_key : string;
  secret : string;
  passphrase : string;
}
(** API credentials for L2 authentication. *)

type api_key_response = Polymarket_common.Auth.api_key_response = {
  api_key : string;
  secret : string;
  passphrase : string;
}
(** Response from API key creation/derivation endpoints. *)

type rate_limiter = Polymarket_rate_limiter.Rate_limiter.t
(** Rate limiter for enforcing API limits. *)

type error = Polymarket_http.Client.error
(** Error type for API operations. *)

val error_to_string : error -> string
(** Convert an error to a human-readable string. *)

val default_base_url : string
(** Default base URL for the CLOB API: https://clob.polymarket.com *)

(** {1 Client Types}

    These abstract types represent the three authentication levels. *)

type unauthed
(** Unauthenticated client for public endpoints only. *)

type l1
(** L1-authenticated client with private key for wallet operations. *)

type l2
(** L2-authenticated client with full API access. *)

(** {1 Unauthenticated Client}

    Provides access to public endpoints that don't require any authentication.
*)
module Unauthed : sig
  type t = unauthed
  (** Unauthenticated client for public endpoints only. *)

  val create :
    ?base_url:string ->
    sw:Eio.Switch.t ->
    net:_ Eio.Net.t ->
    rate_limiter:rate_limiter ->
    unit ->
    t
  (** Create a new unauthenticated CLOB client.
      @param base_url Optional base URL (defaults to {!default_base_url})
      @param sw The Eio switch for resource management
      @param net The Eio network interface
      @param rate_limiter Shared rate limiter for enforcing API limits *)

  (** {2 Order Book} *)

  val get_order_book :
    t -> token_id:string -> unit -> (Types.order_book_summary, error) result

  val get_order_books :
    t ->
    token_ids:string list ->
    unit ->
    (Types.order_book_summary list, error) result

  (** {2 Pricing} *)

  val get_price :
    t ->
    token_id:string ->
    side:Types.Side.t ->
    unit ->
    (Types.price_response, error) result

  val get_midpoint :
    t -> token_id:string -> unit -> (Types.midpoint_response, error) result

  val get_prices :
    t ->
    requests:(string * Types.Side.t) list ->
    unit ->
    (Types.prices_response, error) result

  val get_spreads :
    t -> token_ids:string list -> unit -> (Types.spreads_response, error) result

  (** {2 Timeseries} *)

  val get_price_history :
    t ->
    market:string ->
    ?start_ts:int ->
    ?end_ts:int ->
    ?interval:Types.Interval.t ->
    ?fidelity:int ->
    unit ->
    (Types.price_history, error) result
end

(** {1 L1-Authenticated Client}

    Provides L1 (wallet-based) authentication for creating and deriving API
    keys, plus all public endpoints. L1 authentication uses EIP-712 signatures
    from the wallet's private key. *)
module L1 : sig
  type t = l1
  (** L1-authenticated client with private key for wallet operations. *)

  val create :
    ?base_url:string ->
    sw:Eio.Switch.t ->
    net:_ Eio.Net.t ->
    rate_limiter:rate_limiter ->
    private_key:private_key ->
    unit ->
    t
  (** Create a new L1-authenticated CLOB client.
      @param base_url Optional base URL (defaults to {!default_base_url})
      @param sw The Eio switch for resource management
      @param net The Eio network interface
      @param rate_limiter Shared rate limiter for enforcing API limits
      @param private_key The wallet's private key for signing *)

  val address : t -> string
  (** Get the Ethereum address derived from the private key. *)

  (** {2 L1 Authentication Endpoints} *)

  val create_api_key : t -> nonce:int -> (api_key_response, error) result
  (** Create a new API key using L1 wallet authentication. Returns the API key,
      secret, and passphrase. *)

  val derive_api_key : t -> nonce:int -> (l2 * api_key_response, error) result
  (** Derive API key from wallet and automatically upgrade to L2 client. Returns
      both the L2 client and the raw response (for credential storage). *)

  (** {2 Order Book} *)

  val get_order_book :
    t -> token_id:string -> unit -> (Types.order_book_summary, error) result

  val get_order_books :
    t ->
    token_ids:string list ->
    unit ->
    (Types.order_book_summary list, error) result

  (** {2 Pricing} *)

  val get_price :
    t ->
    token_id:string ->
    side:Types.Side.t ->
    unit ->
    (Types.price_response, error) result

  val get_midpoint :
    t -> token_id:string -> unit -> (Types.midpoint_response, error) result

  val get_prices :
    t ->
    requests:(string * Types.Side.t) list ->
    unit ->
    (Types.prices_response, error) result

  val get_spreads :
    t -> token_ids:string list -> unit -> (Types.spreads_response, error) result

  (** {2 Timeseries} *)

  val get_price_history :
    t ->
    market:string ->
    ?start_ts:int ->
    ?end_ts:int ->
    ?interval:Types.Interval.t ->
    ?fidelity:int ->
    unit ->
    (Types.price_history, error) result
end

(** {1 L2-Authenticated Client}

    Provides L2 (API key-based) authentication for order management, trades, and
    all other authenticated endpoints, plus L1 and public endpoints. L2
    authentication uses HMAC-SHA256 signatures with the API credentials. *)
module L2 : sig
  type t = l2
  (** L2-authenticated client with full API access. *)

  val create :
    ?base_url:string ->
    sw:Eio.Switch.t ->
    net:_ Eio.Net.t ->
    rate_limiter:rate_limiter ->
    private_key:private_key ->
    credentials:credentials ->
    unit ->
    t
  (** Create a new L2-authenticated CLOB client.
      @param base_url Optional base URL (defaults to {!default_base_url})
      @param sw The Eio switch for resource management
      @param net The Eio network interface
      @param rate_limiter Shared rate limiter for enforcing API limits
      @param private_key The wallet's private key (for L1 operations)
      @param credentials The API credentials (api_key, secret, passphrase) *)

  val address : t -> string
  (** Get the Ethereum address derived from the private key. *)

  val credentials : t -> credentials
  (** Get the API credentials. *)

  (** {2 L1 Authentication Endpoints} *)

  val create_api_key : t -> nonce:int -> (api_key_response, error) result
  (** Create a new API key using L1 wallet authentication. *)

  val delete_api_key : t -> (unit, error) result
  (** Delete the current API key. *)

  val get_api_keys : t -> (string list, error) result
  (** Get all API keys for this address. *)

  (** {2 Orders} *)

  val create_order :
    t ->
    order:Types.signed_order ->
    owner:string ->
    order_type:Types.Order_type.t ->
    unit ->
    (Types.create_order_response, error) result
  (** Create a new order on the CLOB. *)

  val create_orders :
    t ->
    orders:(Types.signed_order * string * Types.Order_type.t) list ->
    unit ->
    (Types.create_order_response list, error) result
  (** Create multiple orders on the CLOB. *)

  val get_order :
    t -> order_id:string -> unit -> (Types.open_order, error) result
  (** Get details of a specific order. *)

  val get_orders :
    t ->
    ?market:string ->
    ?asset_id:string ->
    unit ->
    (Types.open_order list, error) result
  (** Get all open orders, optionally filtered by market or asset. *)

  (** {2 Cancel Orders} *)

  val cancel_order :
    t -> order_id:string -> unit -> (Types.cancel_response, error) result
  (** Cancel a specific order. *)

  val cancel_orders :
    t -> order_ids:string list -> unit -> (Types.cancel_response, error) result
  (** Cancel multiple orders. *)

  val cancel_all : t -> unit -> (Types.cancel_response, error) result
  (** Cancel all open orders. *)

  val cancel_market_orders :
    t ->
    ?market:string ->
    ?asset_id:string ->
    unit ->
    (Types.cancel_response, error) result
  (** Cancel all orders for a market or asset. *)

  (** {2 Trades} *)

  val get_trades :
    t ->
    ?id:string ->
    ?taker:string ->
    ?maker:string ->
    ?market:string ->
    ?before:string ->
    ?after:string ->
    unit ->
    (Types.clob_trade list, error) result
  (** Get trade history. *)

  (** {2 Order Book} *)

  val get_order_book :
    t -> token_id:string -> unit -> (Types.order_book_summary, error) result

  val get_order_books :
    t ->
    token_ids:string list ->
    unit ->
    (Types.order_book_summary list, error) result

  (** {2 Pricing} *)

  val get_price :
    t ->
    token_id:string ->
    side:Types.Side.t ->
    unit ->
    (Types.price_response, error) result

  val get_midpoint :
    t -> token_id:string -> unit -> (Types.midpoint_response, error) result

  val get_prices :
    t ->
    requests:(string * Types.Side.t) list ->
    unit ->
    (Types.prices_response, error) result

  val get_spreads :
    t -> token_ids:string list -> unit -> (Types.spreads_response, error) result

  (** {2 Timeseries} *)

  val get_price_history :
    t ->
    market:string ->
    ?start_ts:int ->
    ?end_ts:int ->
    ?interval:Types.Interval.t ->
    ?fidelity:int ->
    unit ->
    (Types.price_history, error) result
end

(** {1 State Transitions}

    Functions to upgrade or downgrade authentication levels. *)

val upgrade_to_l1 : unauthed -> private_key:private_key -> l1
(** Upgrade an unauthenticated client to L1 by providing a private key. The
    address is derived from the private key automatically. *)

val upgrade_to_l2 : l1 -> credentials:credentials -> l2
(** Upgrade an L1 client to L2 by providing API credentials. *)

val l2_to_l1 : l2 -> l1
(** Downgrade an L2 client to L1 (loses L2 capabilities). *)

val l2_to_unauthed : l2 -> unauthed
(** Downgrade an L2 client to unauthenticated (for public endpoints only). *)

val l1_to_unauthed : l1 -> unauthed
(** Downgrade an L1 client to unauthenticated (for public endpoints only). *)
