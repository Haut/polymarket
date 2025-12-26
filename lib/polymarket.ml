(* Polymarket OCaml client library *)

(** {1 Flattened API Modules}

    These modules combine client functions with their response types for
    ergonomic usage. Instead of [Polymarket_gamma.Client.get_events] and
    [Polymarket_gamma.Responses.event], use [Polymarket.Gamma.get_events] and
    [Polymarket.Gamma.event]. *)

module Gamma = struct
  (** Gamma API client for markets, events, series, and search.

      Combines client functions, response types, and query enums. *)

  include Polymarket_gamma.Client
  include Polymarket_gamma.Responses
  include Polymarket_gamma.Query
end

module Data = struct
  (** Data API client for positions, trades, activity, and leaderboards.

      Combines client functions and response types. *)

  include Polymarket_data.Client
  include Polymarket_data.Types
end

module Clob = struct
  (** CLOB API client for order books, pricing, and trading. *)

  include Polymarket_clob.Client
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

  let upgrade_to_l1 = Polymarket_clob.Client_typestate.upgrade_to_l1
  let upgrade_to_l2 = Polymarket_clob.Client_typestate.upgrade_to_l2
  let l2_to_l1 = Polymarket_clob.Client_typestate.l2_to_l1
  let l2_to_unauthed = Polymarket_clob.Client_typestate.l2_to_unauthed
  let l1_to_unauthed = Polymarket_clob.Client_typestate.l1_to_unauthed
end

module Http = Polymarket_http.Client
(** HTTP client utilities for making API requests. *)

module Rate_limiter = Polymarket_rate_limiter.Rate_limiter
(** Route-based rate limiting middleware. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. These are
    re-exported at top level for convenience. *)

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
