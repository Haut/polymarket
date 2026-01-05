(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client. Uses cohttp-eio for HTTP
    requests. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module R = Rate_limiter

let src = Logs.Src.create "polymarket.http" ~doc:"HTTP client"

module Log = (val Logs.src_log src : Logs.LOG)

(** {1 Client Configuration} *)

type t = {
  base_url : string;
  sw : Eio.Switch.t;
  rate_limiter : R.t;
  client : Cohttp_eio.Client.t;
}

(** TLS initialization error type *)
type init_error = Ca_certs_error of string | Tls_config_error of string

let string_of_init_error = function
  | Ca_certs_error msg -> "CA certs error: " ^ msg
  | Tls_config_error msg -> "TLS config error: " ^ msg

let make_https_handler _net =
  match Ca_certs.authenticator () with
  | Error (`Msg msg) -> Error (Ca_certs_error msg)
  | Ok authenticator -> (
      match Tls.Config.client ~authenticator () with
      | Error (`Msg msg) -> Error (Tls_config_error msg)
      | Ok tls_config ->
          Ok
            (fun uri socket ->
              let host =
                (* Extract host for SNI *)
                match Uri.host uri with
                | Some h -> h
                | None -> "localhost"
              in
              Tls_eio.client_of_flow tls_config
                ~host:(Domain_name.of_string_exn host |> Domain_name.host_exn)
                socket))

let create ~base_url ~sw ~net ~rate_limiter () =
  match make_https_handler net with
  | Error e ->
      Log.err (fun m ->
          m "TLS initialization failed: %s" (string_of_init_error e));
      Error e
  | Ok https_handler ->
      let client = Cohttp_eio.Client.make ~https:(Some https_handler) net in
      Ok { base_url; sw; rate_limiter; client }

let base_url t = t.base_url

(** {1 HTTP Request Functions} *)

type params = (string * string list) list

let build_uri base_url path params =
  let uri = Uri.of_string (base_url ^ path) in
  Uri.add_query_params uri params

type status_code = int

let apply_rate_limit t ~method_ ~uri =
  R.before_request t.rate_limiter ~method_ ~uri

(** Helper to convert header list to Http.Header.t *)
let make_headers headers = Http.Header.of_list headers

(** Helper to read body string from cohttp response *)
let body_to_string body =
  Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int

let log_request ~method_ uri =
  Log.debug (fun m -> m "%s %s" method_ (Uri.to_string uri))

let log_response ~method_ uri status =
  Log.debug (fun m -> m "%s %s -> %d" method_ (Uri.to_string uri) status)

let log_error ~method_ uri error =
  Log.err (fun m -> m "%s %s failed: %s" method_ (Uri.to_string uri) error)

let do_get ?(headers = []) t uri =
  apply_rate_limit t ~method_:"GET" ~uri;
  let headers = make_headers headers in
  log_request ~method_:"GET" uri;
  try
    let resp, body = Cohttp_eio.Client.get ~sw:t.sw ~headers t.client uri in
    let status = Http.Response.status resp |> Http.Status.to_int in
    let body_str = body_to_string body in
    log_response ~method_:"GET" uri status;
    (status, body_str)
  with exn ->
    let msg = Printexc.to_string exn in
    log_error ~method_:"GET" uri msg;
    (500, Printf.sprintf {|{"error": "Request failed: %s"}|} msg)

let do_post ?(headers = []) t uri ~body:request_body =
  apply_rate_limit t ~method_:"POST" ~uri;
  let headers =
    make_headers (("Content-Type", "application/json") :: headers)
  in
  let body = Cohttp_eio.Body.of_string request_body in
  log_request ~method_:"POST" uri;
  try
    let resp, resp_body =
      Cohttp_eio.Client.post ~sw:t.sw ~headers ~body t.client uri
    in
    let status = Http.Response.status resp |> Http.Status.to_int in
    let body_str = body_to_string resp_body in
    log_response ~method_:"POST" uri status;
    (status, body_str)
  with exn ->
    let msg = Printexc.to_string exn in
    log_error ~method_:"POST" uri msg;
    (500, Printf.sprintf {|{"error": "Request failed: %s"}|} msg)

let do_delete ?(headers = []) t uri =
  apply_rate_limit t ~method_:"DELETE" ~uri;
  let headers = make_headers headers in
  log_request ~method_:"DELETE" uri;
  try
    let resp, body = Cohttp_eio.Client.delete ~sw:t.sw ~headers t.client uri in
    let status = Http.Response.status resp |> Http.Status.to_int in
    let body_str = body_to_string body in
    log_response ~method_:"DELETE" uri status;
    (status, body_str)
  with exn ->
    let msg = Printexc.to_string exn in
    log_error ~method_:"DELETE" uri msg;
    (500, Printf.sprintf {|{"error": "Request failed: %s"}|} msg)

let do_delete_with_body ?(headers = []) t uri ~body:request_body =
  apply_rate_limit t ~method_:"DELETE" ~uri;
  let headers =
    make_headers (("Content-Type", "application/json") :: headers)
  in
  let body = Cohttp_eio.Body.of_string request_body in
  log_request ~method_:"DELETE" uri;
  try
    let resp, resp_body =
      Cohttp_eio.Client.delete ~sw:t.sw ~headers ~body t.client uri
    in
    let status = Http.Response.status resp |> Http.Status.to_int in
    let body_str = body_to_string resp_body in
    log_response ~method_:"DELETE" uri status;
    (status, body_str)
  with exn ->
    let msg = Printexc.to_string exn in
    log_error ~method_:"DELETE" uri msg;
    (500, Printf.sprintf {|{"error": "Request failed: %s"}|} msg)

(** {1 Error Handling} *)

type http_error = { status : int; body : string; message : string }
type parse_error = { context : string; message : string }
type network_error = { message : string }

type error =
  | Http_error of http_error
  | Parse_error of parse_error
  | Network_error of network_error

let error_to_string = function
  | Http_error { status; message; _ } ->
      Printf.sprintf "HTTP %d: %s" status message
  | Parse_error { context; message } ->
      Printf.sprintf "Parse error in %s: %s" context message
  | Network_error { message } -> Printf.sprintf "Network error: %s" message

let pp_error fmt e = Format.fprintf fmt "%s" (error_to_string e)

type error_response = { error : string } [@@deriving yojson]
(** Type for parsing JSON error responses from APIs. *)

let to_error msg = Parse_error { context = "json"; message = msg }

let parse_error ~status body =
  let message =
    (* Check for HTML error pages (from proxies like Cloudflare) *)
    if String.length body > 0 && body.[0] = '<' then
      match status with
      | 502 -> "Bad Gateway"
      | 503 -> "Service Unavailable"
      | 504 -> "Gateway Timeout"
      | 429 -> "Too Many Requests"
      | _ -> Printf.sprintf "HTTP error (status %d)" status
    else
      try
        let json = Yojson.Safe.from_string body in
        match json with
        | `Assoc fields -> (
            match List.assoc_opt "error" fields with
            | Some (`String msg) -> msg
            | _ -> body)
        | _ -> body
      with _ -> body
  in
  Http_error { status; body; message }

(** {1 Response Handling} *)

let handle_response status body parse_fn =
  match status with
  | 200 -> parse_fn body
  | _ -> Error (parse_error ~status body)

(** {1 JSON Field Checking} *)

(** Find the path to a specific JSON value within a larger JSON structure *)
let rec find_path_to_value ~target ~path json =
  if json == target then Some (List.rev path)
  else
    match json with
    | `Assoc fields ->
        List.find_map
          (fun (key, value) ->
            find_path_to_value ~target ~path:(key :: path) value)
          fields
    | `List items ->
        List.find_mapi
          (fun i item ->
            find_path_to_value ~target
              ~path:(Printf.sprintf "[%d]" i :: path)
              item)
          items
    | _ -> None

let format_path = function [] -> "<root>" | parts -> String.concat "." parts

let check_extra_fields ~expected_fields ~context json =
  match json with
  | `Assoc fields ->
      let extra_fields =
        List.filter
          (fun (name, _) -> not (List.mem name expected_fields))
          fields
      in
      if extra_fields <> [] then
        let format_field (name, value) =
          Printf.sprintf "%s: %s" name (Yojson.Safe.to_string value)
        in
        let formatted =
          List.map format_field extra_fields |> String.concat ", "
        in
        Log.warn (fun m -> m "Extra fields in %s: %s" context formatted)
  | _ -> ()

let parse_with_field_check ~expected_fields ~context body of_yojson =
  let root_json = ref `Null in
  try
    let json = Yojson.Safe.from_string body in
    root_json := json;
    check_extra_fields ~expected_fields ~context json;
    Ok (of_yojson json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, bad_json) ->
      let path =
        match find_path_to_value ~target:bad_json ~path:[] !root_json with
        | Some p -> format_path p
        | None -> "<unknown>"
      in
      let reason =
        match exn with Failure msg -> msg | _ -> Printexc.to_string exn
      in
      let msg = Printf.sprintf "%s.%s: %s" context path reason in
      Error (to_error msg)
  | exn -> Error (to_error (Printexc.to_string exn))

let parse_list_with_field_check ~expected_fields ~context body of_yojson =
  let root_json = ref `Null in
  try
    let json = Yojson.Safe.from_string body in
    root_json := json;
    (match json with
    | `List items ->
        List.iter (check_extra_fields ~expected_fields ~context) items
    | _ -> ());
    Ok (of_yojson json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, bad_json) ->
      let path =
        match find_path_to_value ~target:bad_json ~path:[] !root_json with
        | Some p -> format_path p
        | None -> "<unknown>"
      in
      let reason =
        match exn with Failure msg -> msg | _ -> Printexc.to_string exn
      in
      let msg = Printf.sprintf "%s.%s: %s" context path reason in
      Error (to_error msg)
  | exn -> Error (to_error (Printexc.to_string exn))
