(** Order building helpers for the RFQ API.

    This module provides functions for building signed accept_quote and
    approve_order request bodies. *)

module Crypto = Common.Crypto
module Constants = Common.Constants
module Order_signing = Common.Order_signing
module P = Common.Primitives
open Types

let src = Logs.Src.create "polymarket.rfq.order" ~doc:"RFQ order builder"

module Log = (val Logs.src_log src : Logs.LOG)

let build_accept_quote_body ~private_key ~request_id ~quote_id ~token_id
    ~maker_amount ~taker_amount ~(side : Side.t) ?expiration ?nonce
    ?(fee_rate_bps = Order_signing.default_fee_rate_bps) () =
  match Crypto.private_key_to_address private_key with
  | Error msg -> Error msg
  | Ok address_str -> (
      let address = P.Address.make_exn address_str in
      let salt = Order_signing.generate_salt () in
      let request_id_str = P.Request_id.to_string request_id in
      let quote_id_str = P.Quote_id.to_string quote_id in
      let token_id_str = P.Token_id.to_string token_id in
      Log.debug (fun m ->
          m
            "Building accept_quote: request=%s quote=%s side=%s maker=%s \
             taker=%s"
            request_id_str quote_id_str (Side.to_string side) maker_amount
            taker_amount);
      let expiration =
        match expiration with
        | Some e -> e
        | None -> Order_signing.default_expiration_int ()
      in
      let nonce =
        match nonce with Some n -> n | None -> Order_signing.default_nonce
      in
      let side_int = match side with Side.Buy -> 0 | Side.Sell -> 1 in
      Log.debug (fun m ->
          m "Signing: token=%s...%s expiration=%d nonce=%s"
            (String.sub token_id_str 0 (min 8 (String.length token_id_str)))
            (let len = String.length token_id_str in
             if len > 8 then String.sub token_id_str (len - 4) 4 else "")
            expiration nonce);
      match
        Order_signing.sign_order ~private_key ~salt ~maker:address_str
          ~signer:address_str ~taker:Constants.zero_address
          ~token_id:token_id_str ~maker_amount ~taker_amount
          ~expiration:(string_of_int expiration) ~nonce ~fee_rate_bps
          ~side:side_int ~signature_type:0
      with
      | Error msg -> Error msg
      | Ok signature_str ->
          let signature = P.Signature.make_exn signature_str in
          let zero_address = P.Address.make_exn Constants.zero_address in
          Log.debug (fun m ->
              m "Signed: sig=%s..." (String.sub signature_str 0 16));
          Ok
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
            })
