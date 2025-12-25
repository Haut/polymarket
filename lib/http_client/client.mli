(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client with JSON parsing and query
    parameter building utilities. *)

(** {1 Client Configuration} *)

type t
(** The client type holding connection configuration *)

val create : base_url:string -> sw:Eio.Switch.t -> net:_ Eio.Net.t -> unit -> t
(** Create a new client instance.
    @param base_url The API base URL
    @param sw The Eio switch for resource management
    @param net The Eio network capability *)

val base_url : t -> string
(** Get the base URL of the client *)

(** {1 Query Parameter Builders}

    These functions support pipe-friendly chaining with params as the last
    argument.

    Example:
    {[
      [ ("user", [ user ]) ]
      |> add "market" market |> add_int "limit" limit
      |> add_bool "active" active
    ]} *)

type params = (string * string list) list
(** Query parameters type *)

val add : string -> string option -> params -> params
(** Add an optional string parameter *)

val add_list : string -> ('a -> string) -> 'a list option -> params -> params
(** Add an optional list parameter, joining with commas *)

val add_bool : string -> bool option -> params -> params
(** Add an optional boolean parameter *)

val add_int : string -> int option -> params -> params
(** Add an optional integer parameter *)

val add_float : string -> float option -> params -> params
(** Add an optional float parameter *)

(** {1 HTTP Request Functions} *)

val build_uri : string -> string -> params -> Uri.t
(** Build a URI from base URL, path, and query parameters *)

val do_get :
  ?headers:(string * string) list ->
  t ->
  Uri.t ->
  Cohttp.Code.status_code * string
(** Perform a GET request and return status code and body.
    @param headers Optional list of HTTP headers to include *)

val do_post :
  ?headers:(string * string) list ->
  t ->
  Uri.t ->
  body:string ->
  Cohttp.Code.status_code * string
(** Perform a POST request with JSON body and return status code and body.
    @param headers Optional list of HTTP headers to include *)

val do_delete :
  ?headers:(string * string) list ->
  t ->
  Uri.t ->
  Cohttp.Code.status_code * string
(** Perform a DELETE request and return status code and body.
    @param headers Optional list of HTTP headers to include *)

(** {1 JSON Parsing} *)

val parse_json : (Yojson.Safe.t -> 'a) -> string -> ('a, string) result
(** Parse a JSON response using the provided parser function.
    @return [Ok value] on success, [Error msg] on parse failure *)

val parse_json_list :
  (Yojson.Safe.t -> 'a) -> string -> ('a list, string) result
(** Parse a JSON array response, applying parser to each element.
    @return [Ok list] on success, [Error msg] on parse failure *)

(** {1 Error Handling} *)

type error_response = { error : string }
(** Standard error response type used by Polymarket APIs *)

val to_error : string -> error_response
(** Create an error response from a message *)

val parse_error : string -> error_response
(** Parse an error response from a JSON body, falling back to body as error
    message *)

(** {1 Response Handling} *)

val handle_response :
  Cohttp.Code.status_code ->
  string ->
  (string -> ('a, 'e) result) ->
  (string -> 'e) ->
  ('a, 'e) result
(** Handle HTTP response status and parse body.
    @param status The HTTP status code
    @param body The response body
    @param parse_fn Parser for successful responses
    @param error_parser Parser for error responses
    @return Parsed result or error *)

val request :
  ?headers:(string * string) list ->
  t ->
  string ->
  (string -> ('a, 'e) result) ->
  (string -> 'e) ->
  params ->
  ('a, 'e) result
(** Unified request function for GET requests.
    @param headers Optional list of HTTP headers to include
    @param t The client
    @param path API endpoint path
    @param parse_fn Parser for successful responses
    @param error_parser Parser for error responses
    @param params Query parameters
    @return Parsed result or error *)

(** {1 Convenient JSON Request Helpers}

    These combine request + JSON parsing + standard error handling. *)

val get_json :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  params ->
  ('a, error_response) result
(** GET request expecting a JSON object response.
    @param headers Optional list of HTTP headers to include *)

val get_json_list :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  params ->
  ('a list, error_response) result
(** GET request expecting a JSON array response.
    @param headers Optional list of HTTP headers to include *)

val get_text :
  ?headers:(string * string) list ->
  t ->
  string ->
  params ->
  (string, error_response) result
(** GET request expecting a plain text response.
    @param headers Optional list of HTTP headers to include *)

val post_json :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  body:string ->
  params ->
  ('a, error_response) result
(** POST request with JSON body expecting a JSON object response.
    @param headers Optional list of HTTP headers to include *)

val post_json_list :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  body:string ->
  params ->
  ('a list, error_response) result
(** POST request with JSON body expecting a JSON array response.
    @param headers Optional list of HTTP headers to include *)

val delete_json :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  params ->
  ('a, error_response) result
(** DELETE request expecting a JSON object response.
    @param headers Optional list of HTTP headers to include *)
