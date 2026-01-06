(** Cryptographic utilities for Polymarket API authentication.

    This module provides EIP-712 signing for L1 authentication, HMAC-SHA256
    signing for L2 authentication, and Ethereum address derivation. *)

(** {1 Error Types} *)

type error =
  | Invalid_base64 of string
  | Invalid_private_key
  | Signing_failed
  | Invalid_signature_length of { expected : int; actual : int }
  | Public_key_derivation_failed
  | Invalid_public_key_length of { expected : int; actual : int }
  | Unexpected_error of string
      (** Typed errors for cryptographic operations. *)

val string_of_error : error -> string
(** Convert error to human-readable string. *)

val pp_error : Format.formatter -> error -> unit
(** Pretty-printer for errors. *)

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
  (string, error) result
(** Generate L2 authentication signature. [secret] is base64-encoded. Returns
    [Ok signature] with base64-encoded signature, or [Error e] on failure. *)

(** {1 EIP-712 for L1 Authentication} *)

val sign_clob_auth_message :
  private_key:private_key ->
  address:string ->
  timestamp:string ->
  nonce:int ->
  (string, error) result
(** Sign the CLOB authentication message using EIP-712. Returns [Ok signature]
    with hex signature (0x prefix), or [Error e] on failure. *)

(** {1 Utilities} *)

val private_key_to_address : private_key -> (string, error) result
(** Derive Ethereum address from private key. Returns [Ok address] with
    0x-prefixed address, or [Error e] on failure. *)

val current_timestamp_ms : unit -> string
(** Get current Unix timestamp in milliseconds as string. *)

(** {1 Low-level Signing} *)

val sign_hash : private_key:private_key -> string -> (string, error) result
(** Sign a 32-byte keccak256 hash with a private key.
    @param private_key The signing key
    @param hash_hex The hash as a hex string (no 0x prefix)
    @return
      [Ok signature] with recovery id as 0x-prefixed hex string, or [Error e] on
      failure *)
