(** Gamma API client for markets, events, series, and search.

    Combines client functions and types. *)

include Endpoints
include Types

let default_base_url = "https://gamma-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
  Polymarket_http.Client.create ~base_url ~sw ~net ~rate_limiter ()
