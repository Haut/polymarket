(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client with JSON parsing and query
    parameter building utilities. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

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

let add_float key value params =
  match value with
  | Some v -> (key, [ string_of_float v ]) :: params
  | None -> params

(** {1 HTTP Request Functions} *)

let build_uri base_url path params =
  let uri = Uri.of_string (base_url ^ path) in
  Uri.add_query_params uri params

let do_get t uri =
  try
    let resp, body = Cohttp_eio.Client.get ~sw:t.sw t.client uri in
    let status = Cohttp.Response.status resp in
    let body_str = Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int in
    (status, body_str)
  with exn ->
    ( `Internal_server_error,
      Printf.sprintf {|{"error": "Request failed: %s"}|}
        (Printexc.to_string exn) )

(** {1 JSON Parsing} *)

let truncate_json json =
  let s = Yojson.Safe.to_string json in
  if String.length s > 200 then String.sub s 0 200 ^ "..." else s

let parse_json parse_fn body =
  try
    let json = Yojson.Safe.from_string body in
    Ok (parse_fn json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      Error
        (Printf.sprintf "JSON parse error: %s\nProblematic JSON: %s"
           (Printexc.to_string exn) (truncate_json json))
  | Yojson.Json_error msg -> Error ("JSON error: " ^ msg)

let parse_json_list parse_item_fn body =
  try
    let json = Yojson.Safe.from_string body in
    match json with
    | `List items -> Ok (List.map parse_item_fn items)
    | _ -> Error "Expected JSON array"
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      Error
        (Printf.sprintf "JSON parse error: %s\nProblematic JSON: %s"
           (Printexc.to_string exn) (truncate_json json))
  | Yojson.Json_error msg -> Error ("JSON error: " ^ msg)

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

let request t path parse_fn error_parser params =
  let uri = build_uri t.base_url path params in
  let status, body = do_get t uri in
  handle_response status body parse_fn error_parser

(** {1 Convenient JSON Request Helpers} *)

let get_json t path parser params =
  request t path
    (fun body -> parse_json parser body |> Result.map_error to_error)
    parse_error params

let get_json_list t path parser params =
  request t path
    (fun body -> parse_json_list parser body |> Result.map_error to_error)
    parse_error params

let get_text t path params =
  request t path (fun body -> Ok body) parse_error params
