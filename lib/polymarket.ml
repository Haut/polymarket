(* Polymarket OCaml client library *)

(** {1 Flattened API Modules}

    These modules combine client functions with their response types for
    ergonomic usage. Instead of [Gamma_client.get_events] and
    [Polymarket_gamma.Responses.event], use [Polymarket.Gamma.get_events] and
    [Polymarket.Gamma.event]. *)

module Gamma = Gamma_client
(** Gamma API client for markets, events, series, and search. *)

module Data = Data_client
(** Data API client for positions, trades, activity, and leaderboards. *)

module Clob = struct
  (** CLOB API client for order books, pricing, and trading. *)

  let default_base_url = Clob_client.default_base_url

  module Types = Clob_types

  type unauthed = Clob_client.unauthed
  type l1 = Clob_client.l1
  type l2 = Clob_client.l2

  module Unauthed = Clob_client.Unauthed
  module L1 = Clob_client.L1
  module L2 = Clob_client.L2

  type private_key = Clob_client.private_key
  type credentials = Clob_client.credentials
  type error = Clob_client.error

  let private_key_of_string = Clob_client.private_key_of_string
  let error_to_string = Clob_client.error_to_string
  let upgrade_to_l1 = Clob_client.upgrade_to_l1
  let upgrade_to_l2 = Clob_client.upgrade_to_l2
  let l2_to_l1 = Clob_client.l2_to_l1
  let l2_to_unauthed = Clob_client.l2_to_unauthed
  let l1_to_unauthed = Clob_client.l1_to_unauthed
end

module Rfq = struct
  (** RFQ API client for Request for Quote trading.

      All RFQ endpoints require L2 authentication. *)

  module Types = Rfq_types
  include Rfq_client
end

module Wss = struct
  (** WebSocket client for real-time market and user data.

      Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility. *)

  module Types = Wss_types
  module Market = Wss_client.Market
  module User = Wss_client.User
end

module Rtds = struct
  (** Real-Time Data Socket (RTDS) client for streaming data.

      Provides real-time updates for:
      - Crypto prices (Binance and Chainlink sources)
      - Comments and reactions

      Uses pure-OCaml TLS (tls-eio) for cross-platform compatibility. *)

  module Types = Rtds_types
  include Rtds_client
end

module Rate_limiter = Rate_limiter
(** Route-based rate limiting middleware. *)

module Rate_limit_presets = Rate_limit_presets
(** Pre-configured rate limits for Polymarket APIs. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. These are
    re-exported at top level for convenience. *)

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
module Nonneg_int = Primitives.Nonneg_int
