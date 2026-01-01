(** Gamma API client for markets, events, series, and search.

    Combines client functions and types for ergonomic usage. *)

include module type of Endpoints
include module type of Types

val default_base_url : string
(** Default base URL: https://gamma-api.polymarket.com *)

val create :
  ?base_url:string ->
  sw:Eio.Switch.t ->
  net:'a Eio.Net.t ->
  rate_limiter:Polymarket_rate_limiter.Rate_limiter.t ->
  unit ->
  t
(** Create a Gamma API client.
    @param base_url Override the default base URL
    @param sw Eio switch for resource management
    @param net Eio network capability
    @param rate_limiter Rate limiter for API requests *)
