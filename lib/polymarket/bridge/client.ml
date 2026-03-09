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

(** {1 Withdrawal Endpoint} *)

let create_withdrawal_addresses t ~address ~to_chain_id ~to_token_address
    ~recipient_addr () =
  B.new_post t "/withdraw"
  |> B.with_body
       (J.body
          (J.obj
             [
               ("address", J.string (P.Address.to_string address));
               ("toChainId", J.string to_chain_id);
               ("toTokenAddress", J.string to_token_address);
               ("recipientAddr", J.string recipient_addr);
             ]))
  |> B.fetch_json ~expected_fields:yojson_fields_of_deposit_response
       ~context:"deposit_response" deposit_response_of_yojson

(** {1 Quote Endpoint} *)

let get_quote t ~from_amount_base_unit ~from_chain_id ~from_token_address
    ~recipient_address ~to_chain_id ~to_token_address () =
  B.new_post t "/quote"
  |> B.with_body
       (J.body
          (J.obj
             [
               ("fromAmountBaseUnit", J.string from_amount_base_unit);
               ("fromChainId", J.string from_chain_id);
               ("fromTokenAddress", J.string from_token_address);
               ("recipientAddress", J.string recipient_address);
               ("toChainId", J.string to_chain_id);
               ("toTokenAddress", J.string to_token_address);
             ]))
  |> B.fetch_json ~expected_fields:yojson_fields_of_quote_response
       ~context:"quote_response" quote_response_of_yojson

(** {1 Supported Assets Endpoint} *)

let get_supported_assets t () =
  B.new_get t "/supported-assets"
  |> B.fetch_json ~expected_fields:yojson_fields_of_supported_assets_response
       ~context:"supported_assets_response" supported_assets_response_of_yojson
  |> Result.map (fun r -> r.supported_assets)

(** {1 Status Endpoint} *)

let get_status t ~address () =
  B.new_get t (Printf.sprintf "/status/%s" address)
  |> B.fetch_json ~expected_fields:yojson_fields_of_status_response
       ~context:"status_response" status_response_of_yojson
