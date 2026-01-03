(** RFQ API client for Request for Quote trading.

    All RFQ endpoints require L2 authentication. *)

module Types = Rfq_types
(** RFQ API request/response types. *)

module Auth = Auth
module Crypto = Crypto
module N = Primitives.Nonneg_int

val default_base_url : string
(** Default base URL for the RFQ API: https://clob.polymarket.com *)

type t
(** RFQ client with L2 authentication. *)

val create :
  ?base_url:string ->
  sw:Eio.Switch.t ->
  net:_ Eio.Net.t ->
  rate_limiter:Rate_limiter.t ->
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
  body:Rfq_types.create_request_body ->
  unit ->
  (Rfq_types.create_request_response, Rfq_types.error) result

val cancel_request :
  t ->
  request_id:Rfq_types.P.Request_id.t ->
  unit ->
  (unit, Rfq_types.error) result

val get_requests :
  t ->
  ?offset:string ->
  ?limit:N.t ->
  ?state:Rfq_types.State_filter.t ->
  ?request_ids:string list ->
  ?markets:string list ->
  ?size_min:float ->
  ?size_max:float ->
  ?size_usdc_min:float ->
  ?size_usdc_max:float ->
  ?price_min:float ->
  ?price_max:float ->
  ?sort_by:Rfq_types.Sort_by.t ->
  ?sort_dir:Rfq_types.Sort_dir.t ->
  unit ->
  (Rfq_types.get_requests_response, Rfq_types.error) result

(** {1 Quote Endpoints} *)

val create_quote :
  t ->
  body:Rfq_types.create_quote_body ->
  unit ->
  (Rfq_types.create_quote_response, Rfq_types.error) result

val cancel_quote :
  t -> quote_id:Rfq_types.P.Quote_id.t -> unit -> (unit, Rfq_types.error) result

val get_quotes :
  t ->
  ?offset:string ->
  ?limit:N.t ->
  ?state:Rfq_types.State_filter.t ->
  ?quote_ids:string list ->
  ?request_ids:string list ->
  ?markets:string list ->
  ?size_min:float ->
  ?size_max:float ->
  ?size_usdc_min:float ->
  ?size_usdc_max:float ->
  ?price_min:float ->
  ?price_max:float ->
  ?sort_by:Rfq_types.Sort_by.t ->
  ?sort_dir:Rfq_types.Sort_dir.t ->
  unit ->
  (Rfq_types.get_quotes_response, Rfq_types.error) result

(** {1 Execution Endpoints} *)

val accept_quote :
  t ->
  body:Rfq_types.accept_quote_body ->
  unit ->
  (unit, Rfq_types.error) result
(** Accept a quote. Use [Rfq_order_builder.build_accept_quote_body] to create
    the body. *)

val approve_order :
  t ->
  body:Rfq_types.approve_order_body ->
  unit ->
  (Rfq_types.approve_order_response, Rfq_types.error) result
(** Approve an order. Use [Rfq_order_builder.build_accept_quote_body] to create
    the body. *)
