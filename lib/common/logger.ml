(** Structured logging utilities.

    This module provides setup and structured logging functions that all
    components use. *)

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
  (* Only set the source level, don't override the reporter *)
  Logs.Src.set_level src log_level

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

(** {1 HTTP Logging} *)

let log_request ~method_ ~uri =
  let url = Uri.to_string uri in
  log_info ~section:"HTTP_CLIENT" ~event:"REQUEST"
    [ ("method", method_); ("url", url) ]

let log_response ~method_ ~uri ~status ~body =
  let url = Uri.to_string uri in
  let status_code = match status with `Code c -> string_of_int c in
  log_info ~section:"HTTP_CLIENT" ~event:"RESPONSE"
    [ ("method", method_); ("url", url); ("status", status_code) ];
  log_debug ~section:"HTTP_CLIENT" ~event:"BODY" [ ("body", body) ]

let log_error ~method_ ~uri ~exn =
  let url = Uri.to_string uri in
  let error = Printexc.to_string exn in
  log_err ~section:"HTTP_CLIENT" ~event:"ERROR"
    [ ("method", method_); ("url", url); ("error", error) ]

(** {1 JSON Field Logging} *)

let extract_keys json =
  match json with `Assoc pairs -> List.map fst pairs | _ -> []

let log_json_fields ~context json =
  let keys = extract_keys json in
  if keys <> [] then
    let fields = String.concat ", " keys in
    log_debug ~section:"HTTP_CLIENT" ~event:"JSON_FIELDS"
      [ ("context", context); ("fields", fields) ]

let log_json_fields_with_expected ~context ~expected json =
  let actual = extract_keys json in
  if actual <> [] || expected <> [] then begin
    let extra = List.filter (fun k -> not (List.mem k expected)) actual in
    let missing = List.filter (fun k -> not (List.mem k actual)) expected in
    let fields = String.concat ", " actual in
    log_debug ~section:"HTTP_CLIENT" ~event:"JSON_FIELDS"
      [ ("context", context); ("fields", fields) ];
    if extra <> [] then
      log_debug ~section:"HTTP_CLIENT" ~event:"JSON_EXTRA"
        [ ("context", context); ("extra", String.concat ", " extra) ];
    if missing <> [] then
      log_debug ~section:"HTTP_CLIENT" ~event:"JSON_MISSING"
        [ ("context", context); ("missing", String.concat ", " missing) ]
  end
