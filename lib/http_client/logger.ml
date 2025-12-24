(** HTTP client logging. *)

let src = Logs.Src.create "polymarket" ~doc:"Polymarket library"

module Log = (val Logs.src_log src : Logs.LOG)

let section = "HTTP_CLIENT"
let quote s = Printf.sprintf "\"%s\"" s
let format_kv (key, value) = Printf.sprintf "%s=%s" key (quote value)
let format_kvs kvs = String.concat " " (List.map format_kv kvs)

let log_request ~method_ ~uri =
  let url = Uri.to_string uri in
  let kvs = format_kvs [ ("method", method_); ("url", url) ] in
  Log.info (fun m -> m "[%s] [REQUEST] %s" section kvs)

let log_response ~method_ ~uri ~status ~body =
  let url = Uri.to_string uri in
  let status_code = string_of_int (Cohttp.Code.code_of_status status) in
  let kvs =
    format_kvs [ ("method", method_); ("url", url); ("status", status_code) ]
  in
  Log.info (fun m -> m "[%s] [RESPONSE] %s" section kvs);
  let body_kvs = format_kvs [ ("body", body) ] in
  Log.debug (fun m -> m "[%s] [BODY] %s" section body_kvs)

let log_error ~method_ ~uri ~exn =
  let url = Uri.to_string uri in
  let error = Printexc.to_string exn in
  let kvs =
    format_kvs [ ("method", method_); ("url", url); ("error", error) ]
  in
  Log.err (fun m -> m "[%s] [ERROR] %s" section kvs)

(** {1 JSON Field Logging} *)

let extract_keys json =
  match json with `Assoc pairs -> List.map fst pairs | _ -> []

let log_json_fields ~context json =
  let keys = extract_keys json in
  if keys <> [] then
    let fields = String.concat ", " keys in
    let kvs = format_kvs [ ("context", context); ("fields", fields) ] in
    Log.debug (fun m -> m "[%s] [JSON_FIELDS] %s" section kvs)

let log_json_fields_with_expected ~context ~expected json =
  let actual = extract_keys json in
  if actual <> [] || expected <> [] then begin
    let extra = List.filter (fun k -> not (List.mem k expected)) actual in
    let missing = List.filter (fun k -> not (List.mem k actual)) expected in
    let fields = String.concat ", " actual in
    let kvs = format_kvs [ ("context", context); ("fields", fields) ] in
    Log.debug (fun m -> m "[%s] [JSON_FIELDS] %s" section kvs);
    if extra <> [] then begin
      let kvs =
        format_kvs [ ("context", context); ("extra", String.concat ", " extra) ]
      in
      Log.debug (fun m -> m "[%s] [JSON_EXTRA] %s" section kvs)
    end;
    if missing <> [] then begin
      let kvs =
        format_kvs
          [ ("context", context); ("missing", String.concat ", " missing) ]
      in
      Log.debug (fun m -> m "[%s] [JSON_MISSING] %s" section kvs)
    end
  end
