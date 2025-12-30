(** Generic Cell Rate Algorithm (GCRA) for rate limiting.

    GCRA tracks a theoretical arrival time (TAT) for the next request. It
    provides fair rate limiting with configurable burst capacity.

    For a limit of N requests per T seconds:
    - Sustained rate: N/T requests per second
    - Burst capacity: N requests (the full quota can be used immediately)

    The algorithm ensures that over any T-second window, no more than N requests
    are allowed, while permitting short bursts when there's available quota. *)

type t
(** GCRA state for a single limit *)

val create : Types.limit_config -> t
(** Create a new GCRA state from a limit configuration *)

val check : t -> now:float -> (unit, float) result
(** Check if a request is allowed at the given time.
    @param now Current time in seconds (e.g., from [Eio.Time.now])
    @return [Ok ()] if allowed, [Error retry_after] if rate limited *)

val update : t -> now:float -> unit
(** Update state after a request is allowed. Must be called after [check]
    returns [Ok ()] and before releasing any locks. *)

val check_and_update : t -> now:float -> (unit, float) result
(** Combined check and update. Atomically checks if allowed and updates state.
    @return [Ok ()] if allowed, [Error retry_after] if rate limited *)

val reset : t -> unit
(** Reset the state (for testing) *)

val time_until_ready : t -> now:float -> float
(** Calculate seconds until the next request can proceed *)

val emission_interval : t -> float
(** Get the emission interval (time between requests at sustained rate) *)

val burst_allowance : t -> float
(** Get the burst allowance in seconds *)
