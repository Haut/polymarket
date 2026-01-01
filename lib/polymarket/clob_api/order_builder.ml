(** High-level order building helpers for the CLOB API.

    This module provides ergonomic functions for building signed orders with
    proper EIP-712 signatures, amount calculations, and nonce generation. *)

module Crypto = Polymarket_common.Crypto

(** {1 Constants} *)

module Constants = Polymarket_common.Constants

(** Default fee rate in basis points *)
let default_fee_rate_bps = "0"

(** {1 Salt Generation} *)

(** Generate a random salt as a decimal string. Uses 63 bits of randomness,
    which provides sufficient uniqueness for order deduplication (2^63 possible
    values). *)
let generate_salt () =
  let n = ref Int64.zero in
  for _ = 1 to 8 do
    n := Int64.(logor (shift_left !n 8) (of_int (Random.int 256)))
  done;
  (* Mask to positive int64 range *)
  Int64.(to_string (logand !n max_int))

(** {1 Amount Calculations} *)

(** Calculate maker and taker amounts for an order.

    For BUY orders: maker provides USDC, receives CTF tokens
    - makerAmount = price * size (USDC)
    - takerAmount = size (CTF tokens)

    For SELL orders: maker provides CTF tokens, receives USDC
    - makerAmount = size (CTF tokens)
    - takerAmount = price * size (USDC) *)
let calculate_amounts ~side ~price ~size =
  let size_scaled = size *. Constants.token_scale in
  let usdc_amount = price *. size *. Constants.token_scale in
  match side with
  | Types.Side.Buy ->
      let maker_amount = Printf.sprintf "%.0f" usdc_amount in
      let taker_amount = Printf.sprintf "%.0f" size_scaled in
      (maker_amount, taker_amount)
  | Types.Side.Sell ->
      let maker_amount = Printf.sprintf "%.0f" size_scaled in
      let taker_amount = Printf.sprintf "%.0f" usdc_amount in
      (maker_amount, taker_amount)

(** {1 Order Type Hash} *)

(** EIP-712 type hash for CTF Exchange Order *)
let order_type_hash =
  let type_string =
    "Order(uint256 salt,address maker,address signer,address taker,uint256 \
     tokenId,uint256 makerAmount,uint256 takerAmount,uint256 \
     expiration,uint256 nonce,uint256 feeRateBps,uint8 side,uint8 \
     signatureType)"
  in
  let hash = Digestif.KECCAK_256.digest_string type_string in
  Digestif.KECCAK_256.to_hex hash

(** EIP-712 domain separator for CTF Exchange (precomputed from constants) *)
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
  let chain_id_hex = Crypto.encode_uint256 Constants.polygon_chain_id in
  let contract_hex = String.sub Constants.ctf_exchange_address 2 40 in
  let contract_padded = Crypto.pad_hex_32 contract_hex in
  let data =
    domain_type_hash ^ name_hash ^ version_hash ^ chain_id_hex ^ contract_padded
  in
  let bytes = Hex.to_string (`Hex data) in
  Digestif.KECCAK_256.(to_hex (digest_string bytes))

(** {1 Order Signing} *)

(** Sign an order using EIP-712. Returns the signature hex string with 0x
    prefix. *)
let sign_order ~private_key ~salt ~maker ~signer ~taker ~token_id ~maker_amount
    ~taker_amount ~expiration ~nonce ~fee_rate_bps ~side ~signature_type =
  (* Encode all fields as 32-byte hex *)
  let encode_address addr =
    let hex =
      if String.length addr > 2 && String.sub addr 0 2 = "0x" then
        String.sub addr 2 (String.length addr - 2)
      else addr
    in
    Crypto.pad_hex_32 hex
  in
  let encode_uint256_str s = Crypto.encode_uint256 (int_of_string s) in
  let side_int = match side with Types.Side.Buy -> 0 | Types.Side.Sell -> 1 in
  let sig_type_int =
    match signature_type with
    | Types.Signature_type.Eoa -> 0
    | Types.Signature_type.Poly_proxy -> 1
    | Types.Signature_type.Poly_gnosis_safe -> 2
  in
  (* Compute struct hash *)
  let struct_data =
    order_type_hash ^ encode_uint256_str salt ^ encode_address maker
    ^ encode_address signer ^ encode_address taker
    ^ encode_uint256_str token_id
    ^ encode_uint256_str maker_amount
    ^ encode_uint256_str taker_amount
    ^ encode_uint256_str expiration
    ^ encode_uint256_str nonce
    ^ encode_uint256_str fee_rate_bps
    ^ Crypto.encode_uint256 side_int
    ^ Crypto.encode_uint256 sig_type_int
  in
  let struct_bytes = Hex.to_string (`Hex struct_data) in
  let struct_hash = Digestif.KECCAK_256.(to_hex (digest_string struct_bytes)) in
  (* Compute final EIP-712 hash *)
  let prefix = "\x19\x01" in
  let domain_bytes = Hex.to_string (`Hex ctf_domain_separator) in
  let struct_bytes = Hex.to_string (`Hex struct_hash) in
  let final_data = prefix ^ domain_bytes ^ struct_bytes in
  let final_hash = Digestif.KECCAK_256.(to_hex (digest_string final_data)) in
  (* Sign the hash *)
  Crypto.sign_hash ~private_key final_hash

(** {1 Public API} *)

(** Create a signed limit order.

    @param private_key Ethereum private key (64 hex chars, no 0x prefix)
    @param token_id The CTF token ID for the market outcome
    @param side Buy or Sell
    @param price Price per share (0.0 to 1.0)
    @param size Number of shares
    @param expiration Optional Unix timestamp for order expiry (default: 1 year)
    @param nonce Optional nonce for the order (default: 0)
    @param fee_rate_bps Optional fee rate in basis points (default: 0)
    @return A signed order ready for submission *)
let create_limit_order ~private_key ~token_id ~(side : Types.Side.t) ~price
    ~size ?expiration ?nonce ?(fee_rate_bps = default_fee_rate_bps) () =
  (* Derive address from private key *)
  let address = Crypto.private_key_to_address private_key in
  (* Generate salt *)
  let salt = generate_salt () in
  (* Calculate amounts *)
  let maker_amount, taker_amount = calculate_amounts ~side ~price ~size in
  (* Default expiration: 1 year from now *)
  let expiration =
    match expiration with
    | Some e -> e
    | None ->
        let now = Unix.gettimeofday () in
        Printf.sprintf "%.0f" (now +. Constants.one_year_seconds)
  in
  (* Default nonce *)
  let nonce = match nonce with Some n -> string_of_int n | None -> "0" in
  (* Sign the order *)
  let signature =
    sign_order ~private_key ~salt ~maker:address ~signer:address
      ~taker:Constants.zero_address ~token_id ~maker_amount ~taker_amount
      ~expiration ~nonce ~fee_rate_bps ~side
      ~signature_type:Types.Signature_type.Eoa
  in
  (* Build signed order *)
  Types.
    {
      salt = Some salt;
      maker = Some address;
      signer = Some address;
      taker = Some Constants.zero_address;
      token_id = Some token_id;
      maker_amount = Some maker_amount;
      taker_amount = Some taker_amount;
      expiration = Some expiration;
      nonce = Some nonce;
      fee_rate_bps = Some fee_rate_bps;
      side = Some side;
      signature_type = Some Signature_type.Eoa;
      signature = Some signature;
    }

(** Create an order request ready for API submission.

    @param order The signed order
    @param order_type Order type (GTC, GTD, FOK, FAK)
    @return An order request for the create_order endpoint *)
let create_order_request ~order ~order_type =
  Types.
    { order = Some order; owner = order.maker; order_type = Some order_type }
