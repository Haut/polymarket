(** Polymarket OCaml client library.

    This library provides typed clients for the Polymarket APIs:
    - {!Gamma}: Markets, events, series, and search (gamma-api.polymarket.com)
    - {!Data}: Positions, trades, activity, and leaderboards
      (data-api.polymarket.com)
    - {!Clob}: Order books, pricing, and trading (clob.polymarket.com)
    - {!Rate_limiter}: Route-based rate limiting middleware

    {2 Example Usage}

    {[
      Eio_main.run @@ fun env ->
      Eio.Switch.run @@ fun sw ->
      let client = Polymarket.Gamma.create ~sw ~net:(Eio.Stdenv.net env) () in
      match Polymarket.Gamma.get_events client () with
      | Ok events -> List.iter (fun e -> print_endline e.title) events
      | Error err -> print_endline ("Error: " ^ err.error)
    ]}

    {2 Rate Limiting}

    Pass a clock to enable automatic rate limiting with Polymarket API presets:

    {[
      let client =
        Polymarket.Gamma.create ~sw ~net:(Eio.Stdenv.net env)
          ~clock:(Eio.Stdenv.clock env) ()
      in
      (* Requests are now automatically rate limited *)
    ]}

    {2 Validated Primitive Types}

    The library uses validated types for addresses, hashes, and numeric
    constraints. These are available at the top level for convenience:
    - {!Address}: Ethereum addresses (0x-prefixed, 40 hex chars)
    - {!Hash64}: 64-character hex hashes
    - {!Hash}: Variable-length hex strings
    - {!Nonneg_int}, {!Pos_int}, {!Nonneg_float}: Numeric constraints
    - {!Limit}, {!Offset}: Pagination parameters with bounds

    {2 Sub-libraries}

    For finer-grained control, you can depend on sub-libraries directly:
    - [polymarket.common]: Shared primitives and logging
    - [polymarket.http]: HTTP client utilities
    - [polymarket.rate_limiter]: Rate limiting middleware
    - [polymarket.gamma]: Gamma API client
    - [polymarket.data]: Data API client
    - [polymarket.clob]: CLOB API client *)

(** {1 API Modules} *)

module Gamma : sig
  (** Gamma API client for markets, events, series, and search.

      Combines client functions, response types, and query enums from
      {!Polymarket_gamma}. *)

  include module type of Polymarket_gamma.Client
  include module type of Polymarket_gamma.Responses
  include module type of Polymarket_gamma.Query
end

module Data : sig
  (** Data API client for positions, trades, activity, and leaderboards.

      Combines client functions and response types from {!Polymarket_data}. *)

  include module type of Polymarket_data.Client
  include module type of Polymarket_data.Types
end

module Clob : sig
  (** CLOB API client for order books, pricing, and trading.

      {2 Typestate Authentication}

      The CLOB client uses a typestate pattern to enforce authentication
      requirements at compile time:

      - {!Unauthed}: Public endpoints only (order book, pricing, timeseries)
      - {!L1}: Wallet authentication (create/derive API keys) + public endpoints
      - {!L2}: API key authentication (orders, trades) + L1 + public endpoints

      {[
        (* Create unauthenticated client *)
        let client = Clob.Unauthed.create ~sw ~net () in

        (* Get price with scoped enum *)
        let price = Clob.Unauthed.get_price client ~token_id ~side:Clob.Types.Side.Buy () in

        (* Upgrade to L1 with private key *)
        let l1 = Clob.upgrade_to_l1 client ~private_key in

        (* Derive API key to get L2 client *)
        match Clob.L1.derive_api_key l1 ~nonce with
        | Ok (l2, resp) -> Clob.L2.get_orders l2 ()
        | Error _ -> ...
      ]} *)

  include module type of Polymarket_clob.Client
  module Types = Polymarket_clob.Types
  module Auth = Polymarket_clob.Auth
  module Auth_types = Polymarket_clob.Auth_types
  module Crypto = Polymarket_clob.Crypto

  type unauthed = Polymarket_clob.Client_typestate.unauthed
  type l1 = Polymarket_clob.Client_typestate.l1
  type l2 = Polymarket_clob.Client_typestate.l2

  module Unauthed = Polymarket_clob.Client_typestate.Unauthed
  module L1 = Polymarket_clob.Client_typestate.L1
  module L2 = Polymarket_clob.Client_typestate.L2

  val upgrade_to_l1 : unauthed -> private_key:string -> l1

  val upgrade_to_l2 :
    l1 -> credentials:Polymarket_clob.Auth_types.credentials -> l2

  val l2_to_l1 : l2 -> l1
  val l2_to_unauthed : l2 -> unauthed
  val l1_to_unauthed : l1 -> unauthed
end

module Http = Polymarket_http.Client
(** HTTP client utilities for making API requests. *)

module Rate_limiter = Polymarket_rate_limiter.Rate_limiter
(** Route-based rate limiting middleware for HTTP clients. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. *)

module Address = Polymarket_common.Primitives.Address
module Hash64 = Polymarket_common.Primitives.Hash64
module Hash = Polymarket_common.Primitives.Hash
module Nonneg_int = Polymarket_common.Primitives.Nonneg_int
module Pos_int = Polymarket_common.Primitives.Pos_int
module Nonneg_float = Polymarket_common.Primitives.Nonneg_float
module Limit = Polymarket_common.Primitives.Limit
module Offset = Polymarket_common.Primitives.Offset
module Timestamp = Polymarket_common.Primitives.Timestamp
module Bounded_string = Polymarket_common.Primitives.Bounded_string
module Holders_limit = Polymarket_common.Primitives.Holders_limit
module Min_balance = Polymarket_common.Primitives.Min_balance

module Closed_positions_limit =
  Polymarket_common.Primitives.Closed_positions_limit

module Extended_offset = Polymarket_common.Primitives.Extended_offset
module Leaderboard_limit = Polymarket_common.Primitives.Leaderboard_limit
module Leaderboard_offset = Polymarket_common.Primitives.Leaderboard_offset
module Builder_limit = Polymarket_common.Primitives.Builder_limit
