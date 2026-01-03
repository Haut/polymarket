(** Route matching for rate limiting.

    This module provides pattern matching for HTTP requests against route
    configurations. Pattern matching uses segment boundaries for paths, not
    simple prefix matching. *)

val matches_pattern :
  method_:string -> uri:Uri.t -> Rl_types.route_pattern -> bool
(** Check if a request matches a route pattern.
    @param method_ HTTP method (e.g., "GET", "POST")
    @param uri Request URI *)

val find_matching_routes :
  method_:string ->
  uri:Uri.t ->
  Rl_types.route_config list ->
  Rl_types.route_config list
(** Find all route configs that match the request. Routes are returned in the
    order they appear in the config list. All matching routes apply (not just
    first match). *)

val make_route_key :
  method_:string -> uri:Uri.t -> Rl_types.route_pattern -> Rl_state.route_key
(** Generate a unique key for state lookup. The key format is:
    "host:method:path_prefix" *)

val path_matches_prefix : path:string -> prefix:string -> bool
(** Check if a path matches a prefix using segment boundaries. Examples:
    - ["/orders"] matches ["/orders"], ["/orders/"], ["/orders/123"]
    - ["/orders"] does NOT match ["/orders-test"], ["/ordersX"]
    - ["/api/v1"] matches ["/api/v1/users"]
    - ["/api/v1"] does NOT match ["/api/v10"] *)
