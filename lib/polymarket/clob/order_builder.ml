(** High-level order building helpers for the CLOB API.

    This module provides ergonomic functions for building signed orders with
    proper EIP-712 signatures, amount calculations, and nonce generation. *)

module Crypto = Polymarket_common.Crypto
module Constants = Polymarket_common.Constants
module Order_signing = Polymarket_common.Order_signing

let src = Logs.Src.create "polymarket.clob.order" ~doc:"CLOB order builder"

module Log = (val Logs.src_log src : Logs.LOG)

let default_fee_rate_bps = "0"

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
    ~size ?expiration ?nonce ?(fee_rate_bps = default_fee_rate_bps) () =
  let address = Crypto.private_key_to_address private_key in
  let salt = Order_signing.generate_salt () in
  let maker_amount, taker_amount = calculate_amounts ~side ~price ~size in
  Log.debug (fun m ->
      m "Building order: side=%s price=%.4f size=%.2f -> maker=%s taker=%s"
        (Types.Side.to_string side)
        price size maker_amount taker_amount);
  let expiration =
    match expiration with
    | Some e -> e
    | None ->
        let now = Unix.gettimeofday () in
        Printf.sprintf "%.0f" (now +. Constants.one_year_seconds)
  in
  let nonce = match nonce with Some n -> string_of_int n | None -> "0" in
  let side_int = match side with Types.Side.Buy -> 0 | Types.Side.Sell -> 1 in
  Log.debug (fun m ->
      m "Signing order: token=%s...%s expiration=%s nonce=%s"
        (String.sub token_id 0 (min 8 (String.length token_id)))
        (let len = String.length token_id in
         if len > 8 then String.sub token_id (len - 4) 4 else "")
        expiration nonce);
  let signature =
    Order_signing.sign_order ~private_key ~salt ~maker:address ~signer:address
      ~taker:Constants.zero_address ~token_id ~maker_amount ~taker_amount
      ~expiration ~nonce ~fee_rate_bps ~side:side_int ~signature_type:0
  in
  Log.debug (fun m -> m "Order signed: sig=%s..." (String.sub signature 0 16));
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

let create_order_request ~order ~order_type =
  Types.
    { order = Some order; owner = order.maker; order_type = Some order_type }
