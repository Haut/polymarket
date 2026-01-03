(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client. Uses cohttp-eio for HTTP
    requests. Use the [Builder] module for type-safe request construction. *)

(** {1 Client Configuration} *)

type t
(** The client type holding connection configuration *)

val create :
  base_url:string ->
  sw:Eio.Switch.t ->
  net:_ Eio.Net.t ->
  rate_limiter:Rate_limiter.t ->
  unit ->
  t
(** Create a new client instance.
    @param base_url The API base URL
    @param sw The Eio switch for resource management
    @param net The Eio network interface
    @param rate_limiter Shared rate limiter for enforcing API limits *)

val base_url : t -> string
(** Get the base URL of the client *)

(** {1 HTTP Request Functions} *)

type params = (string * string list) list
(** Query parameters type *)

val build_uri : string -> string -> params -> Uri.t
(** Build a URI from base URL, path, and query parameters *)

type status_code = int
(** HTTP status code *)

val do_get :
  ?headers:(string * string) list -> t -> Uri.t -> status_code * string
(** Perform a GET request and return status code and body.
    @param headers Optional list of HTTP headers to include *)

val do_post :
  ?headers:(string * string) list ->
  t ->
  Uri.t ->
  body:string ->
  status_code * string
(** Perform a POST request with JSON body and return status code and body.
    @param headers Optional list of HTTP headers to include *)

val do_delete :
  ?headers:(string * string) list -> t -> Uri.t -> status_code * string
(** Perform a DELETE request and return status code and body.
    @param headers Optional list of HTTP headers to include *)

val do_delete_with_body :
  ?headers:(string * string) list ->
  t ->
  Uri.t ->
  body:string ->
  status_code * string
(** Perform a DELETE request with JSON body and return status code and body.
    @param headers Optional list of HTTP headers to include *)

(** {1 Error Handling} *)

type http_error = Primitives.http_error
(** HTTP error with status code, raw body, and extracted message *)

type parse_error = Primitives.parse_error
(** Parse error with context and message *)

type network_error = Primitives.network_error
(** Network-level error (connection failed, timeout, etc.) *)

type error = Primitives.api_error
(** Structured error type for all API errors *)

val error_to_string : error -> string
(** Convert error to human-readable string *)

val pp_error : Format.formatter -> error -> unit
(** Pretty printer for errors *)

type error_response = { error : string }
(** Legacy type alias for backwards compatibility *)

val to_error : string -> error
(** Create a parse error from a message *)

val parse_error : status:int -> string -> error
(** Parse an error response from a JSON body and status code *)

(** {1 Response Handling} *)

val handle_response :
  status_code -> string -> (string -> ('a, error) result) -> ('a, error) result
(** Handle HTTP response status and parse body.
    @param status The HTTP status code
    @param body The response body
    @param parse_fn Parser for successful responses
    @return Parsed result or error *)

(** {1 JSON Field Checking}

    These functions log warnings when API responses contain fields not defined
    in our types. Use with [@@deriving yojson_fields] to generate field lists.
*)

val check_extra_fields :
  expected_fields:string list -> context:string -> Yojson.Safe.t -> unit
(** Check a JSON value for unexpected fields and log warnings.
    @param expected_fields List of field names we expect (from yojson_fields)
    @param context Description for logging (e.g. "Market.t") *)

val parse_with_field_check :
  expected_fields:string list ->
  context:string ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  ('a, error) result
(** Parse JSON with extra field checking for single objects.
    @param expected_fields List of expected field names
    @param context Description for logging
    @param body JSON string to parse
    @param of_yojson Parser function from ppx_yojson_conv *)

val parse_list_with_field_check :
  expected_fields:string list ->
  context:string ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  ('a, error) result
(** Parse JSON with extra field checking for lists of objects.
    @param expected_fields List of expected field names for each item
    @param context Description for logging
    @param body JSON string to parse
    @param of_yojson Parser function from ppx_yojson_conv *)
