(** Order building helpers for the RFQ API.

    This module provides functions for building signed accept_quote and
    approve_order request bodies. *)

module Crypto = Polymarket_common.Crypto
module Constants = Polymarket_common.Constants
module Order_signing = Polymarket_common.Order_signing
open Types

let src = Logs.Src.create "polymarket.rfq.order" ~doc:"RFQ order builder"

module Log = (val Logs.src_log src : Logs.LOG)

let default_fee_rate_bps = "0"

let build_accept_quote_body ~private_key ~request_id ~quote_id ~token_id
    ~maker_amount ~taker_amount ~(side : Side.t) ?expiration ?nonce
    ?(fee_rate_bps = default_fee_rate_bps) () =
  let address = Crypto.private_key_to_address private_key in
  let salt = Order_signing.generate_salt () in
  Log.debug (fun m ->
      m "Building accept_quote: request=%s quote=%s side=%s maker=%s taker=%s"
        request_id quote_id (Side.to_string side) maker_amount taker_amount);
  let expiration =
    match expiration with
    | Some e -> e
    | None ->
        let now = Unix.gettimeofday () in
        int_of_float (now +. Constants.one_year_seconds)
  in
  let nonce = match nonce with Some n -> n | None -> "0" in
  let side_int = match side with Side.Buy -> 0 | Side.Sell -> 1 in
  Log.debug (fun m ->
      m "Signing: token=%s...%s expiration=%d nonce=%s"
        (String.sub token_id 0 (min 8 (String.length token_id)))
        (let len = String.length token_id in
         if len > 8 then String.sub token_id (len - 4) 4 else "")
        expiration nonce);
  let signature =
    Order_signing.sign_order ~private_key ~salt ~maker:address ~signer:address
      ~taker:Constants.zero_address ~token_id ~maker_amount ~taker_amount
      ~expiration:(string_of_int expiration) ~nonce ~fee_rate_bps ~side:side_int
      ~signature_type:0
  in
  Log.debug (fun m -> m "Signed: sig=%s..." (String.sub signature 0 16));
  {
    request_id;
    quote_id;
    maker_amount;
    taker_amount;
    token_id;
    maker = address;
    signer = address;
    taker = Constants.zero_address;
    nonce;
    expiration;
    side;
    fee_rate_bps;
    signature;
    salt;
    owner = address;
  }
