(** Generic HTTP client for Polymarket APIs.

    This module provides a reusable HTTP client with JSON parsing and query
    parameter building utilities. *)

(** {1 Client Configuration} *)

type t
(** The client type holding connection configuration *)

val create :
  base_url:string ->
  sw:Eio.Switch.t ->
  net:_ Eio.Net.t ->
  rate_limiter:Polymarket_rate_limiter.Rate_limiter.t ->
  unit ->
  t
(** Create a new client instance.
    @param base_url The API base URL
    @param sw The Eio switch for resource management
    @param net The Eio network interface
    @param rate_limiter Shared rate limiter for enforcing API limits *)

val base_url : t -> string
(** Get the base URL of the client *)

(** {1 Query Parameter Builders}

    These functions support pipe-friendly chaining with params as the last
    argument. Callers are responsible for converting values to strings.

    Example:
    {[
      [ ("user", [ user ]) ]
      |> add "market" market
      |> add "limit" (Option.map string_of_int limit)
      |> add_bool "active" active
    ]} *)

type params = (string * string list) list
(** Query parameters type *)

val add : string -> string option -> params -> params
(** Add an optional string parameter *)

val add_option : string -> ('a -> string) -> 'a option -> params -> params
(** Add an optional parameter with a converter function.
    {[
      add_option "limit" string_of_int limit params add_option "timestamp"
        Timestamp.to_string ts params
    ]} *)

val add_list : string -> ('a -> string) -> 'a list option -> params -> params
(** Add an optional list parameter, joining with commas.
    {[
      add_list "market" Hash64.to_string market params
    ]} *)

val add_bool : string -> bool option -> params -> params
(** Add an optional boolean parameter (renders as "true"/"false") *)

val add_each : string -> ('a -> string) -> 'a list option -> params -> params
(** Add each value as a separate query parameter with the same key. For example,
    [add_each "id" string_of_int (Some [1; 2])] produces [?id=1&id=2] *)

(** {1 HTTP Request Functions} *)

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

(** {1 JSON Parsing} *)

val parse_json : (Yojson.Safe.t -> 'a) -> string -> ('a, string) result
(** Parse a JSON response using the provided parser function.
    @return [Ok value] on success, [Error msg] on parse failure *)

val parse_json_list :
  (Yojson.Safe.t -> 'a) -> string -> ('a list, string) result
(** Parse a JSON array response, applying parser to each element.
    @return [Ok list] on success, [Error msg] on parse failure *)

(** {1 Error Handling} *)

type http_error = { status : int; body : string; message : string }
(** HTTP error with status code, raw body, and extracted message *)

type parse_error = { context : string; message : string }
(** Parse error with context and message *)

type network_error = { message : string }
(** Network-level error (connection failed, timeout, etc.) *)

type error =
  | Http_error of http_error
  | Parse_error of parse_error
  | Network_error of network_error
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

val request :
  ?headers:(string * string) list ->
  t ->
  string ->
  (string -> ('a, error) result) ->
  params ->
  ('a, error) result
(** Unified request function for GET requests.
    @param headers Optional list of HTTP headers to include
    @param t The client
    @param path API endpoint path
    @param parse_fn Parser for successful responses
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
  ('a, error) result
(** GET request expecting a JSON object response.
    @param headers Optional list of HTTP headers to include *)

val get_json_list :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  params ->
  ('a list, error) result
(** GET request expecting a JSON array response.
    @param headers Optional list of HTTP headers to include *)

val get_text :
  ?headers:(string * string) list ->
  t ->
  string ->
  params ->
  (string, error) result
(** GET request expecting a plain text response.
    @param headers Optional list of HTTP headers to include *)

val post_json :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  body:string ->
  params ->
  ('a, error) result
(** POST request with JSON body expecting a JSON object response.
    @param headers Optional list of HTTP headers to include *)

val post_json_list :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  body:string ->
  params ->
  ('a list, error) result
(** POST request with JSON body expecting a JSON array response.
    @param headers Optional list of HTTP headers to include *)

val delete_json :
  ?headers:(string * string) list ->
  t ->
  string ->
  (Yojson.Safe.t -> 'a) ->
  params ->
  ('a, error) result
(** DELETE request expecting a JSON object response.
    @param headers Optional list of HTTP headers to include *)

val delete_unit :
  ?headers:(string * string) list ->
  t ->
  string ->
  params ->
  (unit, error) result
(** DELETE request expecting no content (handles 200/204).
    @param headers Optional list of HTTP headers to include *)

val post_unit :
  ?headers:(string * string) list ->
  t ->
  string ->
  body:string ->
  params ->
  (unit, error) result
(** POST request expecting no content (handles 200/201/204).
    @param headers Optional list of HTTP headers to include *)

(** {1 JSON Body Builders} *)

val json_body : Yojson.Safe.t -> string
(** Convert JSON to string body *)

val json_obj : (string * Yojson.Safe.t) list -> Yojson.Safe.t
(** Build JSON object from field list *)

val json_string : string -> Yojson.Safe.t
(** Wrap string as JSON string *)

val json_list_body : ('a -> Yojson.Safe.t) -> 'a list -> string
(** Map items to JSON and serialize as array *)

val json_list_single_field : string -> string list -> string
(** Build JSON array of single-field objects.
    [json_list_single_field "token_id" ids] produces
    [[{"token_id": "id1"}, {"token_id": "id2"}, ...]] *)
