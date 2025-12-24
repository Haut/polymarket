(** Gamma API logging.

    Uses the "polymarket.gamma" log source. *)

val src : Logs.Src.t
(** The log source for Gamma API logging. *)

val info : string -> unit
val debug : string -> unit
val warn : string -> unit
val err : string -> unit
