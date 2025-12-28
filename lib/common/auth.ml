(** Authentication types and header builders for Polymarket APIs.

    This module provides credentials types and functions for building
    authentication headers for L1 (wallet-based) and L2 (API key-based)
    authentication. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Types} *)

type credentials = { api_key : string; secret : string; passphrase : string }
[@@deriving show, eq]

type api_key_response = {
  api_key : string; [@key "apiKey"]
  secret : string;
  passphrase : string;
}
[@@deriving yojson, show, eq]

type derive_api_key_response = {
  api_key : string; [@key "apiKey"]
  secret : string;
  passphrase : string;
}
[@@deriving yojson, show, eq]

(** {1 Conversion} *)

let credentials_of_api_key_response (resp : api_key_response) : credentials =
  { api_key = resp.api_key; secret = resp.secret; passphrase = resp.passphrase }

let credentials_of_derive_response (resp : derive_api_key_response) :
    credentials =
  { api_key = resp.api_key; secret = resp.secret; passphrase = resp.passphrase }

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

let build_l2_headers ~(credentials : credentials) ~address ~method_ ~path ~body
    =
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
