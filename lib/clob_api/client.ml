(** HTTP client for the Polymarket CLOB API (https://clob.polymarket.com). *)

open Types
module H = Polymarket_http.Client
module P = Polymarket_common.Primitives

(** {1 Client} *)

type t = {
  http : Polymarket_http.Client.t;
  credentials : Auth_types.credentials option;
  address : string option;
}

let default_base_url = "https://clob.polymarket.com"

let create ?(base_url = default_base_url) ?credentials ?address ~sw ~env
    ~rate_limiter () =
  let http = H.create ~base_url ~sw ~env ~rate_limiter () in
  { http; credentials; address }

let with_credentials t ~credentials ~address =
  { t with credentials = Some credentials; address = Some address }

let http_client t = t.http

(** {1 Internal Helpers} *)

let get_auth_headers t ~method_ ~path ~body =
  match (t.credentials, t.address) with
  | Some creds, Some addr ->
      Auth.build_l2_headers ~credentials:creds ~address:addr ~method_ ~path
        ~body
  | _ -> []

(** {1 Authentication} *)

let create_api_key t ~private_key ~nonce =
  let address = Crypto.private_key_to_address private_key in
  Auth.create_api_key t.http ~private_key ~address ~nonce

let derive_api_key t ~private_key ~nonce =
  let address = Crypto.private_key_to_address private_key in
  Auth.derive_api_key t.http ~private_key ~address ~nonce

(** {1 Order Book} *)

let get_order_book t ~token_id () =
  [ ("token_id", [ token_id ]) ]
  |> H.get_json t.http "/book" order_book_summary_of_yojson

let get_order_books t ~token_ids () =
  let body =
    `List (List.map (fun id -> `Assoc [ ("token_id", `String id) ]) token_ids)
    |> Yojson.Safe.to_string
  in
  H.post_json_list t.http "/books" order_book_summary_of_yojson ~body []

(** {1 Pricing} *)

let get_price t ~token_id ~side () =
  [ ("token_id", [ token_id ]); ("side", [ Side.to_string side ]) ]
  |> H.get_json t.http "/price" price_response_of_yojson

let get_midpoint t ~token_id () =
  [ ("token_id", [ token_id ]) ]
  |> H.get_json t.http "/midpoint" midpoint_response_of_yojson

let get_prices t ~requests () =
  let body =
    `List
      (List.map
         (fun (token_id, side) ->
           `Assoc
             [
               ("token_id", `String token_id);
               ("side", `String (Side.to_string side));
             ])
         requests)
    |> Yojson.Safe.to_string
  in
  H.post_json t.http "/prices" prices_response_of_yojson ~body []

let get_spreads t ~token_ids () =
  let body =
    `List (List.map (fun id -> `Assoc [ ("token_id", `String id) ]) token_ids)
    |> Yojson.Safe.to_string
  in
  H.post_json t.http "/spreads" spreads_response_of_yojson ~body []

(** {1 Timeseries} *)

let get_price_history t ~market ?start_ts ?end_ts ?interval ?fidelity () =
  [ ("market", [ market ]) ]
  |> H.add_option "startTs" string_of_int start_ts
  |> H.add_option "endTs" string_of_int end_ts
  |> H.add_option "interval" Interval.to_string interval
  |> H.add_option "fidelity" string_of_int fidelity
  |> H.get_json t.http "/prices-history" price_history_of_yojson

(** {1 Orders} *)

let create_order t ~order ~owner ~order_type () =
  let path = "/order" in
  let body =
    `Assoc
      [
        ("order", yojson_of_signed_order order);
        ("owner", `String owner);
        ("orderType", `String (Order_type.to_string order_type));
      ]
    |> Yojson.Safe.to_string
  in
  let headers = get_auth_headers t ~method_:"POST" ~path ~body in
  H.post_json ~headers t.http path create_order_response_of_yojson ~body []

let create_orders t ~orders () =
  let path = "/orders" in
  let body =
    `List
      (List.map
         (fun (order, owner, order_type) ->
           `Assoc
             [
               ("order", yojson_of_signed_order order);
               ("owner", `String owner);
               ("orderType", `String (Order_type.to_string order_type));
             ])
         orders)
    |> Yojson.Safe.to_string
  in
  let headers = get_auth_headers t ~method_:"POST" ~path ~body in
  H.post_json_list ~headers t.http path create_order_response_of_yojson ~body []

let get_order t ~order_id () =
  let path = "/data/order/" ^ order_id in
  let headers = get_auth_headers t ~method_:"GET" ~path ~body:"" in
  H.get_json ~headers t.http path open_order_of_yojson []

let get_orders t ?market ?asset_id () =
  let path = "/data/orders" in
  let headers = get_auth_headers t ~method_:"GET" ~path ~body:"" in
  [] |> H.add "market" market |> H.add "asset_id" asset_id
  |> H.get_json_list ~headers t.http path open_order_of_yojson

(** {1 Cancel Orders} *)

let cancel_order t ~order_id () =
  let path = "/order" in
  let headers = get_auth_headers t ~method_:"DELETE" ~path ~body:"" in
  [ ("orderID", [ order_id ]) ]
  |> H.delete_json ~headers t.http path cancel_response_of_yojson

let cancel_orders t ~order_ids () =
  let path = "/orders" in
  let headers = get_auth_headers t ~method_:"DELETE" ~path ~body:"" in
  let uri =
    Polymarket_http.Client.build_uri
      (Polymarket_http.Client.base_url t.http)
      path []
  in
  let status, resp_body =
    H.do_delete ~headers t.http (Uri.with_query uri [ ("orderIDs", order_ids) ])
  in
  H.handle_response status resp_body
    (fun body ->
      H.parse_json cancel_response_of_yojson body |> Result.map_error H.to_error)
    H.parse_error

let cancel_all t () =
  let path = "/cancel-all" in
  let headers = get_auth_headers t ~method_:"DELETE" ~path ~body:"" in
  H.delete_json ~headers t.http path cancel_response_of_yojson []

let cancel_market_orders t ?market ?asset_id () =
  let path = "/cancel-market-orders" in
  let headers = get_auth_headers t ~method_:"DELETE" ~path ~body:"" in
  [] |> H.add "market" market |> H.add "asset_id" asset_id
  |> H.delete_json ~headers t.http path cancel_response_of_yojson

(** {1 Trades} *)

let get_trades t ?id ?taker ?maker ?market ?before ?after () =
  let path = "/data/trades" in
  let headers = get_auth_headers t ~method_:"GET" ~path ~body:"" in
  [] |> H.add "id" id |> H.add "taker" taker |> H.add "maker" maker
  |> H.add "market" market |> H.add "before" before |> H.add "after" after
  |> H.get_json_list ~headers t.http path clob_trade_of_yojson
