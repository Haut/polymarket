(** HTTP client for the Polymarket CLOB API (https://clob.polymarket.com). *)

(** {1 Client} *)

type t
(** The CLOB API client type, optionally configured with credentials for
    authenticated endpoints. *)

val default_base_url : string

val create :
  ?base_url:string ->
  ?credentials:Auth_types.credentials ->
  ?address:string ->
  sw:Eio.Switch.t ->
  net:_ Eio.Net.t ->
  unit ->
  t
(** Create a new CLOB API client.
    @param base_url Optional base URL (defaults to https://clob.polymarket.com)
    @param credentials Optional API credentials for authenticated endpoints
    @param address
      Optional Ethereum address (required if credentials are provided)
    @param sw The Eio switch for resource management
    @param net The Eio network capability *)

val with_credentials :
  t -> credentials:Auth_types.credentials -> address:string -> t
(** Create a new client with the given credentials, keeping the same HTTP
    client. *)

val http_client : t -> Polymarket_http.Client.t
(** Get the underlying HTTP client for custom requests. *)

(** {1 Authentication}

    These functions require credentials to be set on the client. *)

val create_api_key :
  t ->
  private_key:Crypto.private_key ->
  nonce:int ->
  (Auth_types.api_key_response, Polymarket_http.Client.error_response) result
(** Create a new API key using L1 wallet authentication. Does not require
    credentials on the client, but requires a private key. *)

val derive_api_key :
  t ->
  private_key:Crypto.private_key ->
  nonce:int ->
  ( Auth_types.derive_api_key_response,
    Polymarket_http.Client.error_response )
  result
(** Derive API key from wallet using L1 authentication. Does not require
    credentials on the client, but requires a private key. *)

(** {1 Order Book} *)

val get_order_book :
  t ->
  token_id:string ->
  unit ->
  (Types.order_book_summary, Types.error_response) result

val get_order_books :
  t ->
  token_ids:string list ->
  unit ->
  (Types.order_book_summary list, Types.error_response) result

(** {1 Pricing} *)

val get_price :
  t ->
  token_id:string ->
  side:Types.order_side ->
  unit ->
  (Types.price_response, Types.error_response) result

val get_midpoint :
  t ->
  token_id:string ->
  unit ->
  (Types.midpoint_response, Types.error_response) result

val get_prices :
  t ->
  requests:(string * Types.order_side) list ->
  unit ->
  (Types.prices_response, Types.error_response) result

val get_spreads :
  t ->
  token_ids:string list ->
  unit ->
  (Types.spreads_response, Types.error_response) result

(** {1 Timeseries} *)

val get_price_history :
  t ->
  market:string ->
  ?start_ts:int ->
  ?end_ts:int ->
  ?interval:Types.time_interval ->
  ?fidelity:int ->
  unit ->
  (Types.price_history, Types.error_response) result

(** {1 Orders} *)

val create_order :
  t ->
  order:Types.signed_order ->
  owner:string ->
  order_type:Types.order_type ->
  unit ->
  (Types.create_order_response, Types.error_response) result

val create_orders :
  t ->
  orders:(Types.signed_order * string * Types.order_type) list ->
  unit ->
  (Types.create_order_response list, Types.error_response) result

val get_order :
  t ->
  order_id:string ->
  unit ->
  (Types.open_order, Types.error_response) result

val get_orders :
  t ->
  ?market:string ->
  ?asset_id:string ->
  unit ->
  (Types.open_order list, Types.error_response) result

(** {1 Cancel Orders} *)

val cancel_order :
  t ->
  order_id:string ->
  unit ->
  (Types.cancel_response, Types.error_response) result

val cancel_orders :
  t ->
  order_ids:string list ->
  unit ->
  (Types.cancel_response, Types.error_response) result

val cancel_all :
  t -> unit -> (Types.cancel_response, Types.error_response) result

val cancel_market_orders :
  t ->
  ?market:string ->
  ?asset_id:string ->
  unit ->
  (Types.cancel_response, Types.error_response) result

(** {1 Trades} *)

val get_trades :
  t ->
  ?id:string ->
  ?taker:string ->
  ?maker:string ->
  ?market:string ->
  ?before:string ->
  ?after:string ->
  unit ->
  (Types.clob_trade list, Types.error_response) result
