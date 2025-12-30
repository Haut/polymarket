(** Simple structured logging for websocket library. *)

let src = Logs.Src.create "websocket" ~doc:"WebSocket library"

module Log = (val Logs.src_log src : Logs.LOG)

let quote s = Printf.sprintf "\"%s\"" s
let format_kv (key, value) = Printf.sprintf "%s=%s" key (quote value)
let format_kvs kvs = String.concat " " (List.map format_kv kvs)

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
