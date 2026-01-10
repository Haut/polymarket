(** Bridge API types for Polymarket.

    These types correspond to the Polymarket Bridge API
    (https://bridge.polymarket.com). *)

module P = Common.Primitives

(** {1 Token Type} *)

type token = {
  name : string option;
  symbol : string option;
  address : string option;
  decimals : int option;
}
[@@deriving yojson, show, eq]
(** Token information for supported assets *)

(** {1 Supported Asset Type} *)

type supported_asset = {
  chain_id : string option;
  chain_name : string option;
  token : token option;
  min_checkout_usd : P.Decimal.t option;
}
[@@deriving yojson, show, eq]
(** Supported asset with chain and minimum deposit information *)

(** {1 Supported Assets Response} *)

type supported_assets_response = {
  supported_assets : supported_asset list;
  note : string option;
}
[@@deriving yojson, show, eq]
(** Response from GET /supported-assets *)

(** {1 Deposit Address Types} *)

type deposit_addresses = {
  evm : P.Address.t option;
  svm : string option;
  btc : string option;
}
[@@deriving yojson, show, eq]
(** Deposit addresses for different blockchain networks *)

type deposit_response = {
  address : deposit_addresses option;
  note : string option;
}
[@@deriving yojson, show, eq]
(** Response from POST /deposit *)

(** {1 Field Lists for Extra Field Detection} *)

val yojson_fields_of_token : string list
val yojson_fields_of_supported_asset : string list
val yojson_fields_of_supported_assets_response : string list
val yojson_fields_of_deposit_addresses : string list
val yojson_fields_of_deposit_response : string list

(** {1 Error Types} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors. *)

val error_to_string : error -> string
(** Convert error to human-readable string *)
