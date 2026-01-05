(** Cryptographic utilities for Polymarket API authentication.

    This module provides EIP-712 signing for L1 authentication, HMAC-SHA256
    signing for L2 authentication, and Ethereum address derivation. *)

(** {1 Types} *)

type private_key
(** Abstract type for a 32-byte private key (64 hex chars, no 0x prefix). *)

val private_key_of_string : string -> private_key
(** Create a private key from a hex string (64 chars, no 0x prefix). *)

val private_key_to_string : private_key -> string
(** Convert a private key to its hex string representation. *)

(** {1 Hashing} *)

val keccak256 : string -> string
(** Compute keccak256 hash of bytes, returns hex string with 0x prefix. *)

val keccak256_hex : string -> string
(** Compute keccak256 hash of hex-encoded data (no 0x prefix), returns hex
    string with 0x prefix. *)

(** {1 HMAC-SHA256 for L2 Authentication} *)

val hmac_sha256 : key:string -> string -> string
(** HMAC-SHA256 of message with raw key bytes, returns raw bytes. *)

val sign_l2_request :
  secret:string ->
  timestamp:string ->
  method_:string ->
  path:string ->
  body:string ->
  string
(** Generate L2 authentication signature. [secret] is base64-encoded. Returns
    base64-encoded signature. *)

(** {1 EIP-712 for L1 Authentication} *)

val sign_clob_auth_message :
  private_key:private_key ->
  address:string ->
  timestamp:string ->
  nonce:int ->
  string
(** Sign the CLOB authentication message using EIP-712. Returns hex signature
    with 0x prefix. *)

(** {1 Utilities} *)

val private_key_to_address : private_key -> string
(** Derive Ethereum address from private key. Returns 0x-prefixed address. *)

val current_timestamp_ms : unit -> string
(** Get current Unix timestamp in milliseconds as string. *)

(** {1 Low-level Signing} *)

val sign_hash : private_key:private_key -> string -> string
(** Sign a 32-byte keccak256 hash with a private key.
    @param private_key The signing key
    @param hash_hex The hash as a hex string (no 0x prefix)
    @return Signature with recovery id as 0x-prefixed hex string *)
