(** Structured logging library.

    This module provides a functor for creating structured loggers with a
    consistent format: [[SECTION] [EVENT] key="value" ...] *)

(** {1 Formatting} *)

let quote s = Printf.sprintf "\"%s\"" s
let format_kv (key, value) = Printf.sprintf "%s=%s" key (quote value)
let format_kvs kvs = String.concat " " (List.map format_kv kvs)

(** {1 Logger Functor} *)

module type CONFIG = sig
  val name : string
  val doc : string
end

module type S = sig
  val src : Logs.Src.t

  val log_info :
    section:string -> event:string -> (string * string) list -> unit

  val log_debug :
    section:string -> event:string -> (string * string) list -> unit

  val log_warn :
    section:string -> event:string -> (string * string) list -> unit

  val log_err : section:string -> event:string -> (string * string) list -> unit
end

module Make (C : CONFIG) : S = struct
  let src = Logs.Src.create C.name ~doc:C.doc

  module Log = (val Logs.src_log src : Logs.LOG)

  let log_info ~section ~event kvs =
    let kv_str = format_kvs kvs in
    if kv_str = "" then Log.info (fun m -> m "[%s] [%s]" section event)
    else Log.info (fun m -> m "[%s] [%s] %s" section event kv_str)

  let log_debug ~section ~event kvs =
    let kv_str = format_kvs kvs in
    if kv_str = "" then Log.debug (fun m -> m "[%s] [%s]" section event)
    else Log.debug (fun m -> m "[%s] [%s] %s" section event kv_str)

  let log_warn ~section ~event kvs =
    let kv_str = format_kvs kvs in
    if kv_str = "" then Log.warn (fun m -> m "[%s] [%s]" section event)
    else Log.warn (fun m -> m "[%s] [%s] %s" section event kv_str)

  let log_err ~section ~event kvs =
    let kv_str = format_kvs kvs in
    if kv_str = "" then Log.err (fun m -> m "[%s] [%s]" section event)
    else Log.err (fun m -> m "[%s] [%s] %s" section event kv_str)
end
