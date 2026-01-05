(** High-level order building helpers for the CLOB API.

    This module provides ergonomic functions for building signed orders with
    proper EIP-712 signatures, amount calculations, and nonce generation. *)

module Crypto = Common.Crypto
module Constants = Common.Constants
module Order_signing = Common.Order_signing
module P = Common.Primitives

let src = Logs.Src.create "polymarket.clob.order" ~doc:"CLOB order builder"

module Log = (val Logs.src_log src : Logs.LOG)

(** {1 Amount Calculations} *)

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

(** {1 Public API} *)

let create_limit_order ~private_key ~token_id ~(side : Types.Side.t) ~price
    ~size ?expiration ?nonce
    ?(fee_rate_bps = Order_signing.default_fee_rate_bps) () =
  let address_str = Crypto.private_key_to_address private_key in
  let address = P.Address.unsafe_of_string address_str in
  let salt = Order_signing.generate_salt () in
  let maker_amount, taker_amount = calculate_amounts ~side ~price ~size in
  let token_id_str = P.Token_id.to_string token_id in
  Log.debug (fun m ->
      m "Building order: side=%s price=%.4f size=%.2f -> maker=%s taker=%s"
        (Types.Side.to_string side)
        price size maker_amount taker_amount);
  let expiration =
    match expiration with
    | Some e -> e
    | None -> Order_signing.default_expiration_string ()
  in
  let nonce =
    match nonce with
    | Some n -> string_of_int n
    | None -> Order_signing.default_nonce
  in
  let side_int = match side with Types.Side.Buy -> 0 | Types.Side.Sell -> 1 in
  Log.debug (fun m ->
      m "Signing order: token=%s...%s expiration=%s nonce=%s"
        (String.sub token_id_str 0 (min 8 (String.length token_id_str)))
        (let len = String.length token_id_str in
         if len > 8 then String.sub token_id_str (len - 4) 4 else "")
        expiration nonce);
  let signature_str =
    Order_signing.sign_order ~private_key ~salt ~maker:address_str
      ~signer:address_str ~taker:Constants.zero_address ~token_id:token_id_str
      ~maker_amount ~taker_amount ~expiration ~nonce ~fee_rate_bps
      ~side:side_int ~signature_type:0
  in
  let signature = P.Signature.unsafe_of_string signature_str in
  let zero_address = P.Address.unsafe_of_string Constants.zero_address in
  Log.debug (fun m ->
      m "Order signed: sig=%s..." (String.sub signature_str 0 16));
  Types.
    {
      salt = Some salt;
      maker = Some address;
      signer = Some address;
      taker = Some zero_address;
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

let create_order_request ~order ~order_type =
  let owner = Option.map P.Address.to_string order.Types.maker in
  Types.{ order = Some order; owner; order_type = Some order_type }
