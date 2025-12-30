(** Core types for rate limiting.

    This module defines the configuration types used throughout the rate
    limiter. *)

(** {1 Route Patterns}

    Route patterns match HTTP requests by host, method, and path prefix. All
    fields are optional - unspecified fields match any value. *)

type route_pattern = {
  host : string option;  (** Hostname to match (e.g., "api.example.com") *)
  method_ : string option;  (** HTTP method to match (e.g., "GET", "POST") *)
  path_prefix : string option;
      (** Path prefix to match (e.g., "/api/v1"). Uses segment boundaries. *)
}
[@@deriving show, eq]

val any_route : route_pattern
(** Pattern matching all routes *)

(** {1 Limit Configuration}

    GCRA-based rate limit configuration using requests per time window. *)

type limit_config = {
  requests : int;  (** Number of requests allowed in the window *)
  window_seconds : float;  (** Time window in seconds *)
}
[@@deriving show, eq]

val limit : requests:int -> window_seconds:float -> limit_config
(** Create a limit configuration. Example:
    [limit ~requests:100 ~window_seconds:10.0] for 100 req/10s *)

(** {1 Behavior}

    What to do when a request exceeds the rate limit. *)

type behavior =
  | Delay  (** Sleep until the request can proceed *)
  | Error  (** Return an error immediately *)
[@@deriving show, eq]

(** {1 Route Configuration}

    Complete configuration for a rate-limited route. *)

type route_config = {
  pattern : route_pattern;  (** Which requests this route matches *)
  limits : limit_config list;  (** Rate limits to apply (all must pass) *)
  behavior : behavior;  (** What to do when rate limited *)
}
[@@deriving show, eq]

(** {1 Errors} *)

type error =
  | Rate_limited of {
      retry_after : float;  (** Seconds until request can proceed *)
      route_key : string;  (** The route that was rate limited *)
    }
[@@deriving show, eq]
