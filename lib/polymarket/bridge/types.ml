(** Bridge API types for Polymarket.

    These types correspond to the Polymarket Bridge API
    (https://bridge.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives
module P = Common.Primitives

(** {1 Token Type} *)

type token = {
  name : string option; [@default None]
  symbol : string option; [@default None]
  address : string option; [@default None]
  decimals : int option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Token information for supported assets *)

(** {1 Supported Asset Type} *)

type supported_asset = {
  chain_id : string option; [@default None] [@key "chainId"]
  chain_name : string option; [@default None] [@key "chainName"]
  token : token option; [@default None]
  min_checkout_usd : P.Decimal.t option; [@default None] [@key "minCheckoutUsd"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Supported asset with chain and minimum deposit information *)

(** {1 Supported Assets Response} *)

type supported_assets_response = {
  supported_assets : supported_asset list;
      [@default []] [@key "supportedAssets"]
  note : string option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from GET /supported-assets *)

(** {1 Deposit Address Types} *)

type deposit_addresses = {
  evm : P.Address.t option; [@default None]
  svm : string option; [@default None]
  btc : string option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Deposit addresses for different blockchain networks *)

type deposit_response = {
  address : deposit_addresses option; [@default None]
  note : string option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Response from POST /deposit *)

(** {1 Status Endpoint Types} *)

(** Transaction status for bridge deposits *)
module Deposit_transaction_status = struct
  type t =
    | Deposit_detected [@value "DEPOSIT_DETECTED"]
    | Processing [@value "PROCESSING"]
    | Origin_tx_confirmed [@value "ORIGIN_TX_CONFIRMED"]
    | Submitted [@value "SUBMITTED"]
    | Completed [@value "COMPLETED"]
    | Failed [@value "FAILED"]
  [@@deriving enum]
end

(** Individual deposit transaction with status *)
type deposit_transaction = {
  from_chain_id : int; [@key "fromChainId"]
  from_token_address : string; [@key "fromTokenAddress"]
  from_amount_base_unit : P.U256.t; [@key "fromAmountBaseUnit"]
  to_chain_id : int; [@key "toChainId"]
  to_token_address : P.Address.t; [@key "toTokenAddress"]
  status : Deposit_transaction_status.t;
  tx_hash : string option; [@default None] [@key "txHash"]
  created_time_ms : int64 option; [@default None] [@key "createdTimeMs"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** A single deposit transaction with chain IDs, amounts, and status *)

(** Response from GET /status/:address *)
type status_response = { transactions : deposit_transaction list }
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** List of all deposit transactions for the given address *)

(** {1 Error Types} *)

type error = Polymarket_http.Client.error

let error_to_string = Polymarket_http.Client.error_to_string
