(** Data API client for positions, trades, activity, and leaderboards.

    Combines client functions and response types. *)

include Endpoints
include Types

let default_base_url = "https://data-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
  Polymarket_http.Client.create ~base_url ~sw ~net ~rate_limiter ()
