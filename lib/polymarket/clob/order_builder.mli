(** High-level order building helpers for the CLOB API.

    This module provides ergonomic functions for building signed orders. For
    low-level signing, see {!Order_signing}.

    Example:
    {[
      let order =
        Order_builder.create_limit_order
          ~private_key:"your_private_key_hex"
          ~token_id:"12345..."
          ~side:Types.Side.Buy
          ~price:0.65
          ~size:100.0
          ()
      in
      let request =
        Order_builder.create_order_request
          ~order
          ~order_type:Types.Order_type.Gtc
      in
      (* Submit with Clob.L2.create_order *)
    ]} *)

(** {1 Amount Calculations} *)

val calculate_amounts :
  side:Types.Side.t -> price:float -> size:float -> string * string
(** Calculate maker and taker amounts for an order.

    For BUY orders: maker provides USDC, receives CTF tokens For SELL orders:
    maker provides CTF tokens, receives USDC

    @param side Buy or Sell
    @param price Price per share (typically 0.0 to 1.0)
    @param size Number of shares
    @return (maker_amount, taker_amount) as decimal strings *)

(** {1 Order Building} *)

val create_limit_order :
  private_key:Common.Crypto.private_key ->
  token_id:Types.P.Token_id.t ->
  side:Types.Side.t ->
  price:float ->
  size:float ->
  ?expiration:string ->
  ?nonce:int ->
  ?fee_rate_bps:string ->
  unit ->
  (Types.signed_order, Common.Crypto.error) result
(** Create a signed limit order ready for submission.

    @param private_key Ethereum private key (64 hex chars, no 0x prefix)
    @param token_id The CTF token ID for the market outcome
    @param side Buy or Sell
    @param price Price per share (0.0 to 1.0 for prediction markets)
    @param size Number of shares to buy/sell
    @param expiration Optional Unix timestamp for order expiry (default: 1 year)
    @param nonce Optional order nonce (default: 0)
    @param fee_rate_bps Optional fee rate in basis points (default: "0")
    @return [Ok order] fully signed with all required fields, or [Error e] *)

val create_order_request :
  order:Types.signed_order ->
  order_type:Types.Order_type.t ->
  Types.order_request
(** Create an order request for API submission.

    @param order The signed order from create_limit_order
    @param order_type Order type: Gtc, Gtd, Fok, or Fak
    @return An order request ready for Clob.L2.create_order *)
