(* Polymarket OCaml client library *)

(** {1 Flattened API Modules}

    These modules combine client functions with their response types for
    ergonomic usage. Instead of [Polymarket_gamma.Client.get_events] and
    [Polymarket_gamma.Responses.event], use [Polymarket.Gamma.get_events] and
    [Polymarket.Gamma.event]. *)

module Gamma = struct
  (** Gamma API client for markets, events, series, and search.

      Combines client functions and types. *)

  include Polymarket_gamma.Endpoints
  include Polymarket_gamma.Types

  let default_base_url = "https://gamma-api.polymarket.com"

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
    Polymarket_http.Client.create ~base_url ~sw ~net ~rate_limiter ()
end

module Data = struct
  (** Data API client for positions, trades, activity, and leaderboards.

      Combines client functions and response types. *)

  include Polymarket_data.Endpoints
  include Polymarket_data.Types

  let default_base_url = "https://data-api.polymarket.com"

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
    Polymarket_http.Client.create ~base_url ~sw ~net ~rate_limiter ()
end

module Clob = struct
  (** CLOB API client for order books, pricing, and trading. *)

  let default_base_url = Polymarket_clob.Client.default_base_url

  module Types = Polymarket_clob.Types
  module Auth = Polymarket_common.Auth
  module Crypto = Polymarket_common.Crypto

  type unauthed = Polymarket_clob.Client.unauthed
  type l1 = Polymarket_clob.Client.l1
  type l2 = Polymarket_clob.Client.l2

  module Unauthed = Polymarket_clob.Client.Unauthed
  module L1 = Polymarket_clob.Client.L1
  module L2 = Polymarket_clob.Client.L2

  let upgrade_to_l1 = Polymarket_clob.Client.upgrade_to_l1
  let upgrade_to_l2 = Polymarket_clob.Client.upgrade_to_l2
  let l2_to_l1 = Polymarket_clob.Client.l2_to_l1
  let l2_to_unauthed = Polymarket_clob.Client.l2_to_unauthed
  let l1_to_unauthed = Polymarket_clob.Client.l1_to_unauthed
end

module Wss = struct
  (** WebSocket client for real-time market and user data.

      Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility. *)

  module Types = Polymarket_wss_api.Types
  module Market = Polymarket_wss_api.Client.Market
  module User = Polymarket_wss_api.Client.User
end

module Rtds = struct
  (** Real-Time Data Socket (RTDS) client for streaming data.

      Provides real-time updates for:
      - Crypto prices (Binance and Chainlink sources)
      - Comments and reactions

      Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility. *)

  module Types = Polymarket_rtds_api.Types
  include Polymarket_rtds_api.Client
end

module Http = Polymarket_http.Client
(** HTTP client utilities for making API requests. *)

module Rate_limiter = Polymarket_rate_limiter.Rate_limiter
(** Route-based rate limiting middleware. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. These are
    re-exported at top level for convenience. *)

module Side = Polymarket_common.Primitives.Side
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

(** {1 Authentication and Crypto}

    Shared authentication types and cryptographic utilities. *)

module Auth = Polymarket_common.Auth
(** Authentication types and header builders. *)

module Crypto = Polymarket_common.Crypto
(** Cryptographic utilities for signing and address derivation. *)
