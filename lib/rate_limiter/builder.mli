(** Fluent builder for rate limit configurations.

    This module provides a chainable API for building route configurations,
    similar to the Rust route-ratelimit crate.

    Example:
    {[
      route () |> host "api.example.com" |> method_ "POST" |> path "/orders"
      |> limit ~requests:100 ~window_seconds:10.0
      |> limit ~requests:1000 ~window_seconds:600.0
      |> on_limit Delay |> build
    ]} *)

type t
(** Builder state *)

val route : unit -> t
(** Start building a route configuration *)

(** {1 Pattern Matching} *)

val host : string -> t -> t
(** Match requests to a specific host *)

val method_ : string -> t -> t
(** Match requests with a specific HTTP method (case-insensitive) *)

val path : string -> t -> t
(** Match requests with a path prefix (uses segment boundaries) *)

(** {1 Rate Limits}

    Multiple limits can be applied to the same route. All limits must pass for a
    request to proceed. This enables burst + sustained limit patterns. *)

val limit : requests:int -> window_seconds:float -> t -> t
(** Add a rate limit. Can be called multiple times to add multiple limits.
    Example: [limit ~requests:100 ~window_seconds:10.0] for 100 req/10s *)

(** {1 Behavior} *)

val on_limit : Types.behavior -> t -> t
(** Set what happens when the rate limit is exceeded.
    - [Delay]: Sleep until the request can proceed (default)
    - [Error]: Return an error immediately *)

(** {1 Building} *)

val build : t -> Types.route_config
(** Build the final route configuration. Uses [Delay] behavior if not specified.
    At least one limit must be configured. *)

(** {1 Convenience Constructors} *)

val simple :
  ?host:string ->
  ?method_:string ->
  ?path:string ->
  requests:int ->
  window_seconds:float ->
  ?behavior:Types.behavior ->
  unit ->
  Types.route_config
(** Create a simple route configuration with a single limit. Example:
    {[
      simple ~host:"api.example.com" ~requests:100 ~window_seconds:10.0 ()
    ]} *)

val global :
  requests:int ->
  window_seconds:float ->
  behavior:Types.behavior ->
  Types.route_config
(** Create a global rate limit that matches all routes *)

val per_host :
  host:string ->
  requests:int ->
  window_seconds:float ->
  behavior:Types.behavior ->
  Types.route_config
(** Create a rate limit for all routes to a specific host *)

val per_endpoint :
  host:string ->
  method_:string ->
  path:string ->
  requests:int ->
  window_seconds:float ->
  behavior:Types.behavior ->
  Types.route_config
(** Create a rate limit for a specific endpoint *)

(** {1 Host-Scoped Builder}

    For organizing rate limits by host, similar to the Rust library's
    [.host("...", |h| ...)] pattern. *)

type host_builder
(** Builder for routes scoped to a host *)

val for_host : string -> host_builder
(** Start building routes for a specific host *)

val add_route : t -> host_builder -> host_builder
(** Add a route to the host builder. The route inherits the host. *)

val build_host : host_builder -> Types.route_config list
(** Build all routes for this host *)
