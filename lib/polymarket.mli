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
  module Auth = Polymarket_common.Auth
  module Crypto = Polymarket_common.Crypto

  type unauthed = Polymarket_clob.Client.unauthed
  type l1 = Polymarket_clob.Client.l1
  type l2 = Polymarket_clob.Client.l2

  module Unauthed = Polymarket_clob.Client.Unauthed
  module L1 = Polymarket_clob.Client.L1
  module L2 = Polymarket_clob.Client.L2

  val upgrade_to_l1 : unauthed -> private_key:string -> l1
  val upgrade_to_l2 : l1 -> credentials:Polymarket_common.Auth.credentials -> l2
  val l2_to_l1 : l2 -> l1
  val l2_to_unauthed : l2 -> unauthed
  val l1_to_unauthed : l1 -> unauthed
end

module Rfq : sig
  (** RFQ API client for Request for Quote trading.

      All RFQ endpoints require L2 authentication. *)

  module Types = Polymarket_rfq.Types
  module Auth = Polymarket_common.Auth
  module Crypto = Polymarket_common.Crypto

  val default_base_url : string
  (** Default base URL for the RFQ API: https://clob.polymarket.com *)

  type t
  (** RFQ client with L2 authentication. *)

  val create :
    ?base_url:string ->
    sw:Eio.Switch.t ->
    net:_ Eio.Net.t ->
    rate_limiter:Polymarket_rate_limiter.Rate_limiter.t ->
    private_key:Crypto.private_key ->
    credentials:Auth.credentials ->
    unit ->
    t
  (** Create a new RFQ client. *)

  val address : t -> string
  (** Get the Ethereum address derived from the private key. *)

  val credentials : t -> Auth.credentials
  (** Get the API credentials. *)

  (** {2 Request Endpoints} *)

  val create_request :
    t ->
    body:Types.create_request_body ->
    unit ->
    (Types.create_request_response, Types.error) result

  val cancel_request :
    t -> request_id:Types.request_id -> unit -> (unit, Types.error) result

  val get_requests :
    t ->
    ?offset:string ->
    ?limit:int ->
    ?state:Types.State_filter.t ->
    ?request_ids:string list ->
    ?markets:string list ->
    ?size_min:float ->
    ?size_max:float ->
    ?size_usdc_min:float ->
    ?size_usdc_max:float ->
    ?price_min:float ->
    ?price_max:float ->
    ?sort_by:Types.Sort_by.t ->
    ?sort_dir:Types.Sort_dir.t ->
    unit ->
    (Types.get_requests_response, Types.error) result

  (** {2 Quote Endpoints} *)

  val create_quote :
    t ->
    body:Types.create_quote_body ->
    unit ->
    (Types.create_quote_response, Types.error) result

  val cancel_quote :
    t -> quote_id:Types.quote_id -> unit -> (unit, Types.error) result

  val get_quotes :
    t ->
    ?offset:string ->
    ?limit:int ->
    ?state:Types.State_filter.t ->
    ?quote_ids:string list ->
    ?request_ids:string list ->
    ?markets:string list ->
    ?size_min:float ->
    ?size_max:float ->
    ?size_usdc_min:float ->
    ?size_usdc_max:float ->
    ?price_min:float ->
    ?price_max:float ->
    ?sort_by:Types.Sort_by.t ->
    ?sort_dir:Types.Sort_dir.t ->
    unit ->
    (Types.get_quotes_response, Types.error) result

  (** {2 Execution Endpoints} *)

  val accept_quote :
    t -> body:Types.accept_quote_body -> unit -> (unit, Types.error) result

  val approve_order :
    t ->
    body:Types.approve_order_body ->
    unit ->
    (Types.approve_order_response, Types.error) result
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
          Clob.Auth.{ api_key = "..."; secret = "..."; passphrase = "..." }
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

  module Types = Polymarket_wss_api.Types
  module Market = Polymarket_wss_api.Client.Market
  module User = Polymarket_wss_api.Client.User
end

module Rtds : sig
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
            ~symbols:[ "btcusdt"; "ethusdt" ]
            ()
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

  module Types = Polymarket_rtds_api.Types

  (** {1 Unified Client} *)

  type t
  (** Unified RTDS client for multiple subscription types *)

  val connect :
    sw:Eio.Switch.t ->
    net:_ Eio.Net.t ->
    clock:float Eio.Time.clock_ty Eio.Resource.t ->
    unit ->
    t
  (** Connect to the RTDS WebSocket *)

  val stream : t -> Types.message Eio.Stream.t
  (** Get the message stream *)

  val subscribe : t -> subscriptions:Types.subscription list -> unit
  (** Subscribe to topics *)

  val unsubscribe : t -> subscriptions:Types.subscription list -> unit
  (** Unsubscribe from topics *)

  val close : t -> unit
  (** Close the connection *)

  (** {1 Specialized Clients} *)

  module Crypto_prices : sig
    (** Specialized client for crypto price streams *)

    type t

    val connect_binance :
      sw:Eio.Switch.t ->
      net:_ Eio.Net.t ->
      clock:float Eio.Time.clock_ty Eio.Resource.t ->
      ?symbols:string list ->
      unit ->
      t
    (** Connect to Binance crypto prices *)

    val connect_chainlink :
      sw:Eio.Switch.t ->
      net:_ Eio.Net.t ->
      clock:float Eio.Time.clock_ty Eio.Resource.t ->
      ?symbol:string ->
      unit ->
      t
    (** Connect to Chainlink oracle prices *)

    val stream : t -> Types.crypto_message Eio.Stream.t
    (** Get the crypto price message stream *)

    val close : t -> unit
    (** Close the connection *)
  end

  module Comments : sig
    (** Specialized client for comment streams *)

    type t

    val connect :
      sw:Eio.Switch.t ->
      net:_ Eio.Net.t ->
      clock:float Eio.Time.clock_ty Eio.Resource.t ->
      ?gamma_auth:Types.gamma_auth ->
      unit ->
      t
    (** Connect to comments stream *)

    val stream : t -> Types.comment Eio.Stream.t
    (** Get the comment message stream *)

    val close : t -> unit
    (** Close the connection *)
  end
end

module Http = Polymarket_http.Client
(** HTTP client utilities for making API requests. *)

module Rate_limiter = Polymarket_rate_limiter.Rate_limiter
(** Route-based rate limiting middleware for HTTP clients. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. *)

module Side = Polymarket_common.Primitives.Side
module Address = Polymarket_common.Primitives.Address
module Hash64 = Polymarket_common.Primitives.Hash64
module Hash = Polymarket_common.Primitives.Hash
module Timestamp = Polymarket_common.Primitives.Timestamp

(** {1 Authentication and Crypto}

    Shared authentication types and cryptographic utilities. *)

module Auth = Polymarket_common.Auth
(** Authentication types and header builders. *)

module Crypto = Polymarket_common.Crypto
(** Cryptographic utilities for signing and address derivation. *)
