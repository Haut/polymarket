(** Order building helpers for the RFQ API.

    This module provides functions for building signed accept_quote and
    approve_order request bodies. *)

val build_accept_quote_body :
  private_key:Common.Crypto.private_key ->
  request_id:Types.P.Request_id.t ->
  quote_id:Types.P.Quote_id.t ->
  token_id:Types.P.U256.t ->
  maker_amount:string ->
  taker_amount:string ->
  side:Types.Side.t ->
  ?expiration:int ->
  ?nonce:string ->
  ?fee_rate_bps:string ->
  unit ->
  (Types.accept_quote_body, Common.Crypto.error) result
(** Build a signed accept_quote request body.

    @param private_key Ethereum private key
    @param request_id The RFQ request ID
    @param quote_id The quote ID to accept
    @param token_id CTF token ID
    @param maker_amount Maker amount in wei
    @param taker_amount Taker amount in wei
    @param side Buy or Sell
    @param expiration Optional expiration timestamp (default: 1 year)
    @param nonce Optional order nonce (default: "0")
    @param fee_rate_bps Optional fee rate in basis points (default: "0")
    @return [Ok body] ready for submission, or [Error e] on failure *)
