(** Typestate-authenticated HTTP client for the Polymarket CLOB API.

    See {!Client_typestate} for documentation. *)

module H = Polymarket_http.Client
module Auth = Polymarket_common.Auth
module Crypto = Polymarket_common.Crypto

let default_base_url = "https://clob.polymarket.com"

(** {1 Public Endpoints Functor}

    Shared implementation for public endpoints across all auth levels. *)

module type HAS_HTTP = sig
  type t

  val http : t -> H.t
end

module Make_public (M : HAS_HTTP) = struct
  let get_order_book t = Endpoints.get_order_book (M.http t)
  let get_order_books t = Endpoints.get_order_books (M.http t)
  let get_price t = Endpoints.get_price (M.http t)
  let get_midpoint t = Endpoints.get_midpoint (M.http t)
  let get_prices t = Endpoints.get_prices (M.http t)
  let get_spreads t = Endpoints.get_spreads (M.http t)
  let get_price_history t = Endpoints.get_price_history (M.http t)
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

  (* L1 auth endpoints *)
  let create_api_key (t : t) ~nonce =
    Endpoints.create_api_key t.http ~private_key:t.private_key
      ~address:t.address ~nonce

  let derive_api_key (t : t) ~nonce =
    match
      Endpoints.derive_api_key t.http ~private_key:t.private_key
        ~address:t.address ~nonce
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

  (* L1 auth endpoints *)
  let create_api_key (t : t) ~nonce =
    Endpoints.create_api_key t.http ~private_key:t.private_key
      ~address:t.address ~nonce

  (* L2 auth endpoints *)
  let delete_api_key (t : t) =
    Endpoints.delete_api_key t.http ~credentials:t.credentials
      ~address:t.address

  let get_api_keys (t : t) =
    Endpoints.get_api_keys t.http ~credentials:t.credentials ~address:t.address

  let create_order (t : t) =
    Endpoints.create_order t.http ~credentials:t.credentials ~address:t.address

  let create_orders (t : t) =
    Endpoints.create_orders t.http ~credentials:t.credentials ~address:t.address

  let get_order (t : t) =
    Endpoints.get_order t.http ~credentials:t.credentials ~address:t.address

  let get_orders (t : t) =
    Endpoints.get_orders t.http ~credentials:t.credentials ~address:t.address

  let cancel_order (t : t) =
    Endpoints.cancel_order t.http ~credentials:t.credentials ~address:t.address

  let cancel_orders (t : t) =
    Endpoints.cancel_orders t.http ~credentials:t.credentials ~address:t.address

  let cancel_all (t : t) =
    Endpoints.cancel_all t.http ~credentials:t.credentials ~address:t.address

  let cancel_market_orders (t : t) =
    Endpoints.cancel_market_orders t.http ~credentials:t.credentials
      ~address:t.address

  let get_trades (t : t) =
    Endpoints.get_trades t.http ~credentials:t.credentials ~address:t.address
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
