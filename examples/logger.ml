(** Example logger with timestamps.

    Provides structured logging with ISO 8601 timestamps for demo programs. Uses
    the Logs library with a custom timestamped reporter.

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

let pp_header ppf (level, _header) =
  let ts = timestamp () in
  match level with
  | Logs.Error -> Format.fprintf ppf "%s [ERROR]" ts
  | Logs.Warning -> Format.fprintf ppf "%s [WARN]" ts
  | _ -> Format.fprintf ppf "%s" ts

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
      msgf @@ fun ?header:_ ?tags:_ fmt ->
      Format.kfprintf k ppf ("%a @[" ^^ fmt ^^ "@]@.") pp_header (level, None)
    else begin
      over ();
      k ()
    end
  in
  { Logs.report }

let log_channel = ref None

let setup () =
  let reporter =
    match Sys.getenv_opt "POLYMARKET_LOG_FILE" with
    | Some path ->
        let oc = open_out path in
        log_channel := Some oc;
        make_reporter (Format.formatter_of_out_channel oc)
    | None -> make_reporter Format.std_formatter
  in
  Logs.set_reporter reporter;
  Logs.Src.set_level src (Some Logs.Debug);
  (* Also initialize the polymarket library logger to respect POLYMARKET_LOG_LEVEL *)
  Polymarket_common.Logger.setup ()

let close () =
  match !log_channel with
  | Some oc ->
      close_out oc;
      log_channel := None
  | None -> ()

(** {1 Formatting} *)

let quote s = Printf.sprintf "\"%s\"" s
let format_kv (key, value) = Printf.sprintf "%s=%s" key (quote value)
let format_kvs kvs = String.concat " " (List.map format_kv kvs)

(** {1 Demo Logging Helpers} *)

let info event kvs =
  let kv_str = format_kvs kvs in
  if kv_str = "" then Log.info (fun m -> m "[DEMO] [%s]" event)
  else Log.info (fun m -> m "[DEMO] [%s] %s" event kv_str)

let ok name msg =
  Log.info (fun m -> m "[DEMO] [OK] name=\"%s\" result=\"%s\"" name msg)

let error name msg =
  Log.err (fun m -> m "[DEMO] [ERROR] name=\"%s\" error=\"%s\"" name msg)

let skip name msg =
  Log.info (fun m -> m "[DEMO] [SKIP] name=\"%s\" reason=\"%s\"" name msg)

let header title = Log.info (fun m -> m "[DEMO] [SECTION] title=\"%s\"" title)
