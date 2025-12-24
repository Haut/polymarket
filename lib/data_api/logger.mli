(** Data API logging with structured key-value format.

    Uses the "polymarket" log source with section "DATA_API".

    {1 Log Format}

    All log messages follow the structured format:
    {[
      [DATA_API] [EVENT] key="value" key2="value2"
    ]}

    Examples:
    - [[DATA_API] [CALL] endpoint="/positions" user="0x..."]]
    - [[DATA_API] [ERROR] endpoint="/markets" error="..."]] *)

val src : Logs.Src.t
(** The log source for Data API logging. *)

val log_info : event:string -> (string * string) list -> unit
(** Log at info level with DATA_API section. *)

val log_debug : event:string -> (string * string) list -> unit
(** Log at debug level with DATA_API section. *)

val log_warn : event:string -> (string * string) list -> unit
(** Log at warning level with DATA_API section. *)

val log_err : event:string -> (string * string) list -> unit
(** Log at error level with DATA_API section. *)
