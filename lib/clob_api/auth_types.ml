(** Authentication types for the CLOB API. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Credentials} *)

type credentials = { api_key : string; secret : string; passphrase : string }
[@@deriving show, eq]

(** {1 API Key Creation} *)

type api_key_response = {
  api_key : string; [@key "apiKey"]
  secret : string;
  passphrase : string;
}
[@@deriving yojson, show, eq]

(** {1 API Key Derivation} *)

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
