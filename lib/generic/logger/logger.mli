(** Generic structured logging built on the Logs library. *)

val src : Logs.src
(** The Logs source for this library *)

val log_debug : section:string -> event:string -> (string * string) list -> unit
(** Log at debug level with section, event, and key-value pairs *)

val log_info : section:string -> event:string -> (string * string) list -> unit
(** Log at info level with section, event, and key-value pairs *)

val log_warn : section:string -> event:string -> (string * string) list -> unit
(** Log at warning level with section, event, and key-value pairs *)

val log_err : section:string -> event:string -> (string * string) list -> unit
(** Log at error level with section, event, and key-value pairs *)
