(** Generic structured logging built on the Logs library.

    Provides a consistent logging interface with structured key-value pairs. *)

let src = Logs.Src.create "polymarket" ~doc:"Polymarket OCaml client"

module Log = (val Logs.src_log src : Logs.LOG)

(** Format key-value pairs as a structured log string *)
let format_kvs kvs =
  String.concat " "
    (List.map (fun (k, v) -> Printf.sprintf "%s=\"%s\"" k v) kvs)

(** Log at debug level *)
let log_debug ~section ~event kvs =
  Log.debug (fun m -> m "[%s] [%s] %s" section event (format_kvs kvs))

(** Log at info level *)
let log_info ~section ~event kvs =
  Log.info (fun m -> m "[%s] [%s] %s" section event (format_kvs kvs))

(** Log at warning level *)
let log_warn ~section ~event kvs =
  Log.warn (fun m -> m "[%s] [%s] %s" section event (format_kvs kvs))

(** Log at error level *)
let log_err ~section ~event kvs =
  Log.err (fun m -> m "[%s] [%s] %s" section event (format_kvs kvs))
