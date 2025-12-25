(** Authentication for the CLOB API.

    This module handles both L1 (wallet-based) and L2 (API key-based)
    authentication for the Polymarket CLOB API. *)

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
  credentials:Auth_types.credentials ->
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

(** {1 Auth Endpoints} *)

val create_api_key :
  Http_client.Client.t ->
  private_key:Crypto.private_key ->
  address:string ->
  nonce:int ->
  (Auth_types.api_key_response, Http_client.Client.error_response) result
(** Create a new API key using L1 authentication.
    @param private_key The Ethereum private key (hex, without 0x prefix)
    @param address The Ethereum address (hex, with 0x prefix)
    @param nonce A unique nonce for this request *)

val derive_api_key :
  Http_client.Client.t ->
  private_key:Crypto.private_key ->
  address:string ->
  nonce:int ->
  (Auth_types.derive_api_key_response, Http_client.Client.error_response) result
(** Derive API key from existing credentials using L1 authentication. Unlike
    create_api_key, this returns the same key for the same nonce.
    @param private_key The Ethereum private key (hex, without 0x prefix)
    @param address The Ethereum address (hex, with 0x prefix)
    @param nonce A unique nonce for this request *)

val delete_api_key :
  Http_client.Client.t ->
  credentials:Auth_types.credentials ->
  address:string ->
  (unit, Http_client.Client.error_response) result
(** Delete an API key using L2 authentication.
    @param credentials The API credentials to delete
    @param address The Ethereum address (hex, with 0x prefix) *)

val get_api_keys :
  Http_client.Client.t ->
  credentials:Auth_types.credentials ->
  address:string ->
  (string list, Http_client.Client.error_response) result
(** Get all API keys for the account using L2 authentication.
    @param credentials The API credentials
    @param address The Ethereum address (hex, with 0x prefix)
    @return List of API key strings *)
