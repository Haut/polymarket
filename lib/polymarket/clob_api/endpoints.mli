(** Endpoint implementations for the Polymarket CLOB API.

    These functions implement the actual API calls and are used by the typestate
    client modules. *)

module Auth = Polymarket_common.Auth

type t = Polymarket_http.Client.t
type error = Polymarket_http.Client.error

(** {1 Auth Endpoints} *)

val create_api_key :
  t ->
  private_key:Polymarket_common.Crypto.private_key ->
  address:string ->
  nonce:int ->
  (Auth.api_key_response, error) result

val derive_api_key :
  t ->
  private_key:Polymarket_common.Crypto.private_key ->
  address:string ->
  nonce:int ->
  (Auth.api_key_response, error) result

val delete_api_key :
  t -> credentials:Auth.credentials -> address:string -> (unit, error) result

val get_api_keys :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  (string list, error) result

(** {1 Order Book} *)

val get_order_book :
  t -> token_id:string -> unit -> (Types.order_book_summary, error) result

val get_order_books :
  t ->
  token_ids:string list ->
  unit ->
  (Types.order_book_summary list, error) result

(** {1 Pricing} *)

val get_price :
  t ->
  token_id:string ->
  side:Types.Side.t ->
  unit ->
  (Types.price_response, error) result

val get_midpoint :
  t -> token_id:string -> unit -> (Types.midpoint_response, error) result

val get_prices :
  t ->
  requests:(string * Types.Side.t) list ->
  unit ->
  (Types.prices_response, error) result

val get_spreads :
  t -> token_ids:string list -> unit -> (Types.spreads_response, error) result

(** {1 Timeseries} *)

val get_price_history :
  t ->
  market:string ->
  ?start_ts:int ->
  ?end_ts:int ->
  ?interval:Types.Interval.t ->
  ?fidelity:int ->
  unit ->
  (Types.price_history, error) result

(** {1 Orders (L2 only)} *)

val create_order :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  order:Types.signed_order ->
  owner:string ->
  order_type:Types.Order_type.t ->
  unit ->
  (Types.create_order_response, error) result

val create_orders :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  orders:(Types.signed_order * string * Types.Order_type.t) list ->
  unit ->
  (Types.create_order_response list, error) result

val get_order :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  order_id:string ->
  unit ->
  (Types.open_order, error) result

val get_orders :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  ?market:string ->
  ?asset_id:string ->
  unit ->
  (Types.open_order list, error) result

(** {1 Cancel Orders (L2 only)} *)

val cancel_order :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  order_id:string ->
  unit ->
  (Types.cancel_response, error) result

val cancel_orders :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  order_ids:string list ->
  unit ->
  (Types.cancel_response, error) result

val cancel_all :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  unit ->
  (Types.cancel_response, error) result

val cancel_market_orders :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  ?market:string ->
  ?asset_id:string ->
  unit ->
  (Types.cancel_response, error) result

(** {1 Trades (L2 only)} *)

val get_trades :
  t ->
  credentials:Auth.credentials ->
  address:string ->
  ?id:string ->
  ?taker:string ->
  ?maker:string ->
  ?market:string ->
  ?before:string ->
  ?after:string ->
  unit ->
  (Types.clob_trade list, error) result
