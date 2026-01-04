(** Typestate-authenticated HTTP client for the Polymarket CLOB API.

    See {!Client_typestate} for documentation. *)

module H = Client
module B = Http_builder
module J = Http_json
module Auth = Auth
module Crypto = Crypto
module Types = Clob_types
open Clob_types

let default_base_url = "https://clob.polymarket.com"

(* Re-export types from internal libraries *)
type private_key = Crypto.private_key

type credentials = Auth.credentials = {
  api_key : string;
  secret : string;
  passphrase : string;
}

type api_key_response = Auth.api_key_response = {
  api_key : string;
  secret : string;
  passphrase : string;
}

type rate_limiter = Rate_limiter.t
type error = H.error

let private_key_of_string = Crypto.private_key_of_string
let error_to_string = H.error_to_string

(** {1 Client Types} *)

type unauthed = { http : H.t }
type l1 = { http : H.t; private_key : Crypto.private_key; address : string }

type l2 = {
  http : H.t;
  private_key : Crypto.private_key;
  address : string;
  credentials : Auth.credentials;
}

(** {1 Public Endpoints Functor}

    Shared implementation for public endpoints across all auth levels. *)

module type HAS_HTTP = sig
  type t

  val http : t -> H.t
end

module Make_public (M : HAS_HTTP) = struct
  let get_order_book t ~token_id () =
    B.new_get (M.http t) "/book"
    |> B.query_param "token_id" token_id
    |> B.fetch_json
         ~expected_fields:Clob_types.yojson_fields_of_order_book_summary
         ~context:"order_book_summary" order_book_summary_of_yojson

  let get_order_books t ~token_ids () =
    B.new_post (M.http t) "/books"
    |> B.with_body (J.list_single_field "token_id" token_ids)
    |> B.fetch_json_list
         ~expected_fields:Clob_types.yojson_fields_of_order_book_summary
         ~context:"order_book_summary" order_book_summary_of_yojson

  let get_price t ~token_id ~side () =
    B.new_get (M.http t) "/price"
    |> B.query_param "token_id" token_id
    |> B.query_param "side" (Side.to_string side)
    |> B.fetch_json ~expected_fields:Clob_types.yojson_fields_of_price_response
         ~context:"price_response" price_response_of_yojson

  let get_midpoint t ~token_id () =
    B.new_get (M.http t) "/midpoint"
    |> B.query_param "token_id" token_id
    |> B.fetch_json
         ~expected_fields:Clob_types.yojson_fields_of_midpoint_response
         ~context:"midpoint_response" midpoint_response_of_yojson

  let get_prices t ~requests () =
    B.new_post (M.http t) "/prices"
    |> B.with_body
         (J.list
            (fun (token_id, side) ->
              J.obj
                [
                  ("token_id", J.string token_id);
                  ("side", J.string (Side.to_string side));
                ])
            requests)
    |> B.fetch_json prices_response_of_yojson

  let get_spreads t ~token_ids () =
    let body = J.list_single_field "token_id" token_ids in
    B.new_post (M.http t) "/spreads"
    |> B.with_body body
    |> B.fetch_json spreads_response_of_yojson

  let get_price_history t ~market ?start_ts ?end_ts ?interval ?fidelity () =
    B.new_get (M.http t) "/prices-history"
    |> B.query_param "market" market
    |> B.query_option "startTs" string_of_int start_ts
    |> B.query_option "endTs" string_of_int end_ts
    |> B.query_option "interval" Interval.to_string interval
    |> B.query_option "fidelity" string_of_int fidelity
    |> B.fetch_json ~expected_fields:Clob_types.yojson_fields_of_price_history
         ~context:"price_history" price_history_of_yojson
end

(** {1 Unauthenticated Client} *)

module Unauthed = struct
  type t = unauthed

  include Make_public (struct
    type t = unauthed

    let http (t : t) = t.http
  end)

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    ({ http } : t)
end

(** {1 L1-Authenticated Client} *)

module L1 = struct
  type t = l1

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    let address = Crypto.private_key_to_address private_key in
    ({ http; private_key; address } : t)

  let address (t : t) = t.address

  include Make_public (struct
    type t = l1

    let http (t : t) = t.http
  end)

  let create_api_key (t : t) ~nonce =
    B.new_post t.http "/auth/api-key"
    |> B.with_body "{}"
    |> B.with_l1_auth ~private_key:t.private_key ~address:t.address ~nonce
    |> B.fetch_json Auth.api_key_response_of_yojson

  let derive_api_key (t : t) ~nonce =
    match
      B.new_get t.http "/auth/derive-api-key"
      |> B.with_l1_auth ~private_key:t.private_key ~address:t.address ~nonce
      |> B.fetch_json Auth.api_key_response_of_yojson
    with
    | Ok resp ->
        let credentials = Auth.credentials_of_api_key_response resp in
        let l2_client : l2 =
          {
            http = t.http;
            private_key = t.private_key;
            address = t.address;
            credentials;
          }
        in
        Ok (l2_client, resp)
    | Error e -> Error e
end

(** {1 L2-Authenticated Client} *)

module L2 = struct
  type t = l2

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      ~credentials () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    let address = Crypto.private_key_to_address private_key in
    ({ http; private_key; address; credentials } : t)

  let address (t : t) = t.address
  let credentials (t : t) = t.credentials

  include Make_public (struct
    type t = l2

    let http (t : t) = t.http
  end)

  let create_api_key (t : t) ~nonce =
    B.new_post t.http "/auth/api-key"
    |> B.with_body "{}"
    |> B.with_l1_auth ~private_key:t.private_key ~address:t.address ~nonce
    |> B.fetch_json Auth.api_key_response_of_yojson

  let delete_api_key (t : t) =
    B.new_delete t.http "/auth/api-key"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.fetch_unit

  let get_api_keys (t : t) =
    B.new_get t.http "/auth/api-keys"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.fetch_json_list (fun json ->
        match json with
        | `String s -> s
        | _ -> failwith "Expected string in API keys list")

  let create_order (t : t) ~order ~owner ~order_type () =
    B.new_post t.http "/order"
    |> B.with_body
         (J.body
            (J.obj
               [
                 ("order", yojson_of_signed_order order);
                 ("owner", J.string owner);
                 ("orderType", J.string (Order_type.to_string order_type));
               ]))
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.fetch_json
         ~expected_fields:Clob_types.yojson_fields_of_create_order_response
         ~context:"create_order_response" create_order_response_of_yojson

  let create_orders (t : t) ~orders () =
    B.new_post t.http "/orders"
    |> B.with_body
         (J.list
            (fun (order, owner, order_type) ->
              J.obj
                [
                  ("order", yojson_of_signed_order order);
                  ("owner", J.string owner);
                  ("orderType", J.string (Order_type.to_string order_type));
                ])
            orders)
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.fetch_json_list
         ~expected_fields:Clob_types.yojson_fields_of_create_order_response
         ~context:"create_order_response" create_order_response_of_yojson

  let get_order (t : t) ~order_id () =
    B.new_get t.http ("/data/order/" ^ order_id)
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.fetch_json ~expected_fields:Clob_types.yojson_fields_of_open_order
         ~context:"open_order" open_order_of_yojson

  let get_orders (t : t) ?market ?asset_id () =
    B.new_get t.http "/data/orders"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.query_add "market" market
    |> B.query_add "asset_id" asset_id
    |> B.fetch_json_list ~expected_fields:Clob_types.yojson_fields_of_open_order
         ~context:"open_order" open_order_of_yojson

  let cancel_order (t : t) ~order_id () =
    B.new_delete t.http "/order"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.query_param "orderID" order_id
    |> B.fetch_json cancel_response_of_yojson

  let cancel_orders (t : t) ~order_ids () =
    B.new_delete t.http "/orders"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.query_each "orderIDs" Fun.id (Some order_ids)
    |> B.fetch_json cancel_response_of_yojson

  let cancel_all (t : t) () =
    B.new_delete t.http "/cancel-all"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.fetch_json cancel_response_of_yojson

  let cancel_market_orders (t : t) ?market ?asset_id () =
    B.new_delete t.http "/cancel-market-orders"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.query_add "market" market
    |> B.query_add "asset_id" asset_id
    |> B.fetch_json cancel_response_of_yojson

  let get_trades (t : t) ?id ?taker ?maker ?market ?before ?after () =
    B.new_get t.http "/data/trades"
    |> B.with_l2_auth ~credentials:t.credentials ~address:t.address
    |> B.query_add "id" id |> B.query_add "taker" taker
    |> B.query_add "maker" maker
    |> B.query_add "market" market
    |> B.query_add "before" before
    |> B.query_add "after" after
    |> B.fetch_json_list ~expected_fields:Clob_types.yojson_fields_of_clob_trade
         ~context:"clob_trade" clob_trade_of_yojson
end

(** {1 State Transitions} *)

let upgrade_to_l1 (t : unauthed) ~private_key : l1 =
  let address = Crypto.private_key_to_address private_key in
  { http = t.http; private_key; address }

let upgrade_to_l2 (t : l1) ~credentials : l2 =
  {
    http = t.http;
    private_key = t.private_key;
    address = t.address;
    credentials;
  }

let l2_to_l1 (t : l2) : l1 =
  { http = t.http; private_key = t.private_key; address = t.address }

let l2_to_unauthed (t : l2) : unauthed = { http = t.http }
let l1_to_unauthed (t : l1) : unauthed = { http = t.http }
