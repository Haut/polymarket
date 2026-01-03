(** Order building helpers for the RFQ API.

    This module provides functions for building signed accept_quote and
    approve_order request bodies. *)

module Crypto = Crypto
module Constants = Constants
module Order_signing = Order_signing
module P = Primitives
open Rfq_types

let src = Logs.Src.create "polymarket.rfq.order" ~doc:"RFQ order builder"

module Log = (val Logs.src_log src : Logs.LOG)

let default_fee_rate_bps = "0"

let build_accept_quote_body ~private_key ~request_id ~quote_id ~token_id
    ~maker_amount ~taker_amount ~(side : Side.t) ?expiration ?nonce
    ?(fee_rate_bps = default_fee_rate_bps) () =
  let address_str = Crypto.private_key_to_address private_key in
  let address = P.Address.unsafe_of_string address_str in
  let salt = Order_signing.generate_salt () in
  let request_id_str = P.Request_id.to_string request_id in
  let quote_id_str = P.Quote_id.to_string quote_id in
  let token_id_str = P.Token_id.to_string token_id in
  Log.debug (fun m ->
      m "Building accept_quote: request=%s quote=%s side=%s maker=%s taker=%s"
        request_id_str quote_id_str (Side.to_string side) maker_amount
        taker_amount);
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
        (String.sub token_id_str 0 (min 8 (String.length token_id_str)))
        (let len = String.length token_id_str in
         if len > 8 then String.sub token_id_str (len - 4) 4 else "")
        expiration nonce);
  let signature_str =
    Order_signing.sign_order ~private_key ~salt ~maker:address_str
      ~signer:address_str ~taker:Constants.zero_address ~token_id:token_id_str
      ~maker_amount ~taker_amount ~expiration:(string_of_int expiration) ~nonce
      ~fee_rate_bps ~side:side_int ~signature_type:0
  in
  let signature = P.Signature.unsafe_of_string signature_str in
  let zero_address = P.Address.unsafe_of_string Constants.zero_address in
  Log.debug (fun m -> m "Signed: sig=%s..." (String.sub signature_str 0 16));
  {
    request_id;
    quote_id;
    maker_amount;
    taker_amount;
    token_id;
    maker = address;
    signer = address;
    taker = zero_address;
    nonce;
    expiration;
    side;
    fee_rate_bps;
    signature;
    salt;
    owner = address_str;
  }
