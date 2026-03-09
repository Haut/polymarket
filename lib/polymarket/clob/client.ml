(** Typestate-authenticated HTTP client for the Polymarket CLOB API.

    See {!Client_typestate} for documentation. *)

module H = Polymarket_http.Client
module B = Polymarket_http.Request
module J = Polymarket_http.Json
module Auth = Common.Auth
module Crypto = Common.Crypto
open Types

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
type init_error = H.init_error

let private_key_of_string = Crypto.private_key_of_string
let error_to_string = H.error_to_string
let init_error_to_string = H.string_of_init_error

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
  let get_time t () =
    B.new_get (M.http t) "/time"
    |> B.fetch_json (function
      | `Int i -> Int64.of_int i
      | `Intlit s -> Int64.of_string s
      | json ->
          raise
            (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
               (Failure "expected integer", json)))

  let get_order_book t ~token_id () =
    B.new_get (M.http t) "/book"
    |> B.query_param "token_id" token_id
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_order_book_summary
         ~context:"order_book_summary" order_book_summary_of_yojson

  let get_order_books t ~token_ids () =
    B.new_post (M.http t) "/books"
    |> B.with_body (J.list_single_field "token_id" token_ids)
    |> B.fetch_json_list
         ~expected_fields:Types.yojson_fields_of_order_book_summary
         ~context:"order_book_summary" order_book_summary_of_yojson

  let get_price t ~token_id ~side () =
    B.new_get (M.http t) "/price"
    |> B.query_param "token_id" token_id
    |> B.query_param "side" (Side.to_string side)
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_price_response
         ~context:"price_response" price_response_of_yojson

  let get_midpoint t ~token_id () =
    B.new_get (M.http t) "/midpoint"
    |> B.query_param "token_id" token_id
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_midpoint_response
         ~context:"midpoint_response" midpoint_response_of_yojson

  let get_prices t ~requests () =
    B.new_post (M.http t) "/prices"
    |> B.with_body
         (J.list
            (fun (token_id, side) ->
              J.obj
                (("token_id", J.string token_id)
                ::
                (match side with
                | Some s -> [ ("side", J.string (Side.to_string s)) ]
                | None -> [])))
            requests)
    |> B.fetch_json prices_response_of_yojson

  let get_prices_query t ~token_ids ~sides () =
    B.new_get (M.http t) "/prices"
    |> B.query_param "token_ids" (String.concat "," token_ids)
    |> B.query_param "sides" (String.concat "," (List.map Side.to_string sides))
    |> B.fetch_json prices_response_of_yojson

  let get_midpoints t ~token_ids () =
    let body = J.list_single_field "token_id" token_ids in
    B.new_post (M.http t) "/midpoints"
    |> B.with_body body
    |> B.fetch_json midpoints_response_of_yojson

  let get_midpoints_query t ~token_ids () =
    B.new_get (M.http t) "/midpoints"
    |> B.query_param "token_ids" (String.concat "," token_ids)
    |> B.fetch_json midpoints_response_of_yojson

  let get_spread t ~token_id () =
    B.new_get (M.http t) "/spread"
    |> B.query_param "token_id" token_id
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_spread_response
         ~context:"spread_response" spread_response_of_yojson

  let get_spreads t ~token_ids () =
    let body = J.list_single_field "token_id" token_ids in
    B.new_post (M.http t) "/spreads"
    |> B.with_body body
    |> B.fetch_json spreads_response_of_yojson

  let get_last_trades_prices t ~token_ids () =
    let body = J.list_single_field "token_id" token_ids in
    B.new_post (M.http t) "/last-trades-prices"
    |> B.with_body body
    |> B.fetch_json_list
         ~expected_fields:Types.yojson_fields_of_last_trade_price_entry
         ~context:"last_trade_price_entry" last_trade_price_entry_of_yojson

  let get_last_trades_prices_query t ~token_ids () =
    B.new_get (M.http t) "/last-trades-prices"
    |> B.query_param "token_ids" (String.concat "," token_ids)
    |> B.fetch_json_list
         ~expected_fields:Types.yojson_fields_of_last_trade_price_entry
         ~context:"last_trade_price_entry" last_trade_price_entry_of_yojson

  let get_fee_rate t ?token_id () =
    B.new_get (M.http t) "/fee-rate"
    |> B.query_option "token_id" Fun.id token_id
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_fee_rate_response
         ~context:"fee_rate_response" fee_rate_response_of_yojson

  let get_fee_rate_by_path t ~token_id () =
    B.new_get (M.http t) ("/fee-rate/" ^ token_id)
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_fee_rate_response
         ~context:"fee_rate_response" fee_rate_response_of_yojson

  let get_tick_size t ?token_id () =
    B.new_get (M.http t) "/tick-size"
    |> B.query_option "token_id" Fun.id token_id
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_tick_size_response
         ~context:"tick_size_response" tick_size_response_of_yojson

  let get_tick_size_by_path t ~token_id () =
    B.new_get (M.http t) ("/tick-size/" ^ token_id)
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_tick_size_response
         ~context:"tick_size_response" tick_size_response_of_yojson

  let get_price_history t ~market ?start_ts ?end_ts ?interval ?fidelity () =
    B.new_get (M.http t) "/prices-history"
    |> B.query_param "market" market
    |> B.query_option "startTs" string_of_int start_ts
    |> B.query_option "endTs" string_of_int end_ts
    |> B.query_option "interval" Interval.to_string interval
    |> B.query_option "fidelity" string_of_int fidelity
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_price_history
         ~context:"price_history" price_history_of_yojson

  let get_simplified_markets t ?next_cursor () =
    B.new_get (M.http t) "/simplified-markets"
    |> B.query_add "next_cursor" next_cursor
    |> B.fetch_json
         ~expected_fields:Types.yojson_fields_of_simplified_markets_response
         ~context:"simplified_markets_response"
         simplified_markets_response_of_yojson

  let get_sampling_markets t ?next_cursor () =
    B.new_get (M.http t) "/sampling-markets"
    |> B.query_add "next_cursor" next_cursor
    |> B.fetch_json ~expected_fields:Types.yojson_fields_of_markets_response
         ~context:"markets_response" markets_response_of_yojson

  let get_sampling_simplified_markets t ?next_cursor () =
    B.new_get (M.http t) "/sampling-simplified-markets"
    |> B.query_add "next_cursor" next_cursor
    |> B.fetch_json
         ~expected_fields:Types.yojson_fields_of_simplified_markets_response
         ~context:"simplified_markets_response"
         simplified_markets_response_of_yojson

  let get_current_rebated_fees t ~date ~maker_address () =
    B.new_get (M.http t) "/rebates/current"
    |> B.query_param "date" date
    |> B.query_param "maker_address" maker_address
    |> B.fetch_json_list ~expected_fields:Types.yojson_fields_of_rebated_fees
         ~context:"rebated_fees" rebated_fees_of_yojson
end

(** {1 Unauthenticated Client} *)

module Unauthed = struct
  type t = unauthed

  include Make_public (struct
    type t = unauthed

    let http (t : t) = t.http
  end)

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
    match H.create ~base_url ~sw ~net ~rate_limiter () with
    | Ok http -> Ok ({ http } : t)
    | Error e -> Error e
end

(** {1 L1-Authenticated Client} *)

module L1 = struct
  type t = l1

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      () =
    match H.create ~base_url ~sw ~net ~rate_limiter () with
    | Error e -> Error e
    | Ok http -> (
        match Crypto.private_key_to_address private_key with
        | Error e -> Error (H.Crypto_error (Crypto.string_of_error e))
        | Ok address -> Ok ({ http; private_key; address } : t))

  let address (t : t) = t.address

  include Make_public (struct
    type t = l1

    let http (t : t) = t.http
  end)

  let create_api_key (t : t) ~nonce =
    let req = B.new_post t.http "/auth/api-key" |> B.with_body "{}" in
    match
      Auth.with_l1_auth ~private_key:t.private_key ~address:t.address ~nonce req
    with
    | Error e -> Error (H.to_error (Crypto.string_of_error e))
    | Ok r -> B.fetch_json Auth.api_key_response_of_yojson r

  let derive_api_key (t : t) ~nonce =
    let req = B.new_get t.http "/auth/derive-api-key" in
    match
      Auth.with_l1_auth ~private_key:t.private_key ~address:t.address ~nonce req
    with
    | Error e -> Error (H.to_error (Crypto.string_of_error e))
    | Ok r -> (
        match B.fetch_json Auth.api_key_response_of_yojson r with
        | Error e -> Error e
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
            Ok (l2_client, resp))
end

(** {1 L2-Authenticated Client} *)

module L2 = struct
  type t = l2

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      ~credentials () =
    match H.create ~base_url ~sw ~net ~rate_limiter () with
    | Error e -> Error e
    | Ok http -> (
        match Crypto.private_key_to_address private_key with
        | Error e -> Error (H.Crypto_error (Crypto.string_of_error e))
        | Ok address -> Ok ({ http; private_key; address; credentials } : t))

  let address (t : t) = t.address
  let credentials (t : t) = t.credentials

  include Make_public (struct
    type t = l2

    let http (t : t) = t.http
  end)

  (** Helper to run L1-authenticated requests *)
  let with_l1_request req ~private_key ~address ~nonce f =
    match Auth.with_l1_auth ~private_key ~address ~nonce req with
    | Error e -> Error (H.to_error (Crypto.string_of_error e))
    | Ok r -> f r

  (** Helper to run L2-authenticated requests *)
  let with_l2_request req ~credentials ~address f =
    match Auth.with_l2_auth ~credentials ~address req with
    | Error e -> Error (H.to_error (Crypto.string_of_error e))
    | Ok r -> f r

  let create_api_key (t : t) ~nonce =
    let req = B.new_post t.http "/auth/api-key" |> B.with_body "{}" in
    with_l1_request req ~private_key:t.private_key ~address:t.address ~nonce
      (B.fetch_json Auth.api_key_response_of_yojson)

  let delete_api_key (t : t) =
    let req = B.new_delete t.http "/auth/api-key" in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      B.fetch_unit

  let get_api_keys (t : t) =
    let req = B.new_get t.http "/auth/api-keys" in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json_list (fun json ->
           match json with
           | `String s -> s
           | _ ->
               raise
                 (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
                    (Failure "Expected string in API keys list", json))))

  let create_order (t : t) ~order ~owner ~order_type ?defer_exec () =
    let fields =
      [
        ("order", yojson_of_signed_order order);
        ("owner", J.string owner);
        ("orderType", J.string (Order_type.to_string order_type));
      ]
      @
      match defer_exec with
      | Some b -> [ ("deferExec", `Bool b) ]
      | None -> []
    in
    let req =
      B.new_post t.http "/order" |> B.with_body (J.body (J.obj fields))
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json
         ~expected_fields:Types.yojson_fields_of_create_order_response
         ~context:"create_order_response" create_order_response_of_yojson)

  let create_orders (t : t) ~orders () =
    let req =
      B.new_post t.http "/orders"
      |> B.with_body
           (J.list
              (fun (order, owner, order_type, defer_exec) ->
                J.obj
                  ([
                     ("order", yojson_of_signed_order order);
                     ("owner", J.string owner);
                     ("orderType", J.string (Order_type.to_string order_type));
                   ]
                  @
                  match defer_exec with
                  | Some b -> [ ("deferExec", `Bool b) ]
                  | None -> []))
              orders)
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json_list
         ~expected_fields:Types.yojson_fields_of_create_order_response
         ~context:"create_order_response" create_order_response_of_yojson)

  let get_order (t : t) ~order_id () =
    let req = B.new_get t.http ("/order/" ^ order_id) in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json ~expected_fields:Types.yojson_fields_of_open_order
         ~context:"open_order" open_order_of_yojson)

  let get_orders (t : t) ?id ?market ?asset_id ?next_cursor () =
    let req =
      B.new_get t.http "/orders" |> B.query_add "id" id
      |> B.query_add "market" market
      |> B.query_add "asset_id" asset_id
      |> B.query_add "next_cursor" next_cursor
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json ~expected_fields:Types.yojson_fields_of_orders_response
         ~context:"orders_response" orders_response_of_yojson)

  let get_order_scoring (t : t) ~order_id () =
    let req =
      B.new_get t.http "/order-scoring" |> B.query_param "order_id" order_id
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json
         ~expected_fields:Types.yojson_fields_of_order_scoring_response
         ~context:"order_scoring_response" order_scoring_response_of_yojson)

  let cancel_order (t : t) ~order_id () =
    let req =
      B.new_delete_with_body t.http "/order"
      |> B.with_body (J.body (J.obj [ ("orderID", J.string order_id) ]))
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json cancel_response_of_yojson)

  let cancel_orders (t : t) ~order_ids () =
    let req =
      B.new_delete_with_body t.http "/orders"
      |> B.with_body (J.list J.string order_ids)
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json cancel_response_of_yojson)

  let cancel_all (t : t) () =
    let req = B.new_delete t.http "/cancel-all" in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json cancel_response_of_yojson)

  let cancel_market_orders (t : t) ~market ~asset_id () =
    let req =
      B.new_delete_with_body t.http "/cancel-market-orders"
      |> B.with_body
           (J.body
              (J.obj
                 [
                   ("market", J.string market); ("asset_id", J.string asset_id);
                 ]))
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json cancel_response_of_yojson)

  let get_trades (t : t) ~maker_address ?id ?market ?asset_id ?before ?after
      ?next_cursor () =
    let req =
      B.new_get t.http "/trades"
      |> B.query_param "maker_address" maker_address
      |> B.query_add "id" id
      |> B.query_add "market" market
      |> B.query_add "asset_id" asset_id
      |> B.query_add "before" before
      |> B.query_add "after" after
      |> B.query_add "next_cursor" next_cursor
    in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json ~expected_fields:Types.yojson_fields_of_trades_response
         ~context:"trades_response" trades_response_of_yojson)

  let send_heartbeat (t : t) () =
    let req = B.new_post t.http "/heartbeats" |> B.with_body "{}" in
    with_l2_request req ~credentials:t.credentials ~address:t.address
      (B.fetch_json ~expected_fields:Types.yojson_fields_of_heartbeat_response
         ~context:"heartbeat_response" heartbeat_response_of_yojson)
end

(** {1 State Transitions} *)

let upgrade_to_l1 (t : unauthed) ~private_key =
  match Crypto.private_key_to_address private_key with
  | Error msg -> Error msg
  | Ok address -> Ok ({ http = t.http; private_key; address } : l1)

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
