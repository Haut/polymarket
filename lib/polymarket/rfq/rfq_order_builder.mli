(** Order building helpers for the RFQ API.

    This module provides functions for building signed accept_quote and
    approve_order request bodies. *)

val build_accept_quote_body :
  private_key:Crypto.private_key ->
  request_id:Rfq_types.P.Request_id.t ->
  quote_id:Rfq_types.P.Quote_id.t ->
  token_id:Rfq_types.P.Token_id.t ->
  maker_amount:string ->
  taker_amount:string ->
  side:Rfq_types.Side.t ->
  ?expiration:int ->
  ?nonce:string ->
  ?fee_rate_bps:string ->
  unit ->
  Rfq_types.accept_quote_body
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
    @return A signed accept_quote_body ready for submission *)
