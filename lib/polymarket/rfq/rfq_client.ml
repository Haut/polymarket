(** RFQ API client for Request for Quote trading.

    All RFQ endpoints require L2 authentication. *)

module H = Client
module B = Http_builder
module J = Http_json
module Types = Rfq_types
module Auth = Auth
module Crypto = Crypto
open Rfq_types

let default_base_url = "https://clob.polymarket.com"

type t = { http : H.t; address : string; credentials : Auth.credentials }

let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
    ~credentials () =
  let http = H.create ~base_url ~sw ~net ~rate_limiter () in
  let address = Crypto.private_key_to_address private_key in
  { http; address; credentials }

let address t = t.address
let credentials t = t.credentials

(** {1 Request Endpoints} *)

let create_request t ~body () =
  B.new_post t.http "/rfq/request"
  |> B.with_body (J.body (yojson_of_create_request_body body))
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.fetch_json ~expected_fields:yojson_fields_of_create_request_response
       ~context:"create_request_response" create_request_response_of_yojson

let cancel_request t ~request_id () =
  B.new_delete_with_body t.http "/rfq/request"
  |> B.with_body (J.body (yojson_of_cancel_request_body { request_id }))
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.fetch_unit

let get_requests t ?offset ?limit ?state ?request_ids ?markets ?size_min
    ?size_max ?size_usdc_min ?size_usdc_max ?price_min ?price_max ?sort_by
    ?sort_dir () =
  B.new_get t.http "/rfq/request"
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.query_add "offset" offset
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "state" State_filter.to_string state
  |> B.query_each "requestIds" Fun.id request_ids
  |> B.query_each "markets" Fun.id markets
  |> B.query_option "sizeMin" string_of_float size_min
  |> B.query_option "sizeMax" string_of_float size_max
  |> B.query_option "sizeUsdcMin" string_of_float size_usdc_min
  |> B.query_option "sizeUsdcMax" string_of_float size_usdc_max
  |> B.query_option "priceMin" string_of_float price_min
  |> B.query_option "priceMax" string_of_float price_max
  |> B.query_option "sortBy" Sort_by.to_string sort_by
  |> B.query_option "sortDir" Sort_dir.to_string sort_dir
  |> B.fetch_json ~expected_fields:yojson_fields_of_get_requests_response
       ~context:"get_requests_response" get_requests_response_of_yojson

(** {1 Quote Endpoints} *)

let create_quote t ~body () =
  B.new_post t.http "/rfq/quote"
  |> B.with_body (J.body (yojson_of_create_quote_body body))
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.fetch_json ~expected_fields:yojson_fields_of_create_quote_response
       ~context:"create_quote_response" create_quote_response_of_yojson

let cancel_quote t ~quote_id () =
  B.new_delete_with_body t.http "/rfq/quote"
  |> B.with_body (J.body (yojson_of_cancel_quote_body { quote_id }))
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.fetch_unit

let get_quotes t ?offset ?limit ?state ?quote_ids ?request_ids ?markets
    ?size_min ?size_max ?size_usdc_min ?size_usdc_max ?price_min ?price_max
    ?sort_by ?sort_dir () =
  B.new_get t.http "/rfq/quote"
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.query_add "offset" offset
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "state" State_filter.to_string state
  |> B.query_each "quoteIds" Fun.id quote_ids
  |> B.query_each "requestIds" Fun.id request_ids
  |> B.query_each "markets" Fun.id markets
  |> B.query_option "sizeMin" string_of_float size_min
  |> B.query_option "sizeMax" string_of_float size_max
  |> B.query_option "sizeUsdcMin" string_of_float size_usdc_min
  |> B.query_option "sizeUsdcMax" string_of_float size_usdc_max
  |> B.query_option "priceMin" string_of_float price_min
  |> B.query_option "priceMax" string_of_float price_max
  |> B.query_option "sortBy" Sort_by.to_string sort_by
  |> B.query_option "sortDir" Sort_dir.to_string sort_dir
  |> B.fetch_json ~expected_fields:yojson_fields_of_get_quotes_response
       ~context:"get_quotes_response" get_quotes_response_of_yojson

(** {1 Execution Endpoints} *)

let accept_quote t ~body () =
  B.new_post t.http "/rfq/request/accept"
  |> B.with_body (J.body (yojson_of_accept_quote_body body))
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.fetch_unit

let approve_order t ~body () =
  B.new_post t.http "/rfq/quote/approve"
  |> B.with_body (J.body (yojson_of_approve_order_body body))
  |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
  |> B.fetch_json ~expected_fields:yojson_fields_of_approve_order_response
       ~context:"approve_order_response" approve_order_response_of_yojson
