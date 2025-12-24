(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client with JSON parsing
    and query parameter building utilities. *)

(** {1 Client Configuration} *)

(** The client type holding connection configuration *)
type t

(** Create a new client instance.
    @param base_url The API base URL
    @param sw The Eio switch for resource management
    @param net The Eio network capability *)
val create :
  base_url:string ->
  sw:Eio.Switch.t ->
  net:_ Eio.Net.t ->
  unit ->
  t

(** Get the base URL of the client *)
val base_url : t -> string

(** {1 Query Parameter Builders}

    These functions support pipe-friendly chaining with params as the last argument.

    Example:
    {[
      [("user", [user])]
      |> add "market" market
      |> add_int "limit" limit
      |> add_bool "active" active
    ]}
*)

(** Query parameters type *)
type params = (string * string list) list

(** Add an optional string parameter *)
val add : string -> string option -> params -> params

(** Add an optional list parameter, joining with commas *)
val add_list : string -> ('a -> string) -> 'a list option -> params -> params

(** Add an optional boolean parameter *)
val add_bool : string -> bool option -> params -> params

(** Add an optional integer parameter *)
val add_int : string -> int option -> params -> params

(** Add an optional float parameter *)
val add_float : string -> float option -> params -> params

(** {1 HTTP Request Functions} *)

(** Build a URI from base URL, path, and query parameters *)
val build_uri : string -> string -> params -> Uri.t

(** Perform a GET request and return status code and body *)
val do_get : t -> Uri.t -> Cohttp.Code.status_code * string

(** {1 JSON Parsing} *)

(** Parse a JSON response using the provided parser function.
    @return [Ok value] on success, [Error msg] on parse failure *)
val parse_json :
  (Yojson.Safe.t -> 'a) ->
  string ->
  ('a, string) result

(** Parse a JSON array response, applying parser to each element.
    @return [Ok list] on success, [Error msg] on parse failure *)
val parse_json_list :
  (Yojson.Safe.t -> 'a) ->
  string ->
  ('a list, string) result

(** {1 Response Handling} *)

(** Handle HTTP response status and parse body.
    @param status The HTTP status code
    @param body The response body
    @param parse_fn Parser for successful responses
    @param error_parser Parser for error responses
    @return Parsed result or error *)
val handle_response :
  Cohttp.Code.status_code ->
  string ->
  (string -> ('a, 'e) result) ->
  (string -> 'e) ->
  ('a, 'e) result

(** Unified request function for GET requests.
    @param t The client
    @param path API endpoint path
    @param parse_fn Parser for successful responses
    @param error_parser Parser for error responses
    @param params Query parameters
    @return Parsed result or error *)
val request :
  t ->
  string ->
  (string -> ('a, 'e) result) ->
  (string -> 'e) ->
  params ->
  ('a, 'e) result
