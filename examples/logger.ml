(** Example logger with timestamps.

    Provides structured logging with ISO 8601 timestamps for demo programs. *)

(** {1 Timestamp} *)

let timestamp () =
  let now = Unix.gettimeofday () in
  let tm = Unix.gmtime now in
  let millis = int_of_float ((now -. floor now) *. 1000.) in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ" (1900 + tm.Unix.tm_year)
    (tm.Unix.tm_mon + 1) tm.Unix.tm_mday tm.Unix.tm_hour tm.Unix.tm_min
    tm.Unix.tm_sec millis

(** {1 Formatting} *)

let quote s = Printf.sprintf "\"%s\"" s
let format_kv (key, value) = Printf.sprintf "%s=%s" key (quote value)
let format_kvs kvs = String.concat " " (List.map format_kv kvs)

(** {1 Structured Logging} *)

let log_info ~section ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then
    Printf.printf "%s [%s] [%s]\n" (timestamp ()) section event
  else Printf.printf "%s [%s] [%s] %s\n" (timestamp ()) section event kv_str

let log_debug ~section ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then
    Printf.printf "%s [%s] [%s]\n" (timestamp ()) section event
  else Printf.printf "%s [%s] [%s] %s\n" (timestamp ()) section event kv_str

let log_warn ~section ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then
    Printf.printf "%s [WARN] [%s] [%s]\n" (timestamp ()) section event
  else
    Printf.printf "%s [WARN] [%s] [%s] %s\n" (timestamp ()) section event kv_str

let log_err ~section ~event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then
    Printf.printf "%s [ERROR] [%s] [%s]\n" (timestamp ()) section event
  else
    Printf.printf "%s [ERROR] [%s] [%s] %s\n" (timestamp ()) section event
      kv_str

(** {1 Demo Logging Helpers} *)

let section = "DEMO"
let info event kvs = log_info ~section ~event kvs
let debug event kvs = log_debug ~section ~event kvs
let warn event kvs = log_warn ~section ~event kvs
let err event kvs = log_err ~section ~event kvs
let ok name msg = info "OK" [ ("name", name); ("result", msg) ]
let error name msg = err "ERROR" [ ("name", name); ("error", msg) ]
let skip name msg = info "SKIP" [ ("name", name); ("reason", msg) ]
let header title = info "SECTION" [ ("title", title) ]
