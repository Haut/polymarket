(** Endpoint implementations for the Polymarket CLOB API.

    These functions implement the actual API calls and are used by the typestate
    client modules. *)

open Types
module H = Polymarket_http.Client
module Auth = Polymarket_common.Auth

(** {1 Auth Endpoints} *)

let create_api_key http ~private_key ~address ~nonce =
  let headers = Auth.build_l1_headers ~private_key ~address ~nonce in
  H.post_json ~headers http "/auth/api-key" Auth.api_key_response_of_yojson
    ~body:"{}" []

let derive_api_key http ~private_key ~address ~nonce =
  let headers = Auth.build_l1_headers ~private_key ~address ~nonce in
  H.get_json ~headers http "/auth/derive-api-key"
    Auth.derive_api_key_response_of_yojson []

let delete_api_key http ~credentials ~address =
  let path = "/auth/api-key" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
  in
  H.delete_unit ~headers http path []

let get_api_keys http ~credentials ~address =
  let path = "/auth/api-keys" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"GET" ~path ~body:""
  in
  H.get_json_list ~headers http path
    (fun json ->
      match json with
      | `String s -> s
      | _ -> failwith "Expected string in API keys list")
    []

(** {1 Order Book} *)

let get_order_book http ~token_id () =
  [ ("token_id", [ token_id ]) ]
  |> H.get_json http "/book" order_book_summary_of_yojson

let get_order_books http ~token_ids () =
  let body = H.json_list_single_field "token_id" token_ids in
  H.post_json_list http "/books" order_book_summary_of_yojson ~body []

(** {1 Pricing} *)

let get_price http ~token_id ~side () =
  [ ("token_id", [ token_id ]); ("side", [ Side.to_string side ]) ]
  |> H.get_json http "/price" price_response_of_yojson

let get_midpoint http ~token_id () =
  [ ("token_id", [ token_id ]) ]
  |> H.get_json http "/midpoint" midpoint_response_of_yojson

let get_prices http ~requests () =
  let body =
    H.json_list_body
      (fun (token_id, side) ->
        H.json_obj
          [
            ("token_id", H.json_string token_id);
            ("side", H.json_string (Side.to_string side));
          ])
      requests
  in
  H.post_json http "/prices" prices_response_of_yojson ~body []

let get_spreads http ~token_ids () =
  let body = H.json_list_single_field "token_id" token_ids in
  H.post_json http "/spreads" spreads_response_of_yojson ~body []

(** {1 Timeseries} *)

let get_price_history http ~market ?start_ts ?end_ts ?interval ?fidelity () =
  [ ("market", [ market ]) ]
  |> H.add_option "startTs" string_of_int start_ts
  |> H.add_option "endTs" string_of_int end_ts
  |> H.add_option "interval" Interval.to_string interval
  |> H.add_option "fidelity" string_of_int fidelity
  |> H.get_json http "/prices-history" price_history_of_yojson

(** {1 Orders (L2 only)} *)

let create_order http ~credentials ~address ~order ~owner ~order_type () =
  let path = "/order" in
  let body =
    H.json_body
      (H.json_obj
         [
           ("order", yojson_of_signed_order order);
           ("owner", H.json_string owner);
           ("orderType", H.json_string (Order_type.to_string order_type));
         ])
  in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"POST" ~path ~body
  in
  H.post_json ~headers http path create_order_response_of_yojson ~body []

let create_orders http ~credentials ~address ~orders () =
  let path = "/orders" in
  let body =
    H.json_list_body
      (fun (order, owner, order_type) ->
        H.json_obj
          [
            ("order", yojson_of_signed_order order);
            ("owner", H.json_string owner);
            ("orderType", H.json_string (Order_type.to_string order_type));
          ])
      orders
  in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"POST" ~path ~body
  in
  H.post_json_list ~headers http path create_order_response_of_yojson ~body []

let get_order http ~credentials ~address ~order_id () =
  let path = "/data/order/" ^ order_id in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"GET" ~path ~body:""
  in
  H.get_json ~headers http path open_order_of_yojson []

let get_orders http ~credentials ~address ?market ?asset_id () =
  let path = "/data/orders" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"GET" ~path ~body:""
  in
  [] |> H.add "market" market |> H.add "asset_id" asset_id
  |> H.get_json_list ~headers http path open_order_of_yojson

(** {1 Cancel Orders (L2 only)} *)

let cancel_order http ~credentials ~address ~order_id () =
  let path = "/order" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
  in
  [ ("orderID", [ order_id ]) ]
  |> H.delete_json ~headers http path cancel_response_of_yojson

let cancel_orders http ~credentials ~address ~order_ids () =
  let path = "/orders" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
  in
  [ ("orderIDs", order_ids) ]
  |> H.delete_json ~headers http path cancel_response_of_yojson

let cancel_all http ~credentials ~address () =
  let path = "/cancel-all" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
  in
  H.delete_json ~headers http path cancel_response_of_yojson []

let cancel_market_orders http ~credentials ~address ?market ?asset_id () =
  let path = "/cancel-market-orders" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
  in
  [] |> H.add "market" market |> H.add "asset_id" asset_id
  |> H.delete_json ~headers http path cancel_response_of_yojson

(** {1 Trades (L2 only)} *)

let get_trades http ~credentials ~address ?id ?taker ?maker ?market ?before
    ?after () =
  let path = "/data/trades" in
  let headers =
    Auth.build_l2_headers ~credentials ~address ~method_:"GET" ~path ~body:""
  in
  [] |> H.add "id" id |> H.add "taker" taker |> H.add "maker" maker
  |> H.add "market" market |> H.add "before" before |> H.add "after" after
  |> H.get_json_list ~headers http path clob_trade_of_yojson
