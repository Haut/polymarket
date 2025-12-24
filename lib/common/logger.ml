(** Application-level logging utilities.

    This module provides the logging setup function and application-level
    logging functions. Component-specific logging is in each component's Logger
    module. *)

let src = Logs.Src.create "polymarket.app" ~doc:"Polymarket application"

module Log = (val Logs.src_log src : Logs.LOG)

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

(** {1 Application Logging} *)

let info msg = Log.info (fun m -> m "%s" msg)
let debug msg = Log.debug (fun m -> m "%s" msg)
let warn msg = Log.warn (fun m -> m "%s" msg)
let err msg = Log.err (fun m -> m "%s" msg)

let section name =
  Log.info (fun m -> m "");
  Log.info (fun m -> m "%s" name);
  Log.info (fun m -> m "%s" (String.make (String.length name) '='))

let ok name msg = Log.info (fun m -> m "[OK] %s: %s" name msg)
let error name msg = Log.info (fun m -> m "[ERROR] %s: %s" name msg)
let skip name msg = Log.info (fun m -> m "[SKIP] %s: %s" name msg)
