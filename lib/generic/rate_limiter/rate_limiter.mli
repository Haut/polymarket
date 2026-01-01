(** Route-based rate limiting for HTTP clients.

    This library provides GCRA-based rate limiting with route matching,
    supporting multiple limits per route and configurable delay/error behaviors.

    {2 Quick Start}

    {[
      (* Create a shared rate limiter with Polymarket API limits *)
      let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Delay in
      let rate_limiter =
        Rate_limiter.create ~routes ~clock:(Eio.Stdenv.clock env) ()
      in

      (* Pass to all API clients *)
      let gamma = Gamma.create ~sw ~net ~rate_limiter () in
      let data = Data.create ~sw ~net ~rate_limiter () in
    ]}

    {2 Features}

    - {b Route matching}: Match requests by host, HTTP method, and path prefix
    - {b Multiple limits}: Stack burst and sustained limits on the same route
    - {b GCRA algorithm}: Fair rate limiting using Generic Cell Rate Algorithm
    - {b Configurable behavior}: Delay requests or return errors per route *)

(** {1 Core Types} *)

type behavior = Types.behavior =
  | Delay
  | Error  (** Behavior when rate limit is exceeded *)

type route_pattern = Types.route_pattern = {
  host : string option;
  method_ : string option;
  path_prefix : string option;
}
(** Route matching pattern *)

type limit_config = Types.limit_config = {
  requests : int;
  window_seconds : float;
}
(** Rate limit configuration *)

type route_config = Types.route_config = {
  pattern : route_pattern;
  limits : limit_config list;
  behavior : behavior;
}
(** Complete route configuration *)

type error = Types.error =
  | Rate_limited of { retry_after : float; route_key : string }
      (** Rate limiter error *)

(** {1 Rate Limiter} *)

type t
(** Rate limiter state *)

exception Rate_limit_exceeded of error
(** Raised by [before_request] when behavior is [Error] and limit exceeded *)

val create :
  routes:route_config list ->
  clock:_ Eio.Time.clock ->
  ?max_idle_time:float ->
  unit ->
  t
(** Create a rate limiter with custom routes.
    @param routes Rate limit configurations (all matching routes apply)
    @param clock Eio clock for timing and delays
    @param max_idle_time
      For cleanup: remove states unused for this long (default: 300.0) *)

val update_routes : t -> route_config list -> unit
(** Update the rate limit routes at runtime *)

val before_request : t -> method_:string -> uri:Uri.t -> unit
(** Check rate limits before making a request.

    - For [Delay] behavior: sleeps until the request is allowed
    - For [Error] behavior: raises [Rate_limit_exceeded] if limit exceeded

    @raise Rate_limit_exceeded when behavior is [Error] and limit exceeded *)

val before_request_result :
  t -> method_:string -> uri:Uri.t -> (unit, error) result
(** Like [before_request] but returns a result instead of raising. *)

(** {1 State Management} *)

val cleanup : t -> unit
(** Remove stale state entries (unused longer than max_idle_time) *)

val state_count : t -> int
(** Get the number of active state entries *)

val reset : t -> unit
(** Clear all rate limit state (for testing) *)

(** {1 Sub-modules} *)

module Types = Types
module Builder = Builder
module Gcra = Gcra
module State = State
module Matcher = Matcher
