(** EIP-712 order signing for CTF Exchange.

    This module provides the cryptographic primitives for signing orders
    compatible with Polymarket's CTF Exchange contract. Used by both CLOB and
    RFQ APIs. *)

(** {1 Salt Generation} *)

let generate_salt () =
  let n = ref Int64.zero in
  for _ = 1 to 8 do
    n := Int64.(logor (shift_left !n 8) (of_int (Random.int 256)))
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
  let chain_id_hex = Crypto.Private.encode_uint256 Constants.polygon_chain_id in
  let contract_hex = String.sub Constants.ctf_exchange_address 2 40 in
  let contract_padded = Crypto.Private.pad_hex_32 contract_hex in
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
    Crypto.Private.pad_hex_32 hex
  in
  let encode_uint256_str s = Crypto.Private.encode_uint256 (int_of_string s) in
  let struct_data =
    order_type_hash ^ encode_uint256_str salt ^ encode_address maker
    ^ encode_address signer ^ encode_address taker
    ^ encode_uint256_str token_id
    ^ encode_uint256_str maker_amount
    ^ encode_uint256_str taker_amount
    ^ encode_uint256_str expiration
    ^ encode_uint256_str nonce
    ^ encode_uint256_str fee_rate_bps
    ^ Crypto.Private.encode_uint256 side
    ^ Crypto.Private.encode_uint256 signature_type
  in
  let struct_bytes = Hex.to_string (`Hex struct_data) in
  let struct_hash = Digestif.KECCAK_256.(to_hex (digest_string struct_bytes)) in
  let prefix = "\x19\x01" in
  let domain_bytes = Hex.to_string (`Hex ctf_domain_separator) in
  let struct_bytes = Hex.to_string (`Hex struct_hash) in
  let final_data = prefix ^ domain_bytes ^ struct_bytes in
  let final_hash = Digestif.KECCAK_256.(to_hex (digest_string final_data)) in
  let private_key_str = Crypto.private_key_to_string private_key in
  Crypto.Private.sign_hash ~private_key:private_key_str final_hash
