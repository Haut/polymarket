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

type ready
(** Phantom type indicating request is ready to execute *)

type not_ready
(** Phantom type indicating request needs a body before execution *)

type 'state t
(** Request builder type. ['state] tracks whether request is ready to execute
    (either [ready] or [not_ready]). *)

(** {1 Request Constructors} *)

val new_get : Http_client.t -> string -> ready t
(** Create a GET request. Ready to execute immediately. *)

val new_post : Http_client.t -> string -> not_ready t
(** Create a POST request. Requires [with_body] before execution. *)

val new_delete : Http_client.t -> string -> ready t
(** Create a DELETE request. Ready to execute immediately. *)

val new_delete_with_body : Http_client.t -> string -> not_ready t
(** Create a DELETE request with body. Requires [with_body] before execution.
    Used for APIs that require a JSON body in DELETE requests. *)

(** {1 Query Parameter Builders} *)

val query_param : string -> string -> 'a t -> 'a t
(** Add a required string parameter. *)

val query_add : string -> string option -> 'a t -> 'a t
(** Add an optional string parameter. *)

val query_option : string -> ('b -> string) -> 'b option -> 'a t -> 'a t
(** Add an optional parameter with a converter function. *)

val query_list : string -> ('b -> string) -> 'b list option -> 'a t -> 'a t
(** Add an optional list parameter, joining values with commas. *)

val query_bool : string -> bool option -> 'a t -> 'a t
(** Add an optional boolean parameter (renders as "true"/"false"). *)

val query_each : string -> ('b -> string) -> 'b list option -> 'a t -> 'a t
(** Add each value as a separate query parameter with the same key.
    [query_each "id" string_of_int (Some [1; 2])] produces [?id=1&id=2] *)

(** {1 Header Builders} *)

val header_add : string -> string -> 'a t -> 'a t
(** Add a single header. *)

val header_list : (string * string) list -> 'a t -> 'a t
(** Add multiple headers. *)

(** {1 Auth} *)

val with_l1_auth :
  private_key:Crypto.private_key -> address:string -> nonce:int -> 'a t -> 'a t
(** Add L1 authentication headers for wallet-based endpoints. *)

val with_l2_auth :
  credentials:Auth.credentials -> address:string -> 'a t -> 'a t
(** Add L2 authentication headers. Computes headers from the request's method,
    path, and body. Must be called after [with_body] for POST requests. *)

(** {1 Body} *)

val with_body : string -> not_ready t -> ready t
(** Add a request body. Changes state from [not_ready] to [ready]. *)

(** {1 Execution} *)

val fetch : ready t -> int * string
(** Execute the request and return raw (status, body). Use this for custom
    response handling. *)

(** {1 Response Parsers}

    These execute the request and parse the response in one step.

    Pass [~expected_fields] (from [@@deriving yojson_fields]) to log warnings
    when the API returns fields not in our types. *)

val fetch_json :
  ?expected_fields:string list ->
  ?context:string ->
  (Yojson.Safe.t -> 'a) ->
  ready t ->
  ('a, Http_client.error) result
(** Execute and parse response as JSON object.
    @param expected_fields If provided, logs warning for unknown fields
    @param context Description for logging (e.g. "Market.t") *)

val fetch_json_list :
  ?expected_fields:string list ->
  ?context:string ->
  (Yojson.Safe.t -> 'a) ->
  ready t ->
  ('a list, Http_client.error) result
(** Execute and parse response as JSON array.
    @param expected_fields If provided, logs warning for unknown fields in items
    @param context Description for logging *)

val fetch_text : ready t -> (string, Http_client.error) result
(** Execute and return response body as string. *)

val fetch_unit : ready t -> (unit, Http_client.error) result
(** Execute and discard response body. Succeeds on 200/201/204. *)
