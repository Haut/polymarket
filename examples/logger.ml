(** Example logger with timestamps and colors.

    Provides structured logging with ISO 8601 timestamps for demo programs. Uses
    the Logs library with a custom timestamped reporter and ANSI colors.

    Set POLYMARKET_LOG_FILE to write logs to a file instead of stdout. *)

let src = Logs.Src.create "demo" ~doc:"Demo application"

module Log = (val Logs.src_log src : Logs.LOG)

(** {1 Timestamp Reporter} *)

let timestamp () =
  let now = Unix.gettimeofday () in
  let tm = Unix.gmtime now in
  let millis = int_of_float ((now -. floor now) *. 1000.) in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ" (1900 + tm.Unix.tm_year)
    (tm.Unix.tm_mon + 1) tm.Unix.tm_mday tm.Unix.tm_hour tm.Unix.tm_min
    tm.Unix.tm_sec millis

let level_style = function
  | Logs.App -> `Magenta
  | Logs.Error -> `Red
  | Logs.Warning -> `Yellow
  | Logs.Info -> `Green
  | Logs.Debug -> `Cyan

let level_to_string = function
  | Logs.App -> "APP"
  | Logs.Error -> "ERROR"
  | Logs.Warning -> "WARN"
  | Logs.Info -> "INFO"
  | Logs.Debug -> "DEBUG"

let is_polymarket_source src =
  let name = Logs.Src.name src in
  name = "demo"
  || (String.length name >= 10 && String.sub name 0 10 = "polymarket")

let make_reporter ppf =
  let report src level ~over k msgf =
    if is_polymarket_source src then
      let k _ =
        over ();
        k ()
      in
      let src_name = Logs.Src.name src in
      let style = level_style level in
      msgf @@ fun ?header:_ ?tags:_ fmt ->
      Format.kfprintf k ppf
        ("%s %a %a @[" ^^ fmt ^^ "@]@.")
        (timestamp ())
        Fmt.(styled style string)
        (level_to_string level)
        Fmt.(styled `Bold string)
        src_name
    else begin
      over ();
      k ()
    end
  in
  { Logs.report }

let log_channel = ref None

let setup () =
  (* Enable ANSI colors if stdout is a TTY *)
  Fmt_tty.setup_std_outputs ();
  let reporter =
    match Sys.getenv_opt "POLYMARKET_LOG_FILE" with
    | Some path ->
        let oc = open_out path in
        log_channel := Some oc;
        (* No colors for file output *)
        Fmt.set_style_renderer (Format.formatter_of_out_channel oc) `None;
        make_reporter (Format.formatter_of_out_channel oc)
    | None -> make_reporter Format.std_formatter
  in
  Logs.set_reporter reporter;
  (* Set global log level for all sources based on POLYMARKET_LOG_LEVEL.
     Default to Info if not specified. *)
  let log_level =
    match Sys.getenv_opt "POLYMARKET_LOG_LEVEL" with
    | Some "debug" -> Some Logs.Debug
    | Some "info" -> Some Logs.Info
    | Some "warn" -> Some Logs.Warning
    | Some "error" -> Some Logs.Error
    | _ -> Some Logs.Info
  in
  Logs.set_level log_level

let close () =
  match !log_channel with
  | Some oc ->
      close_out oc;
      log_channel := None
  | None -> ()

(** {1 Logging Helpers} *)

let info msg = Log.info (fun m -> m "%s" msg)
let debug msg = Log.debug (fun m -> m "%s" msg)
let ok name result = Log.info (fun m -> m "%s: %s" name result)
let warn name msg = Log.warn (fun m -> m "%s: %s" name msg)
let error name msg = Log.err (fun m -> m "%s: %s" name msg)
let skip name reason = Log.info (fun m -> m "[SKIP] %s: %s" name reason)
