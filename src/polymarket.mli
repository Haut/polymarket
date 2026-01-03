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
      let net = Eio.Stdenv.net env in
      let clock = Eio.Stdenv.clock env in
      let rate_limiter =
        Polymarket.Rate_limiter.create ~clock
          ~config:Polymarket.Rate_limit_presets.gamma ()
      in
      let client = Polymarket.Gamma.create ~sw ~net ~rate_limiter () in
      match Polymarket.Gamma.get_events client () with
      | Ok events -> List.iter (fun e -> print_endline e.title) events
      | Error err -> print_endline (Polymarket.api_error_to_string err)
    ]}

    {2 Rate Limiting}

    Create a rate limiter with Polymarket API presets:

    {[
      let clock = Eio.Stdenv.clock env in
      let rate_limiter =
        Polymarket.Rate_limiter.create ~clock
          ~config:Polymarket.Rate_limit_presets.gamma ()
      in
      let client = Polymarket.Gamma.create ~sw ~net ~rate_limiter () in
      (* Requests are now automatically rate limited *)
    ]}

    {2 Validated Primitive Types}

    The library uses validated types for addresses, hashes, and numeric
    constraints. These are available at the top level for convenience:
    - {!Address}: Ethereum addresses (0x-prefixed, 40 hex chars)
    - {!Hash64}: 64-character hex hashes
    - {!Hash}: Variable-length hex strings

    {2 Sub-libraries}

    For finer-grained control, you can depend on sub-libraries directly:
    - [polymarket.common]: Shared primitives and logging
    - [polymarket.http]: HTTP client utilities
    - [polymarket.rate_limiter]: Rate limiting middleware
    - [polymarket.gamma]: Gamma API client
    - [polymarket.data]: Data API client
    - [polymarket.clob]: CLOB API client *)

(** {1 API Modules} *)

module Gamma = Gamma_client
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

module Data = Data_client
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

module Clob = Clob_client
(** CLOB API client for order books, pricing, and trading.

    {2 Typestate Authentication}

    The CLOB client uses a typestate pattern to enforce authentication
    requirements at compile time:

    - {!Clob.Unauthed}: Public endpoints only (order book, pricing, timeseries)
    - {!Clob.L1}: Wallet authentication (create/derive API keys) + public
      endpoints
    - {!Clob.L2}: API key authentication (orders, trades) + L1 + public
      endpoints

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

module Rfq = Rfq_client
(** RFQ API client for Request for Quote trading.

    All RFQ endpoints require L2 authentication. *)

module Wss = Wss_client
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
        Clob.Auth.{ api_key = "..."; secret = "..."; passphrase = "..." }
      in
      let markets = [ "condition_id_1" ] in
      let client = Wss.User.connect ~sw ~net ~clock ~credentials ~markets () in
      let stream = Wss.User.stream client in
      match Eio.Stream.take stream with
      | Wss.Types.User (Trade msg) ->
          Printf.printf "Trade: %s at %s\n" msg.id msg.price
      | _ -> ()
    ]} *)

module Rtds = Rtds_client
(** Real-Time Data Socket (RTDS) client for streaming data.

    Provides real-time updates for:
    - Crypto prices (Binance and Chainlink sources)
    - Comments and reactions

    Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility.

    {2 Crypto Prices (Binance)}

    Subscribe to real-time crypto prices from Binance:

    {[
      Eio_main.run @@ fun env ->
      Eio.Switch.run @@ fun sw ->
      let net = Eio.Stdenv.net env in
      let clock = Eio.Stdenv.clock env in
      let client =
        Rtds.Crypto_prices.connect_binance ~sw ~net ~clock
          ~symbols:[ "btcusdt"; "ethusdt" ] ()
      in
      let stream = Rtds.Crypto_prices.stream client in
      match Eio.Stream.take stream with
      | `Binance msg -> Printf.printf "BTC: %.2f\n" msg.payload.value
      | _ -> ()
    ]}

    {2 Crypto Prices (Chainlink)}

    Subscribe to oracle prices from Chainlink:

    {[
      let client =
        Rtds.Crypto_prices.connect_chainlink ~sw ~net ~clock ~symbol:"eth/usd"
          ()
      in
      let stream = Rtds.Crypto_prices.stream client in
      match Eio.Stream.take stream with
      | `Chainlink msg -> Printf.printf "ETH: %.2f\n" msg.payload.value
      | _ -> ()
    ]}

    {2 Comments}

    Subscribe to real-time comment updates:

    {[
      let client = Rtds.Comments.connect ~sw ~net ~clock () in
      let stream = Rtds.Comments.stream client in
      match Eio.Stream.take stream with
      | `Comment_created msg ->
          Printf.printf "New comment: %s\n" msg.payload.body
      | _ -> ()
    ]}

    {2 Unified Client}

    Subscribe to multiple topics with a single connection:

    {[
      let client = Rtds.connect ~sw ~net ~clock () in
      let subscriptions =
        [
          Rtds.Types.crypto_prices_subscription
            ~filters:(Rtds.Types.binance_symbol_filter [ "btcusdt" ])
            ();
          Rtds.Types.comments_subscription ();
        ]
      in
      Rtds.subscribe client ~subscriptions;
      let stream = Rtds.stream client in
      match Eio.Stream.take stream with
      | `Crypto (`Binance msg) ->
          Printf.printf "Price: %.2f\n" msg.payload.value
      | `Comment (`Comment_created msg) ->
          Printf.printf "Comment: %s\n" msg.payload.body
      | _ -> ()
    ]} *)

module Rate_limiter = Rate_limiter
(** Route-based rate limiting middleware for HTTP clients. *)

module Rate_limit_presets = Rate_limit_presets
(** Pre-configured rate limits for Polymarket APIs. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. *)

module Side = Primitives.Side
module Sort_dir = Primitives.Sort_dir
module Address = Primitives.Address
module Hash64 = Primitives.Hash64
module Hash = Primitives.Hash
module Token_id = Primitives.Token_id
module Signature = Primitives.Signature
module Request_id = Primitives.Request_id
module Quote_id = Primitives.Quote_id
module Trade_id = Primitives.Trade_id
module Timestamp = Primitives.Timestamp

(** {1 Error Types} *)

type http_error = Primitives.http_error = {
  status : int;
  body : string;
  message : string;
}
(** HTTP error with status code, raw body, and extracted message. *)

type parse_error = Primitives.parse_error = {
  context : string;
  message : string;
}
(** Parse error with context and message. *)

type network_error = Primitives.network_error = { message : string }
(** Network-level error (connection failed, timeout, etc.). *)

type api_error = Primitives.api_error =
  | Http_error of http_error
  | Parse_error of parse_error
  | Network_error of network_error
      (** Structured error type for all API errors. *)

val api_error_to_string : api_error -> string
(** Convert error to human-readable string. *)
