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

let http_error ~status ~body ~message : [> `Http_error of http_error ] =
  `Http_error { status; body; message }

let parse_error ~context ~message : [> `Parse_error of parse_error ] =
  `Parse_error { context; message }

let network_error ~message : [> `Network_error of network_error ] =
  `Network_error { message }

let rate_limited ~retry_after ~route_key : [> `Rate_limited of rate_limit_error ]
    =
  `Rate_limited { retry_after; route_key }

(** {1 Error Formatting} *)

let http_error_to_string { status; message; _ } =
  Printf.sprintf "HTTP %d: %s" status message

let parse_error_to_string { context; message } =
  Printf.sprintf "Parse error in %s: %s" context message

let network_error_to_string { message } =
  Printf.sprintf "Network error: %s" message

let rate_limit_error_to_string { retry_after; route_key } =
  Printf.sprintf "Rate limited on %s, retry after %.2fs" route_key retry_after

(** Convert HTTP errors to string. *)
let http_errors_to_string : http_errors -> string = function
  | `Http_error e -> http_error_to_string e
  | `Parse_error e -> parse_error_to_string e
  | `Network_error e -> network_error_to_string e

(** Convert API errors (including rate limiting) to string. *)
let api_errors_to_string : api_errors -> string = function
  | `Http_error e -> http_error_to_string e
  | `Parse_error e -> parse_error_to_string e
  | `Network_error e -> network_error_to_string e
  | `Rate_limited e -> rate_limit_error_to_string e

(** {1 Pretty Printers} *)

let pp_http_errors fmt e = Format.fprintf fmt "%s" (http_errors_to_string e)
let pp_api_errors fmt e = Format.fprintf fmt "%s" (api_errors_to_string e)

(** {1 Error Parsing Helpers} *)

(** Parse an HTTP error response body to extract error message. *)
let parse_http_error ~status body =
  let message =
    try
      let json = Yojson.Safe.from_string body in
      match json with
      | `Assoc fields -> (
          match List.assoc_opt "error" fields with
          | Some (`String msg) -> msg
          | _ -> body)
      | _ -> body
    with _ -> body
  in
  http_error ~status ~body ~message

(** {1 Result Helpers} *)

(** Map over the error type of a result. *)
let map_error f = function Ok x -> Ok x | Error e -> Error (f e)

(** Lift an http_errors result to an api_errors result. *)
let lift_http_error : ('a, http_errors) result -> ('a, [> http_errors ]) result
    =
 fun r -> map_error (fun e -> (e :> api_errors)) r
