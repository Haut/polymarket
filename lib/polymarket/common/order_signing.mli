(** EIP-712 order signing for CTF Exchange.

    This module provides the cryptographic primitives for signing orders
    compatible with Polymarket's CTF Exchange contract. Used by both CLOB and
    RFQ APIs. *)

val generate_salt : unit -> string
(** Generate a random salt as a decimal string. Uses 63 bits of randomness. *)

val order_type_hash : string
(** EIP-712 type hash for CTF Exchange Order struct. *)

val ctf_domain_separator : string
(** EIP-712 domain separator for CTF Exchange (Polygon mainnet). *)

val sign_order :
  private_key:Crypto.private_key ->
  salt:string ->
  maker:string ->
  signer:string ->
  taker:string ->
  token_id:string ->
  maker_amount:string ->
  taker_amount:string ->
  expiration:string ->
  nonce:string ->
  fee_rate_bps:string ->
  side:int ->
  signature_type:int ->
  string
(** Sign an order using EIP-712.

    @param private_key Ethereum private key
    @param salt Order salt (decimal string)
    @param maker Maker address (0x-prefixed)
    @param signer Signer address (0x-prefixed)
    @param taker Taker address (0x-prefixed)
    @param token_id CTF token ID (decimal string)
    @param maker_amount Maker amount in wei (decimal string)
    @param taker_amount Taker amount in wei (decimal string)
    @param expiration Expiration timestamp (decimal string)
    @param nonce Order nonce (decimal string)
    @param fee_rate_bps Fee rate in basis points (decimal string)
    @param side 0 for Buy, 1 for Sell
    @param signature_type 0 for EOA, 1 for Poly_proxy, 2 for Poly_gnosis_safe
    @return Signature hex string with 0x prefix *)
