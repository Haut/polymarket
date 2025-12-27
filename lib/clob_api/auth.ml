(** Authentication for the CLOB API.

    This module handles both L1 (wallet-based) and L2 (API key-based)
    authentication for the Polymarket CLOB API. *)

(** {1 Header Names} *)

let poly_address = "POLY_ADDRESS"
let poly_signature = "POLY_SIGNATURE"
let poly_timestamp = "POLY_TIMESTAMP"
let poly_nonce = "POLY_NONCE"
let poly_api_key = "POLY_API_KEY"
let poly_passphrase = "POLY_PASSPHRASE"

(** {1 L1 Authentication} *)

let build_l1_headers ~private_key ~address ~nonce =
  let timestamp = Crypto.current_timestamp_ms () in
  let signature =
    Crypto.sign_clob_auth_message ~private_key ~address ~timestamp ~nonce
  in
  [
    (poly_address, address);
    (poly_signature, signature);
    (poly_timestamp, timestamp);
    (poly_nonce, string_of_int nonce);
  ]

(** {1 L2 Authentication} *)

let build_l2_headers ~(credentials : Auth_types.credentials) ~address ~method_
    ~path ~body =
  let timestamp = Crypto.current_timestamp_ms () in
  let signature =
    Crypto.sign_l2_request ~secret:credentials.secret ~timestamp ~method_ ~path
      ~body
  in
  [
    (poly_address, address);
    (poly_signature, signature);
    (poly_timestamp, timestamp);
    (poly_api_key, credentials.api_key);
    (poly_passphrase, credentials.passphrase);
  ]

(** {1 Auth Endpoints} *)

let create_api_key client ~private_key ~address ~nonce =
  let headers = build_l1_headers ~private_key ~address ~nonce in
  Polymarket_http.Client.post_json ~headers client "/auth/api-key"
    Auth_types.api_key_response_of_yojson ~body:"{}" []

let derive_api_key client ~private_key ~address ~nonce =
  let headers = build_l1_headers ~private_key ~address ~nonce in
  Polymarket_http.Client.get_json ~headers client "/auth/derive-api-key"
    Auth_types.derive_api_key_response_of_yojson []

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
  | _ -> Error (Polymarket_http.Client.parse_error body)

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
