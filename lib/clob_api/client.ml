(** Typestate-authenticated HTTP client for the Polymarket CLOB API.

    See {!Client_typestate} for documentation. *)

open Types
module H = Polymarket_http.Client

let default_base_url = "https://clob.polymarket.com"

(** {1 Internal Shared Implementations}

    These functions implement the actual API calls and are shared across all
    authentication levels. *)

module Internal = struct
  (** {2 Order Book} *)

  let get_order_book http ~token_id () =
    [ ("token_id", [ token_id ]) ]
    |> H.get_json http "/book" order_book_summary_of_yojson

  let get_order_books http ~token_ids () =
    let body =
      `List (List.map (fun id -> `Assoc [ ("token_id", `String id) ]) token_ids)
      |> Yojson.Safe.to_string
    in
    H.post_json_list http "/books" order_book_summary_of_yojson ~body []

  (** {2 Pricing} *)

  let get_price http ~token_id ~side () =
    [ ("token_id", [ token_id ]); ("side", [ Side.to_string side ]) ]
    |> H.get_json http "/price" price_response_of_yojson

  let get_midpoint http ~token_id () =
    [ ("token_id", [ token_id ]) ]
    |> H.get_json http "/midpoint" midpoint_response_of_yojson

  let get_prices http ~requests () =
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
    H.post_json http "/prices" prices_response_of_yojson ~body []

  let get_spreads http ~token_ids () =
    let body =
      `List (List.map (fun id -> `Assoc [ ("token_id", `String id) ]) token_ids)
      |> Yojson.Safe.to_string
    in
    H.post_json http "/spreads" spreads_response_of_yojson ~body []

  (** {2 Timeseries} *)

  let get_price_history http ~market ?start_ts ?end_ts ?interval ?fidelity () =
    [ ("market", [ market ]) ]
    |> H.add_option "startTs" string_of_int start_ts
    |> H.add_option "endTs" string_of_int end_ts
    |> H.add_option "interval" Interval.to_string interval
    |> H.add_option "fidelity" string_of_int fidelity
    |> H.get_json http "/prices-history" price_history_of_yojson

  (** {2 L2 Auth Headers} *)

  let get_l2_auth_headers ~credentials ~address ~method_ ~path ~body =
    Auth.build_l2_headers ~credentials ~address ~method_ ~path ~body

  (** {2 Orders (L2 only)} *)

  let create_order http ~credentials ~address ~order ~owner ~order_type () =
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
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"POST" ~path ~body
    in
    H.post_json ~headers http path create_order_response_of_yojson ~body []

  let create_orders http ~credentials ~address ~orders () =
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
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"POST" ~path ~body
    in
    H.post_json_list ~headers http path create_order_response_of_yojson ~body []

  let get_order http ~credentials ~address ~order_id () =
    let path = "/data/order/" ^ order_id in
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"GET" ~path ~body:""
    in
    H.get_json ~headers http path open_order_of_yojson []

  let get_orders http ~credentials ~address ?market ?asset_id () =
    let path = "/data/orders" in
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"GET" ~path ~body:""
    in
    [] |> H.add "market" market |> H.add "asset_id" asset_id
    |> H.get_json_list ~headers http path open_order_of_yojson

  (** {2 Cancel Orders (L2 only)} *)

  let cancel_order http ~credentials ~address ~order_id () =
    let path = "/order" in
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
    in
    [ ("orderID", [ order_id ]) ]
    |> H.delete_json ~headers http path cancel_response_of_yojson

  let cancel_orders http ~credentials ~address ~order_ids () =
    let path = "/orders" in
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
    in
    let uri = H.build_uri (H.base_url http) path [] in
    let status, resp_body =
      H.do_delete ~headers http (Uri.with_query uri [ ("orderIDs", order_ids) ])
    in
    H.handle_response status resp_body (fun body ->
        H.parse_json cancel_response_of_yojson body
        |> Result.map_error H.to_error)

  let cancel_all http ~credentials ~address () =
    let path = "/cancel-all" in
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
    in
    H.delete_json ~headers http path cancel_response_of_yojson []

  let cancel_market_orders http ~credentials ~address ?market ?asset_id () =
    let path = "/cancel-market-orders" in
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"DELETE" ~path ~body:""
    in
    [] |> H.add "market" market |> H.add "asset_id" asset_id
    |> H.delete_json ~headers http path cancel_response_of_yojson

  (** {2 Trades (L2 only)} *)

  let get_trades http ~credentials ~address ?id ?taker ?maker ?market ?before
      ?after () =
    let path = "/data/trades" in
    let headers =
      get_l2_auth_headers ~credentials ~address ~method_:"GET" ~path ~body:""
    in
    [] |> H.add "id" id |> H.add "taker" taker |> H.add "maker" maker
    |> H.add "market" market |> H.add "before" before |> H.add "after" after
    |> H.get_json_list ~headers http path clob_trade_of_yojson
end

(** {1 Client Types} *)

type unauthed = { http : H.t }
type l1 = { http : H.t; private_key : Crypto.private_key; address : string }

type l2 = {
  http : H.t;
  private_key : Crypto.private_key;
  address : string;
  credentials : Auth.credentials;
}

(** {1 Unauthenticated Client} *)

module Unauthed = struct
  type t = unauthed

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    { http }

  let get_order_book (t : t) = Internal.get_order_book t.http
  let get_order_books (t : t) = Internal.get_order_books t.http
  let get_price (t : t) = Internal.get_price t.http
  let get_midpoint (t : t) = Internal.get_midpoint t.http
  let get_prices (t : t) = Internal.get_prices t.http
  let get_spreads (t : t) = Internal.get_spreads t.http
  let get_price_history (t : t) = Internal.get_price_history t.http
end

(** {1 L1-Authenticated Client} *)

module L1 = struct
  type t = l1

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    let address = Crypto.private_key_to_address private_key in
    { http; private_key; address }

  let address (t : t) = t.address

  let create_api_key (t : t) ~nonce =
    Auth.create_api_key t.http ~private_key:t.private_key ~address:t.address
      ~nonce

  let derive_api_key (t : t) ~nonce =
    match
      Auth.derive_api_key t.http ~private_key:t.private_key ~address:t.address
        ~nonce
    with
    | Ok resp ->
        let credentials = Auth.credentials_of_derive_response resp in
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

  let get_order_book (t : t) = Internal.get_order_book t.http
  let get_order_books (t : t) = Internal.get_order_books t.http
  let get_price (t : t) = Internal.get_price t.http
  let get_midpoint (t : t) = Internal.get_midpoint t.http
  let get_prices (t : t) = Internal.get_prices t.http
  let get_spreads (t : t) = Internal.get_spreads t.http
  let get_price_history (t : t) = Internal.get_price_history t.http
end

(** {1 L2-Authenticated Client} *)

module L2 = struct
  type t = l2

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      ~credentials () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    let address = Crypto.private_key_to_address private_key in
    { http; private_key; address; credentials }

  let address (t : t) = t.address
  let credentials (t : t) = t.credentials

  (* L1 operations *)
  let create_api_key (t : t) ~nonce =
    Auth.create_api_key t.http ~private_key:t.private_key ~address:t.address
      ~nonce

  let delete_api_key (t : t) =
    Auth.delete_api_key t.http ~credentials:t.credentials ~address:t.address

  let get_api_keys (t : t) =
    Auth.get_api_keys t.http ~credentials:t.credentials ~address:t.address

  (* L2 order operations *)
  let create_order (t : t) =
    Internal.create_order t.http ~credentials:t.credentials ~address:t.address

  let create_orders (t : t) =
    Internal.create_orders t.http ~credentials:t.credentials ~address:t.address

  let get_order (t : t) =
    Internal.get_order t.http ~credentials:t.credentials ~address:t.address

  let get_orders (t : t) =
    Internal.get_orders t.http ~credentials:t.credentials ~address:t.address

  let cancel_order (t : t) =
    Internal.cancel_order t.http ~credentials:t.credentials ~address:t.address

  let cancel_orders (t : t) =
    Internal.cancel_orders t.http ~credentials:t.credentials ~address:t.address

  let cancel_all (t : t) =
    Internal.cancel_all t.http ~credentials:t.credentials ~address:t.address

  let cancel_market_orders (t : t) =
    Internal.cancel_market_orders t.http ~credentials:t.credentials
      ~address:t.address

  let get_trades (t : t) =
    Internal.get_trades t.http ~credentials:t.credentials ~address:t.address

  (* Public operations *)
  let get_order_book (t : t) = Internal.get_order_book t.http
  let get_order_books (t : t) = Internal.get_order_books t.http
  let get_price (t : t) = Internal.get_price t.http
  let get_midpoint (t : t) = Internal.get_midpoint t.http
  let get_prices (t : t) = Internal.get_prices t.http
  let get_spreads (t : t) = Internal.get_spreads t.http
  let get_price_history (t : t) = Internal.get_price_history t.http
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
