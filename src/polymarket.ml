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

module Clob = Clob_client
(** CLOB API client for order books, pricing, and trading. *)

module Rfq = Rfq_client
(** RFQ API client for Request for Quote trading. *)

module Wss = Wss_client
(** WebSocket client for real-time market and user data. *)

module Rtds = Rtds_client
(** Real-Time Data Socket (RTDS) client for streaming data. *)

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

(** {1 Error Types} *)

type http_error = Primitives.http_error = {
  status : int;
  body : string;
  message : string;
}

type parse_error = Primitives.parse_error = {
  context : string;
  message : string;
}

type network_error = Primitives.network_error = { message : string }

type api_error = Primitives.api_error =
  | Http_error of http_error
  | Parse_error of parse_error
  | Network_error of network_error

let api_error_to_string = Primitives.api_error_to_string
