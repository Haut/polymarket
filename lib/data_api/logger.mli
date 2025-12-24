(** Data API logging.

    Uses the "polymarket.data" log source. *)

val src : Logs.Src.t
(** The log source for Data API logging. *)

val info : string -> unit
val debug : string -> unit
val warn : string -> unit
val err : string -> unit
