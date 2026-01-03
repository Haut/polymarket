(* Polymarket OCaml client library *)

(** {1 Flattened API Modules}

    These modules combine client functions with their response types for
    ergonomic usage. Instead of [Polymarket_gamma.Client.get_events] and
    [Polymarket_gamma.Responses.event], use [Polymarket.Gamma.get_events] and
    [Polymarket.Gamma.event]. *)

module Gamma = Polymarket_gamma.Client
(** Gamma API client for markets, events, series, and search. *)

module Data = Polymarket_data.Client
(** Data API client for positions, trades, activity, and leaderboards. *)

module Clob = struct
  (** CLOB API client for order books, pricing, and trading. *)

  let default_base_url = Polymarket_clob.Client.default_base_url

  module Types = Polymarket_clob.Types

  type unauthed = Polymarket_clob.Client.unauthed
  type l1 = Polymarket_clob.Client.l1
  type l2 = Polymarket_clob.Client.l2

  module Unauthed = Polymarket_clob.Client.Unauthed
  module L1 = Polymarket_clob.Client.L1
  module L2 = Polymarket_clob.Client.L2

  type private_key = Polymarket_clob.Client.private_key
  type credentials = Polymarket_clob.Client.credentials
  type error = Polymarket_clob.Client.error

  let error_to_string = Polymarket_clob.Client.error_to_string
  let upgrade_to_l1 = Polymarket_clob.Client.upgrade_to_l1
  let upgrade_to_l2 = Polymarket_clob.Client.upgrade_to_l2
  let l2_to_l1 = Polymarket_clob.Client.l2_to_l1
  let l2_to_unauthed = Polymarket_clob.Client.l2_to_unauthed
  let l1_to_unauthed = Polymarket_clob.Client.l1_to_unauthed
end

module Rfq = struct
  (** RFQ API client for Request for Quote trading.

      All RFQ endpoints require L2 authentication. *)

  module Types = Polymarket_rfq.Types
  include Polymarket_rfq.Client
end

module Wss = struct
  (** WebSocket client for real-time market and user data.

      Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility. *)

  module Types = Polymarket_wss.Types
  module Market = Polymarket_wss.Client.Market
  module User = Polymarket_wss.Client.User
end

module Rtds = struct
  (** Real-Time Data Socket (RTDS) client for streaming data.

      Provides real-time updates for:
      - Crypto prices (Binance and Chainlink sources)
      - Comments and reactions

      Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility. *)

  module Types = Polymarket_rtds.Types
  include Polymarket_rtds.Client
end

module Http = Polymarket_http.Client
(** HTTP client utilities for making API requests. *)

module Rate_limiter = Polymarket_rate_limiter.Rate_limiter
(** Route-based rate limiting middleware. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. These are
    re-exported at top level for convenience. *)

module Side = Polymarket_common.Primitives.Side
module Sort_dir = Polymarket_common.Primitives.Sort_dir
module Address = Polymarket_common.Primitives.Address
module Hash64 = Polymarket_common.Primitives.Hash64
module Hash = Polymarket_common.Primitives.Hash
module Token_id = Polymarket_common.Primitives.Token_id
module Signature = Polymarket_common.Primitives.Signature
module Request_id = Polymarket_common.Primitives.Request_id
module Quote_id = Polymarket_common.Primitives.Quote_id
module Trade_id = Polymarket_common.Primitives.Trade_id
module Timestamp = Polymarket_common.Primitives.Timestamp
module Nonneg_int = Polymarket_common.Primitives.Nonneg_int

(** {1 Authentication and Crypto}

    Shared authentication types and cryptographic utilities. *)

module Auth = Polymarket_common.Auth
(** Authentication types and header builders. *)

module Crypto = Polymarket_common.Crypto
(** Cryptographic utilities for signing and address derivation. *)
