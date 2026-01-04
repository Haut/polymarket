(* Polymarket OCaml client library *)

(** {1 Flattened API Modules}

    These modules combine client functions with their response types for
    ergonomic usage. Instead of [Gamma_client.get_events] and
    [Polymarket_gamma.Responses.event], use [Polymarket.Gamma.get_events] and
    [Polymarket.Gamma.event]. *)

(** Gamma API client for markets, events, series, and search. *)
module Gamma = struct
  include Gamma.Client
  module Types = Gamma.Types
end

(** Data API client for positions, trades, activity, and leaderboards. *)
module Data = struct
  include Data.Client
  module Types = Data.Types
end

(** CLOB API client for order books, pricing, and trading. *)
module Clob = struct
  include Clob.Client
  module Types = Clob.Types
  module Order_builder = Clob.Order_builder
end

(** RFQ API client for Request for Quote trading. *)
module Rfq = struct
  include Rfq.Client
  module Types = Rfq.Types
  module Order_builder = Rfq.Order_builder
end

(** WebSocket client for real-time market and user data. *)
module Wss = struct
  include Wss.Client
  module Types = Wss.Types
end

(** Real-Time Data Socket (RTDS) client for streaming data. *)
module Rtds = struct
  include Rtds.Client
  module Types = Rtds.Types
end

module Rate_limiter = Rate_limiter
(** Route-based rate limiting middleware. *)

module Rate_limit_presets = Common.Rate_limit_presets
(** Pre-configured rate limits for Polymarket APIs. *)

(** {1 Primitive Types}

    Validated types for addresses, hashes, and numeric constraints. *)

module Primitives = Common.Primitives

(** {1 Error Types} *)

module Error = struct
  type http = Polymarket_http.Client.http_error = {
    status : int;
    body : string;
    message : string;
  }

  type parse = Polymarket_http.Client.parse_error = {
    context : string;
    message : string;
  }

  type network = Polymarket_http.Client.network_error = { message : string }

  type t = Polymarket_http.Client.error =
    | Http_error of http
    | Parse_error of parse
    | Network_error of network

  let to_string = Polymarket_http.Client.error_to_string
  let pp = Polymarket_http.Client.pp_error
end
