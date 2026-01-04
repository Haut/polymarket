(** Authentication types and header builders for Polymarket APIs.

    This module provides credentials types and functions for building
    authentication headers for L1 (wallet-based) and L2 (API key-based)
    authentication. *)

(** {1 Types} *)

type credentials = {
  api_key : string;
  secret : string;  (** Base64-encoded secret *)
  passphrase : string;
}
(** API credentials for L2 authentication. *)

val pp_credentials : Format.formatter -> credentials -> unit
val show_credentials : credentials -> string
val equal_credentials : credentials -> credentials -> bool

type api_key_response = {
  api_key : string;
  secret : string;
  passphrase : string;
}
(** Response from API key endpoints (create or derive). *)

val api_key_response_of_yojson : Yojson.Safe.t -> api_key_response
val yojson_of_api_key_response : api_key_response -> Yojson.Safe.t
val pp_api_key_response : Format.formatter -> api_key_response -> unit
val show_api_key_response : api_key_response -> string
val equal_api_key_response : api_key_response -> api_key_response -> bool

(** {1 Conversion} *)

val credentials_of_api_key_response : api_key_response -> credentials
(** Convert API key response to credentials. *)

(** {1 L1 Authentication}

    L1 authentication uses EIP-712 signed messages to prove wallet ownership.
    It's used for creating and deriving API credentials. *)

val build_l1_headers :
  private_key:Crypto.private_key ->
  address:string ->
  nonce:int ->
  (string * string) list
(** Build L1 authentication headers for wallet-based endpoints.
    @param private_key The Ethereum private key (hex, without 0x prefix)
    @param address The Ethereum address (hex, with 0x prefix)
    @param nonce A unique nonce for this request *)

(** {1 L2 Authentication}

    L2 authentication uses HMAC-SHA256 to sign requests using API credentials.
    It's used for authenticated trading and account management endpoints. *)

val build_l2_headers :
  credentials:credentials ->
  address:string ->
  method_:string ->
  path:string ->
  body:string ->
  (string * string) list
(** Build L2 authentication headers for API key-authenticated endpoints.
    @param credentials The API credentials (api_key, secret, passphrase)
    @param address The Ethereum address (hex, with 0x prefix)
    @param method_ The HTTP method (GET, POST, DELETE)
    @param path The request path (e.g., "/orders")
    @param body The request body (empty string for GET/DELETE) *)
