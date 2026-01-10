(** Bridge API client for cross-chain deposits to Polymarket.

    This API enables users to bridge assets from various chains and swap them to
    USDC.e on Polygon for trading on Polymarket. *)

include Types
module P = Common.Primitives
module B = Polymarket_http.Request
module H = Polymarket_http.Client
module J = Polymarket_http.Json

type t = H.t
type init_error = Polymarket_http.Client.init_error

let string_of_init_error = Polymarket_http.Client.string_of_init_error
let default_base_url = "https://bridge.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
  H.create ~base_url ~sw ~net ~rate_limiter ()

(** {1 Deposit Endpoint} *)

let create_deposit_addresses t ~address () =
  B.new_post t "/deposit"
  |> B.with_body
       (J.body (J.obj [ ("address", J.string (P.Address.to_string address)) ]))
  |> B.fetch_json ~expected_fields:yojson_fields_of_deposit_response
       ~context:"deposit_response" deposit_response_of_yojson

(** {1 Supported Assets Endpoint} *)

let get_supported_assets t () =
  B.new_get t "/supported-assets"
  |> B.fetch_json ~expected_fields:yojson_fields_of_supported_assets_response
       ~context:"supported_assets_response" supported_assets_response_of_yojson
  |> Result.map (fun r -> r.supported_assets)
