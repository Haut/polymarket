(** Endpoint implementations for the Polymarket CLOB API.

    These functions implement the actual API calls and are used by the typestate
    client modules. *)

module H = Polymarket_http.Client
module Auth = Polymarket_common.Auth

(** {1 Auth Endpoints} *)

val create_api_key :
  H.t ->
  private_key:Polymarket_common.Crypto.private_key ->
  address:string ->
  nonce:int ->
  (Auth.api_key_response, H.error) result

val derive_api_key :
  H.t ->
  private_key:Polymarket_common.Crypto.private_key ->
  address:string ->
  nonce:int ->
  (Auth.derive_api_key_response, H.error) result

val delete_api_key :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  (unit, H.error) result

val get_api_keys :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  (string list, H.error) result

(** {1 Order Book} *)

val get_order_book :
  H.t -> token_id:string -> unit -> (Types.order_book_summary, H.error) result

val get_order_books :
  H.t ->
  token_ids:string list ->
  unit ->
  (Types.order_book_summary list, H.error) result

(** {1 Pricing} *)

val get_price :
  H.t ->
  token_id:string ->
  side:Types.Side.t ->
  unit ->
  (Types.price_response, H.error) result

val get_midpoint :
  H.t -> token_id:string -> unit -> (Types.midpoint_response, H.error) result

val get_prices :
  H.t ->
  requests:(string * Types.Side.t) list ->
  unit ->
  (Types.prices_response, H.error) result

val get_spreads :
  H.t ->
  token_ids:string list ->
  unit ->
  (Types.spreads_response, H.error) result

(** {1 Timeseries} *)

val get_price_history :
  H.t ->
  market:string ->
  ?start_ts:int ->
  ?end_ts:int ->
  ?interval:Types.Interval.t ->
  ?fidelity:int ->
  unit ->
  (Types.price_history, H.error) result

(** {1 Orders (L2 only)} *)

val create_order :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  order:Types.signed_order ->
  owner:string ->
  order_type:Types.Order_type.t ->
  unit ->
  (Types.create_order_response, H.error) result

val create_orders :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  orders:(Types.signed_order * string * Types.Order_type.t) list ->
  unit ->
  (Types.create_order_response list, H.error) result

val get_order :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  order_id:string ->
  unit ->
  (Types.open_order, H.error) result

val get_orders :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  ?market:string ->
  ?asset_id:string ->
  unit ->
  (Types.open_order list, H.error) result

(** {1 Cancel Orders (L2 only)} *)

val cancel_order :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  order_id:string ->
  unit ->
  (Types.cancel_response, H.error) result

val cancel_orders :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  order_ids:string list ->
  unit ->
  (Types.cancel_response, H.error) result

val cancel_all :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  unit ->
  (Types.cancel_response, H.error) result

val cancel_market_orders :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  ?market:string ->
  ?asset_id:string ->
  unit ->
  (Types.cancel_response, H.error) result

(** {1 Trades (L2 only)} *)

val get_trades :
  H.t ->
  credentials:Auth.credentials ->
  address:string ->
  ?id:string ->
  ?taker:string ->
  ?maker:string ->
  ?market:string ->
  ?before:string ->
  ?after:string ->
  unit ->
  (Types.clob_trade list, H.error) result
