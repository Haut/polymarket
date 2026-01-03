(** State management for rate limiting.

    This module manages GCRA states for all routes, providing thread-safe
    access. Call [cleanup] explicitly to remove stale entries. *)

type t
(** State manager for all route limits *)

type route_key = string
(** Unique key identifying a route (e.g., "api.example.com:GET:/orders") *)

val create : clock:_ Eio.Time.clock -> ?max_idle_time:float -> unit -> t
(** Create a state manager.
    @param clock Eio clock for timing
    @param max_idle_time
      Remove states unused for this long in seconds (default: 300.0) *)

val check_limits :
  t ->
  route_key:route_key ->
  limits:Rl_types.limit_config list ->
  (unit, float) result
(** Check all limits for a route.
    @return
      [Ok ()] if all limits pass, [Error max_retry_after] if any limit is
      exceeded *)

val cleanup : t -> unit
(** Remove stale state entries (unused longer than max_idle_time) *)

val state_count : t -> int
(** Get the number of active state entries (for monitoring) *)

val reset : t -> unit
(** Clear all state (for testing) *)
