(** RFQ API client for Request for Quote trading.

    All RFQ endpoints require L2 authentication. *)

module Auth = Polymarket_common.Auth
module Crypto = Polymarket_common.Crypto
module N = Polymarket_common.Primitives.Nonneg_int

val default_base_url : string
(** Default base URL for the RFQ API: https://clob.polymarket.com *)

type t
(** RFQ client with L2 authentication. *)

val create :
  ?base_url:string ->
  sw:Eio.Switch.t ->
  net:_ Eio.Net.t ->
  rate_limiter:Polymarket_rate_limiter.Rate_limiter.t ->
  private_key:Crypto.private_key ->
  credentials:Auth.credentials ->
  unit ->
  t

val address : t -> string
(** Get the Ethereum address derived from the private key. *)

val credentials : t -> Auth.credentials
(** Get the API credentials. *)

(** {1 Request Endpoints} *)

val create_request :
  t ->
  body:Types.create_request_body ->
  unit ->
  (Types.create_request_response, Types.error) result

val cancel_request :
  t -> request_id:Types.P.Request_id.t -> unit -> (unit, Types.error) result

val get_requests :
  t ->
  ?offset:string ->
  ?limit:N.t ->
  ?state:Types.State_filter.t ->
  ?request_ids:string list ->
  ?markets:string list ->
  ?size_min:float ->
  ?size_max:float ->
  ?size_usdc_min:float ->
  ?size_usdc_max:float ->
  ?price_min:float ->
  ?price_max:float ->
  ?sort_by:Types.Sort_by.t ->
  ?sort_dir:Types.Sort_dir.t ->
  unit ->
  (Types.get_requests_response, Types.error) result

(** {1 Quote Endpoints} *)

val create_quote :
  t ->
  body:Types.create_quote_body ->
  unit ->
  (Types.create_quote_response, Types.error) result

val cancel_quote :
  t -> quote_id:Types.P.Quote_id.t -> unit -> (unit, Types.error) result

val get_quotes :
  t ->
  ?offset:string ->
  ?limit:N.t ->
  ?state:Types.State_filter.t ->
  ?quote_ids:string list ->
  ?request_ids:string list ->
  ?markets:string list ->
  ?size_min:float ->
  ?size_max:float ->
  ?size_usdc_min:float ->
  ?size_usdc_max:float ->
  ?price_min:float ->
  ?price_max:float ->
  ?sort_by:Types.Sort_by.t ->
  ?sort_dir:Types.Sort_dir.t ->
  unit ->
  (Types.get_quotes_response, Types.error) result

(** {1 Execution Endpoints} *)

val accept_quote :
  t -> body:Types.accept_quote_body -> unit -> (unit, Types.error) result
(** Accept a quote. Use {!Order_builder.build_accept_quote_body} to create the
    body. *)

val approve_order :
  t ->
  body:Types.approve_order_body ->
  unit ->
  (Types.approve_order_response, Types.error) result
(** Approve an order. Use {!Order_builder.build_accept_quote_body} to create the
    body. *)
