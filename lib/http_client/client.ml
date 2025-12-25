(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client with JSON parsing and query
    parameter building utilities. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Non-negative Integers} *)

module Nonneg_int = struct
  type t = int

  let of_int n = if n >= 0 then Some n else None
  let of_int_exn n = if n >= 0 then n else invalid_arg "must be non-negative"
  let to_int n = n
  let zero = 0
  let one = 1
end

(** {1 Timestamps} *)

module Timestamp = struct
  type t = Ptime.t

  let of_string s =
    match Ptime.of_rfc3339 s with Ok (t, _, _) -> Some t | Error _ -> None

  let of_string_exn s =
    match of_string s with
    | Some t -> t
    | None -> invalid_arg ("invalid ISO 8601 timestamp: " ^ s)

  let to_string t = Ptime.to_rfc3339 ~tz_offset_s:0 t
  let to_ptime t = t
  let of_ptime t = t

  let t_of_yojson = function
    | `String s -> of_string_exn s
    | _ -> failwith "Timestamp: expected string"

  let yojson_of_t t = `String (to_string t)
  let pp fmt t = Format.fprintf fmt "%s" (to_string t)
  let show t = to_string t
  let equal = Ptime.equal
end

(** {1 Client Configuration} *)

type t = { base_url : string; client : Cohttp_eio.Client.t; sw : Eio.Switch.t }

let create ~base_url ~sw ~net () =
  let authenticator =
    match Ca_certs.authenticator () with
    | Ok x -> x
    | Error (`Msg m) -> failwith ("Failed to create X509 authenticator: " ^ m)
  in
  let https =
    let tls_config =
      match Tls.Config.client ~authenticator () with
      | Error (`Msg msg) -> failwith ("TLS configuration error: " ^ msg)
      | Ok cfg -> cfg
    in
    fun uri raw ->
      let host =
        Uri.host uri
        |> Option.map (fun x -> Domain_name.(host_exn (of_string_exn x)))
      in
      Tls_eio.client_of_flow ?host tls_config raw
  in
  let client = Cohttp_eio.Client.make ~https:(Some https) net in
  { base_url; client; sw }

let base_url t = t.base_url

(** {1 Query Parameter Builders} *)

type params = (string * string list) list

let add key value params =
  match value with Some v -> (key, [ v ]) :: params | None -> params

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

let add_int key value params =
  match value with
  | Some v -> (key, [ string_of_int v ]) :: params
  | None -> params

let add_nonneg_int key value params =
  match value with
  | Some v -> (key, [ string_of_int (Nonneg_int.to_int v) ]) :: params
  | None -> params

let add_float key value params =
  match value with
  | Some v -> (key, [ string_of_float v ]) :: params
  | None -> params

let add_string_array key values params =
  match values with
  | Some vs -> List.fold_left (fun acc v -> (key, [ v ]) :: acc) params vs
  | None -> params

(** {1 HTTP Request Functions} *)

let build_uri base_url path params =
  let uri = Uri.of_string (base_url ^ path) in
  Uri.add_query_params uri params

let do_get ?(headers = []) t uri =
  Common.Logger.log_request ~method_:"GET" ~uri;
  try
    let headers = Cohttp.Header.of_list headers in
    let resp, body = Cohttp_eio.Client.get ~sw:t.sw ~headers t.client uri in
    let status = Cohttp.Response.status resp in
    let body_str = Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int in
    Common.Logger.log_response ~method_:"GET" ~uri ~status ~body:body_str;
    (status, body_str)
  with exn ->
    Common.Logger.log_error ~method_:"GET" ~uri ~exn;
    ( `Internal_server_error,
      Printf.sprintf {|{"error": "Request failed: %s"}|}
        (Printexc.to_string exn) )

let do_post ?(headers = []) t uri ~body:request_body =
  Common.Logger.log_request ~method_:"POST" ~uri;
  try
    let all_headers = ("Content-Type", "application/json") :: headers in
    let headers = Cohttp.Header.of_list all_headers in
    let body = Cohttp_eio.Body.of_string request_body in
    let resp, resp_body =
      Cohttp_eio.Client.post ~sw:t.sw ~headers ~body t.client uri
    in
    let status = Cohttp.Response.status resp in
    let body_str =
      Eio.Buf_read.(parse_exn take_all) resp_body ~max_size:max_int
    in
    Common.Logger.log_response ~method_:"POST" ~uri ~status ~body:body_str;
    (status, body_str)
  with exn ->
    Common.Logger.log_error ~method_:"POST" ~uri ~exn;
    ( `Internal_server_error,
      Printf.sprintf {|{"error": "Request failed: %s"}|}
        (Printexc.to_string exn) )

let do_delete ?(headers = []) t uri =
  Common.Logger.log_request ~method_:"DELETE" ~uri;
  try
    let headers = Cohttp.Header.of_list headers in
    let resp, body = Cohttp_eio.Client.delete ~sw:t.sw ~headers t.client uri in
    let status = Cohttp.Response.status resp in
    let body_str = Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int in
    Common.Logger.log_response ~method_:"DELETE" ~uri ~status ~body:body_str;
    (status, body_str)
  with exn ->
    Common.Logger.log_error ~method_:"DELETE" ~uri ~exn;
    ( `Internal_server_error,
      Printf.sprintf {|{"error": "Request failed: %s"}|}
        (Printexc.to_string exn) )

(** {1 JSON Parsing} *)

let parse_json parse_fn body =
  try
    let json = Yojson.Safe.from_string body in
    Ok (parse_fn json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      Error
        (Printf.sprintf
           "JSON parse error: %s\nProblematic value: %s\nFull response:\n%s"
           (Printexc.to_string exn)
           (Yojson.Safe.to_string json)
           body)
  | Yojson.Json_error msg -> Error ("JSON error: " ^ msg ^ "\nBody:\n" ^ body)

let parse_json_list parse_item_fn body =
  try
    let json = Yojson.Safe.from_string body in
    match json with
    | `List items -> Ok (List.map parse_item_fn items)
    | _ -> Error ("Expected JSON array\nBody:\n" ^ body)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      Error
        (Printf.sprintf
           "JSON parse error: %s\nProblematic value: %s\nFull response:\n%s"
           (Printexc.to_string exn)
           (Yojson.Safe.to_string json)
           body)
  | Yojson.Json_error msg -> Error ("JSON error: " ^ msg ^ "\nBody:\n" ^ body)

(** {1 Error Handling} *)

type error_response = { error : string } [@@deriving yojson]

let to_error msg = { error = msg }

let parse_error body =
  try error_response_of_yojson (Yojson.Safe.from_string body)
  with _ -> { error = body }

(** {1 Response Handling} *)

let handle_response status body parse_fn error_parser =
  match Cohttp.Code.code_of_status status with
  | 200 -> parse_fn body
  | _ -> Error (error_parser body)

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
