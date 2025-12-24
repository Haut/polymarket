(** Logging utilities for Polymarket API clients.

    This module provides structured HTTP request/response logging using the
    OCaml Logs library. Logging is controlled via the POLYMARKET_LOG_LEVEL
    environment variable.

    {1 Usage}

    Call {!setup} once at program startup:

    {[
      let () = Polymarket.Common.Logger.setup ()
      (* rest of your program *)
    ]}

    Set the log level via environment variable:

    {[
      POLYMARKET_LOG_LEVEL=debug ./your_program
    ]}

    Valid levels: debug, info, off (default: off) *)

(** {1 Initialization} *)

val setup : unit -> unit
(** Initialize logging from POLYMARKET_LOG_LEVEL environment variable.

    Valid levels:
    - "debug": Detailed HTTP request/response logging including full bodies
    - "info": Request URLs and response status codes
    - "off": No logging (default)

    This function should be called once at program startup before making any API
    calls. *)

(** {1 HTTP Logging} *)

val log_request : method_:string -> uri:Uri.t -> unit
(** Log an outgoing HTTP request.
    @param method_ HTTP method (e.g., "GET", "POST")
    @param uri Full request URI including query parameters *)

val log_response :
  method_:string ->
  uri:Uri.t ->
  status:Cohttp.Code.status_code ->
  body:string ->
  unit
(** Log an HTTP response.
    @param method_ HTTP method used in the request
    @param uri Request URI
    @param status HTTP status code
    @param body Full response body *)

val log_error : method_:string -> uri:Uri.t -> exn:exn -> unit
(** Log an HTTP request error.
    @param method_ HTTP method used in the request
    @param uri Request URI
    @param exn The exception that occurred *)

(** {1 JSON Field Logging} *)

val log_json_fields : context:string -> Yojson.Safe.t -> unit
(** Log the top-level field names from a JSON object at debug level.
    @param context Description of what's being parsed (e.g., "event", "market")

    This helps identify fields that the API returns which may not be captured in
    our OCaml types. *)

val log_json_fields_with_expected :
  context:string -> expected:string list -> Yojson.Safe.t -> unit
(** Log JSON fields and compare with expected type fields.
    @param context Description of what's being parsed
    @param expected List of field names expected by the OCaml type

    Logs:
    - All fields present in the JSON
    - Extra fields: in JSON but not in expected list (API returns more than we
      capture)
    - Missing fields: in expected but not in JSON (our type expects more than
      API provides) *)

(** {1 Advanced} *)

val src : Logs.Src.t
(** The logs source for Polymarket library. Advanced users can configure custom
    reporters using this source. *)
