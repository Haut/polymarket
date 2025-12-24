(** Data API logging. *)

let src = Logs.Src.create "polymarket" ~doc:"Polymarket library"

module Log = (val Logs.src_log src : Logs.LOG)

let section = "DATA_API"
let quote s = Printf.sprintf "\"%s\"" s
let format_kv (key, value) = Printf.sprintf "%s=%s" key (quote value)
let format_kvs kvs = String.concat " " (List.map format_kv kvs)

let log_info ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then Log.info (fun m -> m "[%s] [%s]" section event)
  else Log.info (fun m -> m "[%s] [%s] %s" section event kv_str)

let log_debug ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then Log.debug (fun m -> m "[%s] [%s]" section event)
  else Log.debug (fun m -> m "[%s] [%s] %s" section event kv_str)

let log_warn ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then Log.warn (fun m -> m "[%s] [%s]" section event)
  else Log.warn (fun m -> m "[%s] [%s] %s" section event kv_str)

let log_err ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then Log.err (fun m -> m "[%s] [%s]" section event)
  else Log.err (fun m -> m "[%s] [%s] %s" section event kv_str)
