(** Endpoint implementations for the Polymarket CLOB API.

    These functions implement the actual API calls and are used by the typestate
    client modules. *)

open Types
module B = Polymarket_http.Builder
module J = Polymarket_http.Json
module Auth = Polymarket_common.Auth

type t = Polymarket_http.Client.t
type error = Polymarket_http.Client.error

(** {1 Auth Endpoints} *)

let create_api_key http ~private_key ~address ~nonce =
  B.new_post http "/auth/api-key"
  |> B.with_body "{}"
  |> B.with_l1_auth ~private_key ~address ~nonce
  |> B.fetch_json Auth.api_key_response_of_yojson

let derive_api_key http ~private_key ~address ~nonce =
  B.new_get http "/auth/derive-api-key"
  |> B.with_l1_auth ~private_key ~address ~nonce
  |> B.fetch_json Auth.derive_api_key_response_of_yojson

let delete_api_key http ~credentials ~address =
  B.new_delete http "/auth/api-key"
  |> B.with_l2_auth ~credentials ~address
  |> B.fetch_unit

let get_api_keys http ~credentials ~address =
  B.new_get http "/auth/api-keys"
  |> B.with_l2_auth ~credentials ~address
  |> B.fetch_json_list (fun json ->
      match json with
      | `String s -> s
      | _ -> failwith "Expected string in API keys list")

(** {1 Order Book} *)

let get_order_book http ~token_id () =
  B.new_get http "/book"
  |> B.query_param "token_id" token_id
  |> B.fetch_json order_book_summary_of_yojson

let get_order_books http ~token_ids () =
  let body = J.list_single_field "token_id" token_ids in
  B.new_post http "/books" |> B.with_body body
  |> B.fetch_json_list order_book_summary_of_yojson

(** {1 Pricing} *)

let get_price http ~token_id ~side () =
  B.new_get http "/price"
  |> B.query_param "token_id" token_id
  |> B.query_param "side" (Side.to_string side)
  |> B.fetch_json price_response_of_yojson

let get_midpoint http ~token_id () =
  B.new_get http "/midpoint"
  |> B.query_param "token_id" token_id
  |> B.fetch_json midpoint_response_of_yojson

let get_prices http ~requests () =
  let body =
    J.list
      (fun (token_id, side) ->
        J.obj
          [
            ("token_id", J.string token_id);
            ("side", J.string (Side.to_string side));
          ])
      requests
  in
  B.new_post http "/prices" |> B.with_body body
  |> B.fetch_json prices_response_of_yojson

let get_spreads http ~token_ids () =
  let body = J.list_single_field "token_id" token_ids in
  B.new_post http "/spreads" |> B.with_body body
  |> B.fetch_json spreads_response_of_yojson

(** {1 Timeseries} *)

let get_price_history http ~market ?start_ts ?end_ts ?interval ?fidelity () =
  B.new_get http "/prices-history"
  |> B.query_param "market" market
  |> B.query_option "startTs" string_of_int start_ts
  |> B.query_option "endTs" string_of_int end_ts
  |> B.query_option "interval" Interval.to_string interval
  |> B.query_option "fidelity" string_of_int fidelity
  |> B.fetch_json price_history_of_yojson

(** {1 Orders (L2 only)} *)

let create_order http ~credentials ~address ~order ~owner ~order_type () =
  let body =
    J.body
      (J.obj
         [
           ("order", yojson_of_signed_order order);
           ("owner", J.string owner);
           ("orderType", J.string (Order_type.to_string order_type));
         ])
  in
  B.new_post http "/order" |> B.with_body body
  |> B.with_l2_auth ~credentials ~address
  |> B.fetch_json create_order_response_of_yojson

let create_orders http ~credentials ~address ~orders () =
  let body =
    J.list
      (fun (order, owner, order_type) ->
        J.obj
          [
            ("order", yojson_of_signed_order order);
            ("owner", J.string owner);
            ("orderType", J.string (Order_type.to_string order_type));
          ])
      orders
  in
  B.new_post http "/orders" |> B.with_body body
  |> B.with_l2_auth ~credentials ~address
  |> B.fetch_json_list create_order_response_of_yojson

let get_order http ~credentials ~address ~order_id () =
  B.new_get http ("/data/order/" ^ order_id)
  |> B.with_l2_auth ~credentials ~address
  |> B.fetch_json open_order_of_yojson

let get_orders http ~credentials ~address ?market ?asset_id () =
  B.new_get http "/data/orders"
  |> B.with_l2_auth ~credentials ~address
  |> B.query_add "market" market
  |> B.query_add "asset_id" asset_id
  |> B.fetch_json_list open_order_of_yojson

(** {1 Cancel Orders (L2 only)} *)

let cancel_order http ~credentials ~address ~order_id () =
  B.new_delete http "/order"
  |> B.with_l2_auth ~credentials ~address
  |> B.query_param "orderID" order_id
  |> B.fetch_json cancel_response_of_yojson

let cancel_orders http ~credentials ~address ~order_ids () =
  B.new_delete http "/orders"
  |> B.with_l2_auth ~credentials ~address
  |> B.query_each "orderIDs" Fun.id (Some order_ids)
  |> B.fetch_json cancel_response_of_yojson

let cancel_all http ~credentials ~address () =
  B.new_delete http "/cancel-all"
  |> B.with_l2_auth ~credentials ~address
  |> B.fetch_json cancel_response_of_yojson

let cancel_market_orders http ~credentials ~address ?market ?asset_id () =
  B.new_delete http "/cancel-market-orders"
  |> B.with_l2_auth ~credentials ~address
  |> B.query_add "market" market
  |> B.query_add "asset_id" asset_id
  |> B.fetch_json cancel_response_of_yojson

(** {1 Trades (L2 only)} *)

let get_trades http ~credentials ~address ?id ?taker ?maker ?market ?before
    ?after () =
  B.new_get http "/data/trades"
  |> B.with_l2_auth ~credentials ~address
  |> B.query_add "id" id |> B.query_add "taker" taker
  |> B.query_add "maker" maker
  |> B.query_add "market" market
  |> B.query_add "before" before
  |> B.query_add "after" after
  |> B.fetch_json_list clob_trade_of_yojson
