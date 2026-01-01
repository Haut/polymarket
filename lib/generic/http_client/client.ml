(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client. Uses cohttp-eio for HTTP
    requests. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module R = Polymarket_rate_limiter.Rate_limiter

let section = "HTTP"

(** {1 Client Configuration} *)

type t = {
  base_url : string;
  sw : Eio.Switch.t;
  rate_limiter : R.t;
  client : Cohttp_eio.Client.t;
}

let make_https_handler _net =
  let authenticator =
    match Ca_certs.authenticator () with
    | Ok auth -> auth
    | Error (`Msg msg) -> failwith ("CA certs error: " ^ msg)
  in
  let tls_config =
    match Tls.Config.client ~authenticator () with
    | Ok cfg -> cfg
    | Error (`Msg msg) -> failwith ("TLS config error: " ^ msg)
  in
  fun uri socket ->
    let host =
      (* Extract host for SNI *)
      match Uri.host uri with
      | Some h -> h
      | None -> "localhost"
    in
    Tls_eio.client_of_flow tls_config
      ~host:(Domain_name.of_string_exn host |> Domain_name.host_exn)
      socket

let create ~base_url ~sw ~net ~rate_limiter () =
  let client =
    Cohttp_eio.Client.make ~https:(Some (make_https_handler net)) net
  in
  { base_url; sw; rate_limiter; client }

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
  Logger.log_info ~section ~event:"REQUEST"
    [ ("method", method_); ("uri", Uri.to_string uri) ]

let log_response ~method_ uri status =
  Logger.log_info ~section ~event:"RESPONSE"
    [
      ("method", method_);
      ("uri", Uri.to_string uri);
      ("status", string_of_int status);
    ]

let log_error ~method_ uri error =
  Logger.log_err ~section ~event:"ERROR"
    [ ("method", method_); ("uri", Uri.to_string uri); ("error", error) ]

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

let check_extra_fields ~expected_fields ~context json =
  match json with
  | `Assoc fields ->
      let actual = List.map fst fields in
      let extra =
        List.filter (fun f -> not (List.mem f expected_fields)) actual
      in
      if extra <> [] then
        Logger.log_warn ~section:"JSON" ~event:"EXTRA_FIELDS"
          [ ("context", context); ("fields", String.concat ", " extra) ]
  | _ -> ()

let parse_with_field_check ~expected_fields ~context body of_yojson =
  try
    let json = Yojson.Safe.from_string body in
    check_extra_fields ~expected_fields ~context json;
    Ok (of_yojson json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _) ->
      Error (to_error (Printexc.to_string exn))
  | exn -> Error (to_error (Printexc.to_string exn))

let parse_list_with_field_check ~expected_fields ~context body of_yojson =
  try
    let json = Yojson.Safe.from_string body in
    (match json with
    | `List items ->
        List.iter (check_extra_fields ~expected_fields ~context) items
    | _ -> ());
    Ok (of_yojson json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _) ->
      Error (to_error (Printexc.to_string exn))
  | exn -> Error (to_error (Printexc.to_string exn))
