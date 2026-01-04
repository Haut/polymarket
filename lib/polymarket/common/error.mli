(** Polymorphic error types for composable error handling.

    This module provides extensible error types using polymorphic variants,
    allowing different parts of the codebase to define their own error cases
    while maintaining composability. *)

(** {1 Base Error Types} *)

type http_error = { status : int; body : string; message : string }
(** HTTP-related errors. *)

type parse_error = { context : string; message : string }
(** JSON parsing errors. *)

type network_error = { message : string }
(** Network/connection errors. *)

type rate_limit_error = { retry_after : float; route_key : string }
(** Rate limiting errors. *)

(** {1 Polymorphic Error Variants} *)

type http_errors =
  [ `Http_error of http_error
  | `Parse_error of parse_error
  | `Network_error of network_error ]
(** Core HTTP client errors. *)

type rate_limit_errors = [ `Rate_limited of rate_limit_error ]
(** Rate limiting errors. *)

type api_errors = [ http_errors | rate_limit_errors ]
(** All API errors (HTTP + rate limiting). *)

(** {1 Error Constructors} *)

val http_error :
  status:int -> body:string -> message:string -> [> `Http_error of http_error ]
(** Construct an HTTP error. *)

val parse_error :
  context:string -> message:string -> [> `Parse_error of parse_error ]
(** Construct a parse error. *)

val network_error : message:string -> [> `Network_error of network_error ]
(** Construct a network error. *)

val rate_limited :
  retry_after:float -> route_key:string -> [> `Rate_limited of rate_limit_error ]
(** Construct a rate limit error. *)

(** {1 Error Formatting} *)

val http_error_to_string : http_error -> string
val parse_error_to_string : parse_error -> string
val network_error_to_string : network_error -> string
val rate_limit_error_to_string : rate_limit_error -> string

val http_errors_to_string : http_errors -> string
(** Convert HTTP errors to string. *)

val api_errors_to_string : api_errors -> string
(** Convert API errors (including rate limiting) to string. *)

(** {1 Pretty Printers} *)

val pp_http_errors : Format.formatter -> http_errors -> unit
val pp_api_errors : Format.formatter -> api_errors -> unit

(** {1 Error Parsing Helpers} *)

val parse_http_error : status:int -> string -> [> `Http_error of http_error ]
(** Parse an HTTP error response body to extract error message. *)

(** {1 Result Helpers} *)

val map_error : ('a -> 'b) -> ('c, 'a) result -> ('c, 'b) result
(** Map over the error type of a result. *)

val lift_http_error : ('a, http_errors) result -> ('a, api_errors) result
(** Lift an http_errors result to an api_errors result. *)
