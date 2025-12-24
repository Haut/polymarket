(** Application-level logging utilities.

    This module provides the logging setup function and application-level
    logging functions. Component-specific logging is in each component's Logger
    module:
    - {!Http_client.Logger} - HTTP request/response logging
    - {!Gamma_api.Logger} - Gamma API logging
    - {!Data_api.Logger} - Data API logging

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

(** {1 Application Logging}

    General-purpose logging functions for application output. Uses the
    "polymarket.app" log source. *)

val info : string -> unit
(** Log an info-level message. *)

val debug : string -> unit
(** Log a debug-level message. *)

val warn : string -> unit
(** Log a warning-level message. *)

val err : string -> unit
(** Log an error-level message. *)

val section : string -> unit
(** Print a section header with underline. *)

val ok : string -> string -> unit
(** Log a success message: [ok name msg] prints "[OK] name: msg". *)

val error : string -> string -> unit
(** Log an error message: [error name msg] prints "[ERROR] name: msg". *)

val skip : string -> string -> unit
(** Log a skip message: [skip name msg] prints "[SKIP] name: msg". *)

(** {1 Advanced} *)

val src : Logs.Src.t
(** The log source for application logging. *)
