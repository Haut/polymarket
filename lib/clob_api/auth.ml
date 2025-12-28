(** Authentication for the CLOB API.

    This module re-exports types and header builders from common, and provides
    CLOB-specific HTTP endpoint functions. *)

(* Re-export types and header builders from common *)
include Polymarket_common.Auth

(** {1 Auth Endpoints} *)

let create_api_key client ~private_key ~address ~nonce =
  let headers = build_l1_headers ~private_key ~address ~nonce in
  Polymarket_http.Client.post_json ~headers client "/auth/api-key"
    api_key_response_of_yojson ~body:"{}" []

let derive_api_key client ~private_key ~address ~nonce =
  let headers = build_l1_headers ~private_key ~address ~nonce in
  Polymarket_http.Client.get_json ~headers client "/auth/derive-api-key"
    derive_api_key_response_of_yojson []

let delete_api_key client ~credentials ~address =
  let path = "/auth/api-key" in
  let headers =
    build_l2_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
  in
  let uri =
    Polymarket_http.Client.build_uri
      (Polymarket_http.Client.base_url client)
      path []
  in
  let status, body = Polymarket_http.Client.do_delete ~headers client uri in
  match status with
  | 200 | 204 -> Ok ()
  | _ -> Error (Polymarket_http.Client.parse_error ~status body)

let get_api_keys client ~credentials ~address =
  let path = "/auth/api-keys" in
  let headers =
    build_l2_headers ~credentials ~address ~method_:"GET" ~path ~body:""
  in
  Polymarket_http.Client.get_json_list ~headers client path
    (fun json ->
      match json with
      | `String s -> s
      | _ -> failwith "Expected string in API keys list")
    []
