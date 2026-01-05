(** EIP-712 order signing for CTF Exchange.

    This module provides the cryptographic primitives for signing orders
    compatible with Polymarket's CTF Exchange contract. Used by both CLOB and
    RFQ APIs. *)

(** {1 Internal Helpers} *)

(** Pad hex string to 64 chars (32 bytes) with leading zeros *)
let pad_hex_32 hex =
  let len = String.length hex in
  if len >= 64 then hex else String.make (64 - len) '0' ^ hex

(** Encode uint256 as 32-byte hex *)
let encode_uint256 n =
  let hex = Printf.sprintf "%x" n in
  pad_hex_32 hex

(** {1 Default Values} *)

let default_fee_rate_bps = "0"
let default_nonce = "0"

let default_expiration_float () =
  Unix.gettimeofday () +. Constants.one_year_seconds

let default_expiration_string () =
  Printf.sprintf "%.0f" (default_expiration_float ())

let default_expiration_int () = int_of_float (default_expiration_float ())

(** {1 Salt Generation} *)

let generate_salt () =
  let bytes = Mirage_crypto_rng.generate 8 in
  let n = ref Int64.zero in
  for i = 0 to 7 do
    n := Int64.(logor (shift_left !n 8) (of_int (Char.code bytes.[i])))
  done;
  Int64.(to_string (logand !n max_int))

(** {1 EIP-712 Type Hash} *)

let order_type_hash =
  let type_string =
    "Order(uint256 salt,address maker,address signer,address taker,uint256 \
     tokenId,uint256 makerAmount,uint256 takerAmount,uint256 \
     expiration,uint256 nonce,uint256 feeRateBps,uint8 side,uint8 \
     signatureType)"
  in
  Digestif.KECCAK_256.(to_hex (digest_string type_string))

(** {1 EIP-712 Domain Separator} *)

let ctf_domain_separator =
  let domain_type_hash =
    let type_string =
      "EIP712Domain(string name,string version,uint256 chainId,address \
       verifyingContract)"
    in
    Digestif.KECCAK_256.(to_hex (digest_string type_string))
  in
  let name_hash =
    Digestif.KECCAK_256.(
      to_hex (digest_string Constants.ctf_exchange_domain_name))
  in
  let version_hash =
    Digestif.KECCAK_256.(
      to_hex (digest_string Constants.ctf_exchange_domain_version))
  in
  let chain_id_hex = encode_uint256 Constants.polygon_chain_id in
  let contract_hex = String.sub Constants.ctf_exchange_address 2 40 in
  let contract_padded = pad_hex_32 contract_hex in
  let data =
    domain_type_hash ^ name_hash ^ version_hash ^ chain_id_hex ^ contract_padded
  in
  let bytes = Hex.to_string (`Hex data) in
  Digestif.KECCAK_256.(to_hex (digest_string bytes))

(** {1 Order Signing} *)

let sign_order ~private_key ~salt ~maker ~signer ~taker ~token_id ~maker_amount
    ~taker_amount ~expiration ~nonce ~fee_rate_bps ~side ~signature_type =
  let encode_address addr =
    let hex =
      if String.length addr > 2 && String.sub addr 0 2 = "0x" then
        String.sub addr 2 (String.length addr - 2)
      else addr
    in
    pad_hex_32 hex
  in
  let encode_uint256_str s = encode_uint256 (int_of_string s) in
  let struct_data =
    order_type_hash ^ encode_uint256_str salt ^ encode_address maker
    ^ encode_address signer ^ encode_address taker
    ^ encode_uint256_str token_id
    ^ encode_uint256_str maker_amount
    ^ encode_uint256_str taker_amount
    ^ encode_uint256_str expiration
    ^ encode_uint256_str nonce
    ^ encode_uint256_str fee_rate_bps
    ^ encode_uint256 side
    ^ encode_uint256 signature_type
  in
  let struct_bytes = Hex.to_string (`Hex struct_data) in
  let struct_hash = Digestif.KECCAK_256.(to_hex (digest_string struct_bytes)) in
  let prefix = "\x19\x01" in
  let domain_bytes = Hex.to_string (`Hex ctf_domain_separator) in
  let struct_bytes = Hex.to_string (`Hex struct_hash) in
  let final_data = prefix ^ domain_bytes ^ struct_bytes in
  let final_hash = Digestif.KECCAK_256.(to_hex (digest_string final_data)) in
  Crypto.sign_hash ~private_key final_hash
