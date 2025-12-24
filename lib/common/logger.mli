(** Structured logging utilities.

    This module provides setup and structured logging functions that all
    components use.

    {1 Log Format}

    All log messages follow the structured format:
    {[
      [ SECTION ] [ EVENT ] key = "value" key2 = "value2"
    ]}

    Examples:
    - [[HTTP_CLIENT] [REQUEST] method="GET" url="https://..."]
    - [[HTTP_CLIENT] [RESPONSE] method="GET" url="..." status="200"]
    - [[DATA_API] [CALL] endpoint="/positions" user="0x..."]

    {1 Usage}

    Call {!setup} once at program startup:

    {[
      let () = Polymarket.Common.Logger.setup ()
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
    - "debug": Detailed logging including HTTP response bodies
    - "info": Request URLs and response status codes
    - "off": No logging (default)

    This sets the global log level that applies to all log sources. *)

(** {1 Structured Logging}

    General-purpose logging functions that take section, event, and key-value
    pairs. *)

val log_info : section:string -> event:string -> (string * string) list -> unit
(** Log at info level. Example:
    [log_info ~section:"HTTP_CLIENT" ~event:"REQUEST" [("method", "GET");
     ("url", "...")]] *)

val log_debug : section:string -> event:string -> (string * string) list -> unit
(** Log at debug level. *)

val log_warn : section:string -> event:string -> (string * string) list -> unit
(** Log at warning level. *)

val log_err : section:string -> event:string -> (string * string) list -> unit
(** Log at error level. *)

(** {1 Formatting Helpers} *)

val format_kv : string * string -> string
(** Format a single key-value pair as [key="value"]. *)

val format_kvs : (string * string) list -> string
(** Format a list of key-value pairs as [key1="value1" key2="value2" ...]. *)

(** {1 HTTP Logging} *)

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

(** {1 JSON Field Logging} *)

val log_json_fields : context:string -> Yojson.Safe.t -> unit
(** Log JSON field names at debug level. Format:
    [[HTTP_CLIENT] [JSON_FIELDS] context="..." fields="..."] *)

val log_json_fields_with_expected :
  context:string -> expected:string list -> Yojson.Safe.t -> unit
(** Log JSON fields and compare with expected fields. *)

(** {1 Advanced} *)

val src : Logs.Src.t
(** The log source for the Polymarket library. *)
