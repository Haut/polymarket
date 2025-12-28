(** Typestate-authenticated HTTP client for the Polymarket CLOB API.

    See {!Client_typestate} for documentation. *)

module H = Polymarket_http.Client
module Auth = Polymarket_common.Auth
module Crypto = Polymarket_common.Crypto

let default_base_url = "https://clob.polymarket.com"

(** {1 Public Endpoints Functor} *)

module type HAS_HTTP = sig
  type t

  val http : t -> H.t
end

module Make_public (M : HAS_HTTP) = struct
  let get_order_book (t : M.t) = Endpoints.get_order_book (M.http t)
  let get_order_books (t : M.t) = Endpoints.get_order_books (M.http t)
  let get_price (t : M.t) = Endpoints.get_price (M.http t)
  let get_midpoint (t : M.t) = Endpoints.get_midpoint (M.http t)
  let get_prices (t : M.t) = Endpoints.get_prices (M.http t)
  let get_spreads (t : M.t) = Endpoints.get_spreads (M.http t)
  let get_price_history (t : M.t) = Endpoints.get_price_history (M.http t)
end

(** {1 L1 Operations Functor} *)

module type HAS_L1_AUTH = sig
  type t
  type l2_client

  val http : t -> H.t
  val private_key : t -> Crypto.private_key
  val address : t -> string

  val make_l2 :
    H.t -> Crypto.private_key -> string -> Auth.credentials -> l2_client
end

module Make_l1_ops (M : HAS_L1_AUTH) = struct
  include Make_public (M)

  let address (t : M.t) = M.address t

  let create_api_key (t : M.t) ~nonce =
    Endpoints.create_api_key (M.http t) ~private_key:(M.private_key t)
      ~address:(M.address t) ~nonce

  let derive_api_key (t : M.t) ~nonce =
    match
      Endpoints.derive_api_key (M.http t) ~private_key:(M.private_key t)
        ~address:(M.address t) ~nonce
    with
    | Ok resp ->
        let credentials = Auth.credentials_of_derive_response resp in
        let l2_client =
          M.make_l2 (M.http t) (M.private_key t) (M.address t) credentials
        in
        Ok (l2_client, resp)
    | Error e -> Error e
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

let make_l2 http private_key address credentials =
  { http; private_key; address; credentials }

(** {1 L2 Operations Functor} *)

module type HAS_L2_AUTH = sig
  include HAS_L1_AUTH

  val credentials : t -> Auth.credentials
end

module Make_l2_ops (M : HAS_L2_AUTH) = struct
  include Make_l1_ops (M)

  let credentials (t : M.t) = M.credentials t

  let delete_api_key (t : M.t) =
    Endpoints.delete_api_key (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let get_api_keys (t : M.t) =
    Endpoints.get_api_keys (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let create_order (t : M.t) =
    Endpoints.create_order (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let create_orders (t : M.t) =
    Endpoints.create_orders (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let get_order (t : M.t) =
    Endpoints.get_order (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let get_orders (t : M.t) =
    Endpoints.get_orders (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let cancel_order (t : M.t) =
    Endpoints.cancel_order (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let cancel_orders (t : M.t) =
    Endpoints.cancel_orders (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let cancel_all (t : M.t) =
    Endpoints.cancel_all (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let cancel_market_orders (t : M.t) =
    Endpoints.cancel_market_orders (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)

  let get_trades (t : M.t) =
    Endpoints.get_trades (M.http t) ~credentials:(M.credentials t)
      ~address:(M.address t)
end

(** {1 Unauthenticated Client} *)

module Unauthed = struct
  type t = unauthed

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    { http }

  include Make_public (struct
    type t = unauthed

    let http (t : t) = t.http
  end)
end

(** {1 L1-Authenticated Client} *)

module L1 = struct
  type t = l1

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    let address = Crypto.private_key_to_address private_key in
    { http; private_key; address }

  include Make_l1_ops (struct
    type t = l1
    type l2_client = l2

    let http (t : t) = t.http
    let private_key (t : t) = t.private_key
    let address (t : t) = t.address
    let make_l2 = make_l2
  end)
end

(** {1 L2-Authenticated Client} *)

module L2 = struct
  type t = l2

  let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter ~private_key
      ~credentials () =
    let http = H.create ~base_url ~sw ~net ~rate_limiter () in
    let address = Crypto.private_key_to_address private_key in
    { http; private_key; address; credentials }

  include Make_l2_ops (struct
    type t = l2
    type l2_client = l2

    let http (t : t) = t.http
    let private_key (t : t) = t.private_key
    let address (t : t) = t.address
    let make_l2 = make_l2
    let credentials (t : t) = t.credentials
  end)
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
