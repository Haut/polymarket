(** Logging utilities for Polymarket API clients. *)

let src = Logs.Src.create "polymarket.http" ~doc:"Polymarket HTTP client"

module Log = (val Logs.src_log src : Logs.LOG)

(** {1 Initialization} *)

let parse_log_level level_str =
  match String.lowercase_ascii level_str with
  | "debug" -> Some Logs.Debug
  | "info" -> Some Logs.Info
  | "off" -> None
  | _ -> None

let setup () =
  (* Read log level from environment variable *)
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

  (* Only set up reporter if logging is enabled *)
  match log_level with
  | Some _ ->
      Fmt_tty.setup_std_outputs ();
      Logs.set_reporter (Logs_fmt.reporter ());
      Logs.Src.set_level src log_level
  | None ->
      (* Explicitly disable logging *)
      Logs.Src.set_level src None

(** {1 HTTP Logging} *)

let log_request ~method_ ~uri =
  let uri_str = Uri.to_string uri in
  Log.info (fun m -> m "HTTP %s %s" method_ uri_str)

let log_response ~method_ ~uri ~status ~body =
  let uri_str = Uri.to_string uri in
  let status_code = Cohttp.Code.code_of_status status in
  Log.info (fun m -> m "HTTP %s %s -> %d" method_ uri_str status_code);
  Log.debug (fun m -> m "Response body: %s" body)

let log_error ~method_ ~uri ~exn =
  let uri_str = Uri.to_string uri in
  Log.err (fun m ->
      m "HTTP %s %s failed: %s" method_ uri_str (Printexc.to_string exn))

(** {1 JSON Field Logging} *)

let extract_keys json =
  match json with `Assoc pairs -> List.map fst pairs | _ -> []

let log_json_fields ~context json =
  let keys = extract_keys json in
  if keys <> [] then
    Log.debug (fun m ->
        m "JSON fields [%s]: %s" context (String.concat ", " keys))

let log_json_fields_with_expected ~context ~expected json =
  let actual = extract_keys json in
  if actual <> [] || expected <> [] then begin
    let extra = List.filter (fun k -> not (List.mem k expected)) actual in
    let missing = List.filter (fun k -> not (List.mem k actual)) expected in
    Log.debug (fun m ->
        m "JSON fields [%s]: %s" context (String.concat ", " actual));
    if extra <> [] then
      Log.debug (fun m ->
          m "  Extra fields (not in type): %s" (String.concat ", " extra));
    if missing <> [] then
      Log.debug (fun m ->
          m "  Missing fields (in type but not JSON): %s"
            (String.concat ", " missing))
  end
