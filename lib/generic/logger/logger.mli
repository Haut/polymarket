(** Structured logging library.

    This module provides a functor for creating structured loggers with a
    consistent format: [[SECTION] [EVENT] key="value" ...]

    {1 Usage}

    Create a logger for your library:
    {[
      module Log = Logger.Make (struct
        let name = "mylib"
        let doc = "My library"
      end)

      let () = Log.log_info ~section:"INIT" ~event:"START" []
    ]} *)

(** {1 Formatting Helpers} *)

val format_kv : string * string -> string
(** Format a single key-value pair as [key="value"]. *)

val format_kvs : (string * string) list -> string
(** Format a list of key-value pairs as [key1="value1" key2="value2" ...]. *)

(** {1 Logger Functor} *)

module type CONFIG = sig
  val name : string
  (** Log source name (e.g., "websocket", "http"). *)

  val doc : string
  (** Log source description. *)
end

module type S = sig
  val src : Logs.Src.t
  (** The log source. Can be used to configure log levels. *)

  val log_info :
    section:string -> event:string -> (string * string) list -> unit
  (** Log at info level. *)

  val log_debug :
    section:string -> event:string -> (string * string) list -> unit
  (** Log at debug level. *)

  val log_warn :
    section:string -> event:string -> (string * string) list -> unit
  (** Log at warning level. *)

  val log_err : section:string -> event:string -> (string * string) list -> unit
  (** Log at error level. *)
end

(** Create a logger with the given configuration. *)
module Make (_ : CONFIG) : S
