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

(** {1 Error Types} *)

type error = Polymarket_http.Client.error

let error_to_string = Polymarket_http.Client.error_to_string
