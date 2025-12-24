(** HTTP client logging.

    Provides logging for HTTP requests and responses. Uses the "polymarket.http"
    log source. *)

val src : Logs.Src.t
(** The log source for HTTP client logging. *)

val log_request : method_:string -> uri:Uri.t -> unit
(** Log an outgoing HTTP request. *)

val log_response :
  method_:string ->
  uri:Uri.t ->
  status:Cohttp.Code.status_code ->
  body:string ->
  unit
(** Log an HTTP response. *)

val log_error : method_:string -> uri:Uri.t -> exn:exn -> unit
(** Log an HTTP request error. *)

val log_json_fields : context:string -> Yojson.Safe.t -> unit
(** Log JSON field names at debug level. *)

val log_json_fields_with_expected :
  context:string -> expected:string list -> Yojson.Safe.t -> unit
(** Log JSON fields and compare with expected fields. *)
