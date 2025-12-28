(** Authentication for the CLOB API.

    This module re-exports types and header builders from common, and provides
    CLOB-specific HTTP endpoint functions. *)

(* Re-export types and header builders from common *)
include module type of Polymarket_common.Auth

(** {1 Auth Endpoints} *)

val create_api_key :
  Polymarket_http.Client.t ->
  private_key:Crypto.private_key ->
  address:string ->
  nonce:int ->
  (api_key_response, Polymarket_http.Client.error) result
(** Create a new API key using L1 authentication.
    @param private_key The Ethereum private key (hex, without 0x prefix)
    @param address The Ethereum address (hex, with 0x prefix)
    @param nonce A unique nonce for this request *)

val derive_api_key :
  Polymarket_http.Client.t ->
  private_key:Crypto.private_key ->
  address:string ->
  nonce:int ->
  (derive_api_key_response, Polymarket_http.Client.error) result
(** Derive API key from existing credentials using L1 authentication. Unlike
    create_api_key, this returns the same key for the same nonce.
    @param private_key The Ethereum private key (hex, without 0x prefix)
    @param address The Ethereum address (hex, with 0x prefix)
    @param nonce A unique nonce for this request *)

val delete_api_key :
  Polymarket_http.Client.t ->
  credentials:credentials ->
  address:string ->
  (unit, Polymarket_http.Client.error) result
(** Delete an API key using L2 authentication.
    @param credentials The API credentials to delete
    @param address The Ethereum address (hex, with 0x prefix) *)

val get_api_keys :
  Polymarket_http.Client.t ->
  credentials:credentials ->
  address:string ->
  (string list, Polymarket_http.Client.error) result
(** Get all API keys for the account using L2 authentication.
    @param credentials The API credentials
    @param address The Ethereum address (hex, with 0x prefix)
    @return List of API key strings *)
