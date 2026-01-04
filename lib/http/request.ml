(** Type-safe request builder with phantom types.

    This module provides a builder pattern for HTTP requests with compile-time
    enforcement of:
    - POST requires a body before execution
    - GET/DELETE are ready to execute immediately

    Example usage:
    {[
      (* GET request - returns parsed JSON list *)
      new_get client "/positions"
      |> query_param "user" user
      |> query_option "limit" string_of_int limit
      |> fetch_json_list position_of_yojson

      (* POST with body *)
      new_post client "/order"
      |> header_list auth_headers
      |> with_body body
      |> fetch_json order_of_yojson

      (* Raw execution for custom handling *)
      new_get client "/health"
      |> fetch
      |> fun (status, body) -> ...
    ]} *)

module C = Client

type ready
(** Phantom type indicating request is ready to execute *)

type not_ready
(** Phantom type indicating request needs a body before execution *)

type method_ = GET | POST | DELETE | DELETE_WITH_BODY

type 'state t = {
  client : Client.t;
  method_ : method_;
  path : string;
  params : C.params;
  headers : (string * string) list;
  body : string option;
}
(** Request builder type. ['state] tracks whether request is ready to execute.
*)

(** {1 Request Constructors} *)

let new_get (client : Client.t) (path : string) : ready t =
  { client; method_ = GET; path; params = []; headers = []; body = None }

let new_post (client : Client.t) (path : string) : not_ready t =
  { client; method_ = POST; path; params = []; headers = []; body = None }

let new_delete (client : Client.t) (path : string) : ready t =
  { client; method_ = DELETE; path; params = []; headers = []; body = None }

let new_delete_with_body (client : Client.t) (path : string) : not_ready t =
  {
    client;
    method_ = DELETE_WITH_BODY;
    path;
    params = [];
    headers = [];
    body = None;
  }

(** {1 Query Parameter Builders} *)

let add_param (key : string) (value : string) (req : 'a t) : 'a t =
  { req with params = (key, [ value ]) :: req.params }

let query_param (key : string) (value : string) (req : 'a t) : 'a t =
  add_param key value req

let query_option (key : string) (to_string : 'b -> string) (value : 'b option)
    (req : 'a t) : 'a t =
  match value with Some v -> add_param key (to_string v) req | None -> req

let query_add (key : string) (value : string option) (req : 'a t) : 'a t =
  query_option key Fun.id value req

let query_bool (key : string) (value : bool option) (req : 'a t) : 'a t =
  query_option key string_of_bool value req

let query_list (key : string) (to_string : 'b -> string)
    (values : 'b list option) (req : 'a t) : 'a t =
  match values with
  | Some (_ :: _ as vs) ->
      add_param key (String.concat "," (List.map to_string vs)) req
  | _ -> req

let query_each (key : string) (to_string : 'b -> string)
    (values : 'b list option) (req : 'a t) : 'a t =
  match values with
  | Some vs ->
      List.fold_left (fun acc v -> add_param key (to_string v) acc) req vs
  | None -> req

(** {1 Header Builders} *)

let header_add (key : string) (value : string) (req : 'a t) : 'a t =
  { req with headers = (key, value) :: req.headers }

let header_list (hs : (string * string) list) (req : 'a t) : 'a t =
  { req with headers = hs @ req.headers }

(** {1 Request Accessors} *)

let method_string (req : 'a t) : string =
  match req.method_ with
  | GET -> "GET"
  | POST -> "POST"
  | DELETE | DELETE_WITH_BODY -> "DELETE"

let path (req : 'a t) : string = req.path
let body_opt (req : 'a t) : string option = req.body

(** {1 Body} *)

let with_body (body : string) (req : not_ready t) : ready t =
  { req with body = Some body }

(** {1 Execution} *)

let fetch (req : ready t) : int * string =
  let uri = Client.build_uri (C.base_url req.client) req.path req.params in
  match req.method_ with
  | GET -> C.do_get ~headers:req.headers req.client uri
  | DELETE -> C.do_delete ~headers:req.headers req.client uri
  | POST ->
      let body_str = Option.get req.body in
      C.do_post ~headers:req.headers req.client uri ~body:body_str
  | DELETE_WITH_BODY ->
      let body_str = Option.get req.body in
      C.do_delete_with_body ~headers:req.headers req.client uri ~body:body_str

(** {1 Response Parsers}

    These execute the request and parse the response in one step. *)

let fetch_json ?(expected_fields : string list option) ?(context : string = "")
    (parser : Yojson.Safe.t -> 'a) (req : ready t) : ('a, C.error) result =
  let status, body = fetch req in
  C.handle_response status body (fun b ->
      match expected_fields with
      | Some fields ->
          C.parse_with_field_check ~expected_fields:fields ~context b parser
      | None -> Json.parse parser b |> Result.map_error Client.to_error)

let fetch_json_list ?(expected_fields : string list option)
    ?(context : string = "") (parser : Yojson.Safe.t -> 'a) (req : ready t) :
    ('a list, C.error) result =
  let status, body = fetch req in
  C.handle_response status body (fun b ->
      match expected_fields with
      | Some fields ->
          C.parse_list_with_field_check ~expected_fields:fields ~context b
            (Ppx_yojson_conv_lib.Yojson_conv.list_of_yojson parser)
      | None -> Json.parse_list parser b |> Result.map_error Client.to_error)

let fetch_text (req : ready t) : (string, C.error) result =
  let status, body = fetch req in
  C.handle_response status body (fun b -> Ok b)

let fetch_unit (req : ready t) : (unit, C.error) result =
  let status, body = fetch req in
  match status with
  | 200 | 201 | 204 -> Ok ()
  | _ -> Error (C.parse_error ~status body)
