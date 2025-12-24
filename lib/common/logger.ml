(** Structured logging utilities.

    This module provides setup and a general-purpose structured logging function
    that all components use. *)

let src = Logs.Src.create "polymarket" ~doc:"Polymarket library"

module Log = (val Logs.src_log src : Logs.LOG)

(** {1 Formatting} *)

let quote s = Printf.sprintf "\"%s\"" s
let format_kv (key, value) = Printf.sprintf "%s=%s" key (quote value)
let format_kvs kvs = String.concat " " (List.map format_kv kvs)

(** {1 Initialization} *)

let parse_log_level level_str =
  match String.lowercase_ascii level_str with
  | "debug" -> Some Logs.Debug
  | "info" -> Some Logs.Info
  | "off" -> None
  | _ -> None

let setup () =
  let log_level =
    match Sys.getenv_opt "POLYMARKET_LOG_LEVEL" with
    | None -> None
    | Some level -> (
        match parse_log_level level with
        | None ->
            Printf.eprintf
              "Warning: Invalid POLYMARKET_LOG_LEVEL '%s'. Valid values: \
               debug, info, off\n\
               %!"
              level;
            None
        | some_level -> some_level)
  in
  match log_level with
  | Some level ->
      Fmt_tty.setup_std_outputs ();
      Logs.set_reporter (Logs_fmt.reporter ());
      Logs.set_level (Some level)
  | None -> Logs.set_level None

(** {1 Structured Logging} *)

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
