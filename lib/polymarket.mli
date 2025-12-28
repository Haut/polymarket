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

      {2 Module-based Enums}

      Query parameter enums use a module-based pattern for type safety:

      {[
        (* Filter events by status *)
        let events = Gamma.get_events client ~status:Gamma.Status.Active () in

        (* Get comments for an event *)
        let comments =
          Gamma.get_comments client
            ~parent_entity_type:Gamma.Parent_entity_type.Event
            ~parent_entity_id:123 ()
        in
      ]} *)

  include module type of Polymarket_gamma.Client
  include module type of Polymarket_gamma.Types
end

module Data : sig
  (** Data API client for positions, trades, activity, and leaderboards.

      {2 Module-based Enums}

      Query parameter enums use a module-based pattern for type safety:

      {[
        (* Get positions sorted by cash PnL *)
        let positions =
          Data.get_positions client ~user
            ~sort_by:Data.Position_sort_by.Cashpnl
            ~sort_direction:Data.Sort_direction.Desc ()
        in

        (* Get trader leaderboard *)
        let leaders =
          Data.get_trader_leaderboard client
            ~category:Data.Leaderboard_category.Politics
            ~time_period:Data.Time_period.Week
            ~order_by:Data.Leaderboard_order_by.Pnl ()
        in
      ]} *)

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

  val default_base_url : string

  module Types = Polymarket_clob.Types
  module Auth = Polymarket_clob.Auth
  module Auth_types = Polymarket_clob.Auth_types
  module Crypto = Polymarket_clob.Crypto

  type unauthed = Polymarket_clob.Client.unauthed
  type l1 = Polymarket_clob.Client.l1
  type l2 = Polymarket_clob.Client.l2

  module Unauthed = Polymarket_clob.Client.Unauthed
  module L1 = Polymarket_clob.Client.L1
  module L2 = Polymarket_clob.Client.L2

  val upgrade_to_l1 : unauthed -> private_key:string -> l1

  val upgrade_to_l2 :
    l1 -> credentials:Polymarket_clob.Auth_types.credentials -> l2

  val l2_to_l1 : l2 -> l1
  val l2_to_unauthed : l2 -> unauthed
  val l1_to_unauthed : l1 -> unauthed
end

module Wss : sig
  (** WebSocket client for real-time market and user data.

      Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility.

      {2 Market Channel (Public)}

      Subscribe to orderbook updates for specific asset IDs:

      {[
        Eio_main.run @@ fun env ->
        Eio.Switch.run @@ fun sw ->
        let net = Eio.Stdenv.net env in
        let clock = Eio.Stdenv.clock env in
        let asset_ids = [ "token_id_1"; "token_id_2" ] in
        let client = Wss.Market.connect ~sw ~net ~clock ~asset_ids () in
        let stream = Wss.Market.stream client in
        match Eio.Stream.take stream with
        | Wss.Types.Market (Book msg) ->
            Printf.printf "Book update for %s\n" msg.asset_id
        | _ -> ()
      ]}

      {2 User Channel (Authenticated)}

      Subscribe to your trades and orders with API credentials:

      {[
        let credentials =
          Clob.Auth_types.
            { api_key = "..."; secret = "..."; passphrase = "..." }
        in
        let markets = [ "condition_id_1" ] in
        let client =
          Wss.User.connect ~sw ~net ~clock ~credentials ~markets ()
        in
        let stream = Wss.User.stream client in
        match Eio.Stream.take stream with
        | Wss.Types.User (Trade msg) ->
            Printf.printf "Trade: %s at %s\n" msg.id msg.price
        | _ -> ()
      ]} *)

  module Types = Polymarket_wss.Types
  module Market = Polymarket_wss.Client.Market
  module User = Polymarket_wss.Client.User
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
