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
module Auth = Polymarket_common.Auth

type ready
(** Phantom type indicating request is ready to execute *)

type not_ready
(** Phantom type indicating request needs a body before execution *)

type method_ = GET | POST | DELETE

type 'state t = {
  client : C.t;
  method_ : method_;
  path : string;
  params : C.params;
  headers : (string * string) list;
  body : string option;
}
(** Request builder type. ['state] tracks whether request is ready to execute.
*)

(** {1 Request Constructors} *)

let new_get (client : C.t) (path : string) : ready t =
  { client; method_ = GET; path; params = []; headers = []; body = None }

let new_post (client : C.t) (path : string) : not_ready t =
  { client; method_ = POST; path; params = []; headers = []; body = None }

let new_delete (client : C.t) (path : string) : ready t =
  { client; method_ = DELETE; path; params = []; headers = []; body = None }

(** {1 Query Parameter Builders} *)

let query_param (key : string) (value : string) (req : 'a t) : 'a t =
  { req with params = (key, [ value ]) :: req.params }

let query_add (key : string) (value : string option) (req : 'a t) : 'a t =
  match value with
  | Some v -> { req with params = (key, [ v ]) :: req.params }
  | None -> req

let query_option (key : string) (to_string : 'b -> string) (value : 'b option)
    (req : 'a t) : 'a t =
  match value with
  | Some v -> { req with params = (key, [ to_string v ]) :: req.params }
  | None -> req

let query_list (key : string) (to_string : 'b -> string)
    (values : 'b list option) (req : 'a t) : 'a t =
  match values with
  | Some vs when vs <> [] ->
      let joined = String.concat "," (List.map to_string vs) in
      { req with params = (key, [ joined ]) :: req.params }
  | _ -> req

let query_bool (key : string) (value : bool option) (req : 'a t) : 'a t =
  match value with
  | Some true -> { req with params = (key, [ "true" ]) :: req.params }
  | Some false -> { req with params = (key, [ "false" ]) :: req.params }
  | None -> req

let query_each (key : string) (to_string : 'b -> string)
    (values : 'b list option) (req : 'a t) : 'a t =
  match values with
  | Some vs ->
      List.fold_left
        (fun acc v ->
          { acc with params = (key, [ to_string v ]) :: acc.params })
        req vs
  | None -> req

(** {1 Header Builders} *)

let header_add (key : string) (value : string) (req : 'a t) : 'a t =
  { req with headers = (key, value) :: req.headers }

let header_list (hs : (string * string) list) (req : 'a t) : 'a t =
  { req with headers = hs @ req.headers }

(** {1 Auth} *)

let with_l1_auth ~private_key ~address ~nonce (req : 'a t) : 'a t =
  let headers = Auth.build_l1_headers ~private_key ~address ~nonce in
  { req with headers = headers @ req.headers }

let method_to_string = function
  | GET -> "GET"
  | POST -> "POST"
  | DELETE -> "DELETE"

let with_l2_auth ~credentials ~address (req : 'a t) : 'a t =
  let method_ = method_to_string req.method_ in
  let body = Option.value ~default:"" req.body in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_ ~path:req.path ~body
  in
  { req with headers = headers @ req.headers }

(** {1 Body} *)

let with_body (body : string) (req : not_ready t) : ready t =
  { req with body = Some body }

(** {1 Execution} *)

let fetch (req : ready t) : int * string =
  let uri = C.build_uri (C.base_url req.client) req.path req.params in
  match req.method_ with
  | GET -> C.do_get ~headers:req.headers req.client uri
  | DELETE -> C.do_delete ~headers:req.headers req.client uri
  | POST ->
      let body_str = Option.get req.body in
      C.do_post ~headers:req.headers req.client uri ~body:body_str

(** {1 Response Parsers}

    These execute the request and parse the response in one step. *)

let fetch_json (parser : Yojson.Safe.t -> 'a) (req : ready t) :
    ('a, C.error) result =
  let status, body = fetch req in
  C.handle_response status body (fun b ->
      Json.parse parser b |> Result.map_error C.to_error)

let fetch_json_list (parser : Yojson.Safe.t -> 'a) (req : ready t) :
    ('a list, C.error) result =
  let status, body = fetch req in
  C.handle_response status body (fun b ->
      Json.parse_list parser b |> Result.map_error C.to_error)

let fetch_text (req : ready t) : (string, C.error) result =
  let status, body = fetch req in
  C.handle_response status body (fun b -> Ok b)

let fetch_unit (req : ready t) : (unit, C.error) result =
  let status, body = fetch req in
  match status with
  | 200 | 201 | 204 -> Ok ()
  | _ -> Error (C.parse_error ~status body)
