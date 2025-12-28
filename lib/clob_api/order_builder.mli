(** High-level order building helpers for the CLOB API.

    This module provides ergonomic functions for building signed orders with
    proper EIP-712 signatures, amount calculations, and nonce generation.

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

(** {1 Salt Generation} *)

val generate_salt : unit -> string
(** Generate a random salt for order uniqueness. Returns a large decimal integer
    string. *)

(** {1 Amount Calculations} *)

val calculate_amounts :
  side:Types.Side.t -> price:float -> size:float -> string * string
(** Calculate maker and taker amounts for an order.

    For BUY orders: maker provides USDC, receives CTF tokens
    - makerAmount = price * size (scaled to 6 decimals)
    - takerAmount = size (scaled to 6 decimals)

    For SELL orders: maker provides CTF tokens, receives USDC
    - makerAmount = size (scaled to 6 decimals)
    - takerAmount = price * size (scaled to 6 decimals)

    @param side Buy or Sell
    @param price Price per share (typically 0.0 to 1.0)
    @param size Number of shares
    @return (maker_amount, taker_amount) as strings *)

(** {1 Order Building} *)

val create_limit_order :
  private_key:Crypto.private_key ->
  token_id:string ->
  side:Types.Side.t ->
  price:float ->
  size:float ->
  ?expiration:string ->
  ?nonce:int ->
  ?fee_rate_bps:string ->
  unit ->
  Types.signed_order
(** Create a signed limit order ready for submission.

    @param private_key Ethereum private key (64 hex chars, no 0x prefix)
    @param token_id The CTF token ID for the market outcome
    @param side Buy or Sell
    @param price Price per share (0.0 to 1.0 for prediction markets)
    @param size Number of shares to buy/sell
    @param expiration Optional Unix timestamp for order expiry (default: 1 year)
    @param nonce Optional order nonce (default: 0)
    @param fee_rate_bps Optional fee rate in basis points (default: "0")
    @return A fully signed order with all required fields *)

val create_order_request :
  order:Types.signed_order ->
  order_type:Types.Order_type.t ->
  Types.order_request
(** Create an order request for API submission.

    @param order The signed order from create_limit_order
    @param order_type
      Order type: Gtc (Good Till Cancelled), Gtd (Good Till Date), Fok (Fill or
      Kill), Fak (Fill and Kill)
    @return An order request ready for Clob.L2.create_order *)
