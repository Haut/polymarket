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

(** {1 Quote Types} *)

type fee_breakdown = {
  app_fee_label : string option;
  app_fee_percent : float option;
  app_fee_usd : float option;
  fill_cost_percent : float option;
  fill_cost_usd : float option;
  gas_usd : float option;
  max_slippage : float option;
  min_received : float option;
  swap_impact : float option;
  swap_impact_usd : float option;
  total_impact : float option;
  total_impact_usd : float option;
}
[@@deriving yojson, show, eq]
(** Breakdown of estimated fees for a quote *)

type quote_response = {
  est_checkout_time_ms : int option;
  est_fee_breakdown : fee_breakdown option;
  est_input_usd : float option;
  est_output_usd : float option;
  est_to_token_base_unit : string option;
  quote_id : string option;
}
[@@deriving yojson, show, eq]
(** Response from POST /quote *)

(** {1 Status Endpoint Types} *)

(** Transaction status for bridge deposits *)
module Deposit_transaction_status : sig
  type t =
    | Deposit_detected
    | Processing
    | Origin_tx_confirmed
    | Submitted
    | Completed
    | Failed

  val to_string : t -> string
  val of_string : string -> t
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** Individual deposit transaction with status *)
type deposit_transaction = {
  from_chain_id : string;
  from_token_address : string;
  from_amount_base_unit : string;
  to_chain_id : string;
  to_token_address : string;
  status : Deposit_transaction_status.t;
  tx_hash : string option;
  created_time_ms : float option;
}
[@@deriving yojson, show, eq]
(** A single deposit transaction with chain IDs, amounts, and status *)

(** Response from GET /status/:address *)
type status_response = { transactions : deposit_transaction list }
[@@deriving yojson, show, eq]
(** List of all deposit transactions for the given address *)

(** {1 Field Lists for Extra Field Detection} *)

val yojson_fields_of_token : string list
val yojson_fields_of_supported_asset : string list
val yojson_fields_of_supported_assets_response : string list
val yojson_fields_of_deposit_addresses : string list
val yojson_fields_of_deposit_response : string list
val yojson_fields_of_fee_breakdown : string list
val yojson_fields_of_quote_response : string list
val yojson_fields_of_deposit_transaction : string list
val yojson_fields_of_status_response : string list

(** {1 Error Types} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors. *)

val error_to_string : error -> string
(** Convert error to human-readable string *)
