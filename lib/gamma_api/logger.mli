(** Gamma API logging with structured key-value format.

    Uses the "polymarket" log source with section "GAMMA_API".

    {1 Log Format}

    All log messages follow the structured format:
    {[
      [GAMMA_API] [EVENT] key="value" key2="value2"
    ]}

    Examples:
    - [[GAMMA_API] [CALL] endpoint="/events" limit="10"]]
    - [[GAMMA_API] [ERROR] endpoint="/markets" error="..."]] *)

val src : Logs.Src.t
(** The log source for Gamma API logging. *)

val log_info : event:string -> (string * string) list -> unit
(** Log at info level with GAMMA_API section. *)

val log_debug : event:string -> (string * string) list -> unit
(** Log at debug level with GAMMA_API section. *)

val log_warn : event:string -> (string * string) list -> unit
(** Log at warning level with GAMMA_API section. *)

val log_err : event:string -> (string * string) list -> unit
(** Log at error level with GAMMA_API section. *)
