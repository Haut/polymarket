(** HTTP client logging with structured key-value format.

    Provides logging for HTTP requests and responses. Uses the "polymarket.http"
    log source.

    {1 Log Format}

    All log messages follow the structured format:
    {[
      [ HTTP_CLIENT ] [ EVENT ] key = "value" key2 = "value2"
    ]}

    Examples:
    - [[HTTP_CLIENT] [REQUEST] method="GET" url="https://..."]
    - [[HTTP_CLIENT] [RESPONSE] method="GET" url="..." status="200"]
    - [[HTTP_CLIENT] [ERROR] method="GET" url="..." error="..."] *)

val src : Logs.Src.t
(** The log source for HTTP client logging. *)

val log_request : method_:string -> uri:Uri.t -> unit
(** Log an outgoing HTTP request. Format:
    [[HTTP_CLIENT] [REQUEST] method="..." url="..."] *)

val log_response :
  method_:string ->
  uri:Uri.t ->
  status:Cohttp.Code.status_code ->
  body:string ->
  unit
(** Log an HTTP response. Format:
    [[HTTP_CLIENT] [RESPONSE] method="..." url="..." status="..."] *)

val log_error : method_:string -> uri:Uri.t -> exn:exn -> unit
(** Log an HTTP request error. Format:
    [[HTTP_CLIENT] [ERROR] method="..." url="..." error="..."] *)

val log_json_fields : context:string -> Yojson.Safe.t -> unit
(** Log JSON field names at debug level. Format:
    [[HTTP_CLIENT] [JSON_FIELDS] context="..." fields="..."] *)

val log_json_fields_with_expected :
  context:string -> expected:string list -> Yojson.Safe.t -> unit
(** Log JSON fields and compare with expected fields. *)
