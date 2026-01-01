(** Cryptographic utilities for Polymarket API authentication.

    This module provides EIP-712 signing, HMAC-SHA256, and Ethereum address
    derivation for API authentication. *)

type private_key = string

(** {1 Hashing} *)

let keccak256 data =
  let hash = Digestif.KECCAK_256.digest_string data in
  "0x" ^ Digestif.KECCAK_256.to_hex hash

let keccak256_hex hex_str =
  let bytes = Hex.to_string (`Hex hex_str) in
  keccak256 bytes

(** {1 HMAC-SHA256} *)

let hmac_sha256 ~key message =
  Digestif.SHA256.(to_raw_string (hmac_string ~key message))

let sign_l2_request ~secret ~timestamp ~method_ ~path ~body =
  (* Decode base64 secret *)
  let key = Base64.decode_exn secret in
  (* Construct message: timestamp + method + path + body *)
  let message = timestamp ^ method_ ^ path ^ body in
  (* Compute HMAC-SHA256 *)
  let signature = hmac_sha256 ~key message in
  (* Encode result as base64 *)
  Base64.encode_exn signature

(** {1 EIP-712 Helpers} *)

(** Pad hex string to 64 chars (32 bytes) with leading zeros *)
let pad_hex_32 hex =
  let len = String.length hex in
  if len >= 64 then hex else String.make (64 - len) '0' ^ hex

(** Encode uint256 as 32-byte hex *)
let encode_uint256 n =
  let hex = Printf.sprintf "%x" n in
  pad_hex_32 hex

(** EIP-712 type hash for domain: keccak256("EIP712Domain(string name,string
    version,uint256 chainId)") *)
let domain_type_hash =
  let type_string =
    "EIP712Domain(string name,string version,uint256 chainId)"
  in
  let hash = Digestif.KECCAK_256.digest_string type_string in
  Digestif.KECCAK_256.to_hex hash

(** EIP-712 type hash for ClobAuth: keccak256("ClobAuth(address address,string
    timestamp,uint256 nonce,string message)") *)
let clob_auth_type_hash =
  let type_string =
    "ClobAuth(address address,string timestamp,uint256 nonce,string message)"
  in
  let hash = Digestif.KECCAK_256.digest_string type_string in
  Digestif.KECCAK_256.to_hex hash

(** Compute EIP-712 domain separator *)
let compute_domain_separator () =
  (* Encode: typeHash + keccak256(name) + keccak256(version) + chainId *)
  let name_hash =
    Digestif.KECCAK_256.(to_hex (digest_string Constants.clob_domain_name))
  in
  let version_hash =
    Digestif.KECCAK_256.(to_hex (digest_string Constants.clob_domain_version))
  in
  let chain_id_hex = encode_uint256 Constants.polygon_chain_id in
  let data = domain_type_hash ^ name_hash ^ version_hash ^ chain_id_hex in
  let bytes = Hex.to_string (`Hex data) in
  Digestif.KECCAK_256.(to_hex (digest_string bytes))

(** Compute struct hash for ClobAuth message *)
let compute_clob_auth_hash ~address ~timestamp ~nonce =
  (* Remove 0x prefix from address if present *)
  let addr_hex =
    if String.length address > 2 && String.sub address 0 2 = "0x" then
      String.sub address 2 (String.length address - 2)
    else address
  in
  (* Pad address to 32 bytes (left-padded with zeros) *)
  let addr_padded = pad_hex_32 addr_hex in
  (* Hash the string fields *)
  let timestamp_hash = Digestif.KECCAK_256.(to_hex (digest_string timestamp)) in
  let message_hash =
    Digestif.KECCAK_256.(to_hex (digest_string Constants.auth_message_text))
  in
  let nonce_hex = encode_uint256 nonce in
  (* Encode: typeHash + address + keccak256(timestamp) + nonce + keccak256(message) *)
  let data =
    clob_auth_type_hash ^ addr_padded ^ timestamp_hash ^ nonce_hex
    ^ message_hash
  in
  let bytes = Hex.to_string (`Hex data) in
  Digestif.KECCAK_256.(to_hex (digest_string bytes))

(** Compute EIP-712 hash to sign *)
let compute_eip712_hash ~address ~timestamp ~nonce =
  let domain_separator = compute_domain_separator () in
  let struct_hash = compute_clob_auth_hash ~address ~timestamp ~nonce in
  (* Final hash: keccak256("\x19\x01" + domainSeparator + structHash) *)
  let prefix = "\x19\x01" in
  let domain_bytes = Hex.to_string (`Hex domain_separator) in
  let struct_bytes = Hex.to_string (`Hex struct_hash) in
  let data = prefix ^ domain_bytes ^ struct_bytes in
  Digestif.KECCAK_256.(to_hex (digest_string data))

(** {1 Secp256k1 Signing} *)

(** Sign a 32-byte hash with private key, returns signature with recovery id *)
let sign_hash ~private_key hash_hex =
  let open Libsecp256k1.External in
  (* Create signing context *)
  let ctx = Context.create ~sign:true ~verify:true () in
  (* Parse private key (hex string to bytes) *)
  let sk_bytes = Bigstring.of_string (Hex.to_string (`Hex private_key)) in
  let sk = Key.read_sk_exn ctx sk_bytes in
  (* Parse hash (hex string to bytes) *)
  let hash_bytes = Bigstring.of_string (Hex.to_string (`Hex hash_hex)) in
  (* Sign with recoverable signature *)
  let signature = Sign.sign_recoverable_exn ctx ~sk hash_bytes in
  (* Serialize signature (65 bytes: 64 bytes r+s + 1 byte recovery id) *)
  let sig_bytes = Sign.to_bytes ctx signature in
  let sig_str = Bigstring.to_string sig_bytes in
  (* First 64 bytes are r+s, last byte is recovery id *)
  let rs_hex = Hex.of_string (String.sub sig_str 0 64) in
  let recid = Char.code sig_str.[64] in
  let v = recid + 27 in
  let (`Hex rs_str) = rs_hex in
  Printf.sprintf "0x%s%02x" rs_str v

(** {1 Public API} *)

let sign_clob_auth_message ~private_key ~address ~timestamp ~nonce =
  let hash = compute_eip712_hash ~address ~timestamp ~nonce in
  sign_hash ~private_key hash

let private_key_to_address private_key =
  let open Libsecp256k1.External in
  (* Create context *)
  let ctx = Context.create ~sign:true ~verify:true () in
  (* Parse private key *)
  let sk_bytes = Bigstring.of_string (Hex.to_string (`Hex private_key)) in
  let sk = Key.read_sk_exn ctx sk_bytes in
  (* Derive public key *)
  let pk = Key.neuterize_exn ctx sk in
  (* Serialize uncompressed public key (65 bytes: 0x04 + 64 bytes) *)
  let pk_bytes = Key.to_bytes ~compress:false ctx pk in
  let pk_str = Bigstring.to_string pk_bytes in
  (* Take last 64 bytes (skip 0x04 prefix), hash with keccak256, take last 20 bytes *)
  let pk_data = String.sub pk_str 1 64 in
  let hash = Digestif.KECCAK_256.digest_string pk_data in
  let hash_hex = Digestif.KECCAK_256.to_hex hash in
  (* Last 40 chars (20 bytes) of hash = address *)
  "0x" ^ String.sub hash_hex (String.length hash_hex - 40) 40

let current_timestamp_ms () =
  let t = Unix.gettimeofday () in
  Printf.sprintf "%.0f" (t *. 1000.0)
