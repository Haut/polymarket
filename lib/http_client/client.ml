(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client with JSON parsing and query
    parameter building utilities. Uses cohttp-eio for HTTP requests. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module R = Polymarket_rate_limiter.Rate_limiter

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

(** {1 Query Parameter Builders} *)

type params = (string * string list) list

let add key value params =
  match value with Some v -> (key, [ v ]) :: params | None -> params

let add_option key to_string value params =
  match value with Some v -> (key, [ to_string v ]) :: params | None -> params

let add_list key to_string values params =
  match values with
  | Some vs when vs <> [] ->
      let joined = String.concat "," (List.map to_string vs) in
      (key, [ joined ]) :: params
  | _ -> params

let add_bool key value params =
  match value with
  | Some true -> (key, [ "true" ]) :: params
  | Some false -> (key, [ "false" ]) :: params
  | None -> params

let add_each key to_string values params =
  match values with
  | Some vs ->
      List.fold_left (fun acc v -> (key, [ to_string v ]) :: acc) params vs
  | None -> params

(** {1 HTTP Request Functions} *)

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

let do_get ?(headers = []) t uri =
  apply_rate_limit t ~method_:"GET" ~uri;
  Polymarket_common.Logger.log_request ~method_:"GET" ~uri;
  let headers = make_headers headers in
  try
    let resp, body = Cohttp_eio.Client.get ~sw:t.sw ~headers t.client uri in
    let status = Http.Response.status resp |> Http.Status.to_int in
    let body_str = body_to_string body in
    Polymarket_common.Logger.log_response ~method_:"GET" ~uri
      ~status:(`Code status) ~body:body_str;
    (status, body_str)
  with exn ->
    let msg = Printexc.to_string exn in
    Polymarket_common.Logger.log_error ~method_:"GET" ~uri ~exn;
    (500, Printf.sprintf {|{"error": "Request failed: %s"}|} msg)

let do_post ?(headers = []) t uri ~body:request_body =
  apply_rate_limit t ~method_:"POST" ~uri;
  Polymarket_common.Logger.log_request ~method_:"POST" ~uri;
  let headers =
    make_headers (("Content-Type", "application/json") :: headers)
  in
  let body = Cohttp_eio.Body.of_string request_body in
  try
    let resp, resp_body =
      Cohttp_eio.Client.post ~sw:t.sw ~headers ~body t.client uri
    in
    let status = Http.Response.status resp |> Http.Status.to_int in
    let body_str = body_to_string resp_body in
    Polymarket_common.Logger.log_response ~method_:"POST" ~uri
      ~status:(`Code status) ~body:body_str;
    (status, body_str)
  with exn ->
    let msg = Printexc.to_string exn in
    Polymarket_common.Logger.log_error ~method_:"POST" ~uri ~exn;
    (500, Printf.sprintf {|{"error": "Request failed: %s"}|} msg)

let do_delete ?(headers = []) t uri =
  apply_rate_limit t ~method_:"DELETE" ~uri;
  Polymarket_common.Logger.log_request ~method_:"DELETE" ~uri;
  let headers = make_headers headers in
  try
    let resp, body = Cohttp_eio.Client.delete ~sw:t.sw ~headers t.client uri in
    let status = Http.Response.status resp |> Http.Status.to_int in
    let body_str = body_to_string body in
    Polymarket_common.Logger.log_response ~method_:"DELETE" ~uri
      ~status:(`Code status) ~body:body_str;
    (status, body_str)
  with exn ->
    let msg = Printexc.to_string exn in
    Polymarket_common.Logger.log_error ~method_:"DELETE" ~uri ~exn;
    (500, Printf.sprintf {|{"error": "Request failed: %s"}|} msg)

(** {1 JSON Parsing} *)

let parse_json parse_fn body =
  try
    let json = Yojson.Safe.from_string body in
    Ok (parse_fn json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      let msg =
        Printf.sprintf
          "JSON parse error: %s\nProblematic value: %s\nFull response:\n%s"
          (Printexc.to_string exn)
          (Yojson.Safe.to_string json)
          body
      in
      Polymarket_common.Logger.log_err ~section:"HTTP_CLIENT"
        ~event:"PARSE_ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg
  | Yojson.Json_error msg ->
      let err = "JSON error: " ^ msg ^ "\nBody:\n" ^ body in
      Polymarket_common.Logger.log_err ~section:"HTTP_CLIENT"
        ~event:"PARSE_ERROR"
        [ ("error", msg) ];
      Error err
  | exn ->
      let msg =
        Printf.sprintf "Parse error: %s\nFull response:\n%s"
          (Printexc.to_string exn) body
      in
      Polymarket_common.Logger.log_err ~section:"HTTP_CLIENT"
        ~event:"PARSE_ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg

let parse_json_list parse_item_fn body =
  try
    let json = Yojson.Safe.from_string body in
    match json with
    | `List items -> Ok (List.map parse_item_fn items)
    | _ ->
        let err = "Expected JSON array\nBody:\n" ^ body in
        Polymarket_common.Logger.log_err ~section:"HTTP_CLIENT"
          ~event:"PARSE_ERROR"
          [ ("error", "expected JSON array") ];
        Error err
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      let msg =
        Printf.sprintf
          "JSON parse error: %s\nProblematic value: %s\nFull response:\n%s"
          (Printexc.to_string exn)
          (Yojson.Safe.to_string json)
          body
      in
      Polymarket_common.Logger.log_err ~section:"HTTP_CLIENT"
        ~event:"PARSE_ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg
  | Yojson.Json_error msg ->
      let err = "JSON error: " ^ msg ^ "\nBody:\n" ^ body in
      Polymarket_common.Logger.log_err ~section:"HTTP_CLIENT"
        ~event:"PARSE_ERROR"
        [ ("error", msg) ];
      Error err
  | exn ->
      let msg =
        Printf.sprintf "Parse error: %s\nFull response:\n%s"
          (Printexc.to_string exn) body
      in
      Polymarket_common.Logger.log_err ~section:"HTTP_CLIENT"
        ~event:"PARSE_ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg

(** {1 Error Handling} *)

type error_response = { error : string } [@@deriving yojson]

let to_error msg = { error = msg }

let parse_error body =
  try error_response_of_yojson (Yojson.Safe.from_string body)
  with _ -> { error = body }

(** {1 Response Handling} *)

let handle_response status body parse_fn error_parser =
  match status with 200 -> parse_fn body | _ -> Error (error_parser body)

let request ?(headers = []) t path parse_fn error_parser params =
  let uri = build_uri t.base_url path params in
  let status, body = do_get ~headers t uri in
  handle_response status body parse_fn error_parser

(** {1 Convenient JSON Request Helpers} *)

let get_json ?(headers = []) t path parser params =
  request ~headers t path
    (fun body -> parse_json parser body |> Result.map_error to_error)
    parse_error params

let get_json_list ?(headers = []) t path parser params =
  request ~headers t path
    (fun body -> parse_json_list parser body |> Result.map_error to_error)
    parse_error params

let get_text ?(headers = []) t path params =
  request ~headers t path (fun body -> Ok body) parse_error params

let post_json ?(headers = []) t path parser ~body params =
  let uri = build_uri t.base_url path params in
  let status, resp_body = do_post ~headers t uri ~body in
  handle_response status resp_body
    (fun body -> parse_json parser body |> Result.map_error to_error)
    parse_error

let post_json_list ?(headers = []) t path parser ~body params =
  let uri = build_uri t.base_url path params in
  let status, resp_body = do_post ~headers t uri ~body in
  handle_response status resp_body
    (fun body -> parse_json_list parser body |> Result.map_error to_error)
    parse_error

let delete_json ?(headers = []) t path parser params =
  let uri = build_uri t.base_url path params in
  let status, body = do_delete ~headers t uri in
  handle_response status body
    (fun body -> parse_json parser body |> Result.map_error to_error)
    parse_error
