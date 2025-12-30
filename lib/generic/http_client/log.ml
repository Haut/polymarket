(** HTTP client logging. *)

include Logger.Make (struct
  let name = "http"
  let doc = "HTTP client"
end)

let section = "HTTP_CLIENT"

let log_request ~method_ ~uri =
  let url = Uri.to_string uri in
  log_info ~section ~event:"REQUEST" [ ("method", method_); ("url", url) ]

let log_response ~method_ ~uri ~status ~body =
  let url = Uri.to_string uri in
  let status_code = match status with `Code c -> string_of_int c in
  log_info ~section ~event:"RESPONSE"
    [ ("method", method_); ("url", url); ("status", status_code) ];
  log_debug ~section ~event:"BODY" [ ("body", body) ]

let log_error ~method_ ~uri ~exn =
  let url = Uri.to_string uri in
  let error = Printexc.to_string exn in
  log_err ~section ~event:"ERROR"
    [ ("method", method_); ("url", url); ("error", error) ]
