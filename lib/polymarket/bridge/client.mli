(** Bridge API client for cross-chain deposits to Polymarket.

    This API enables users to bridge assets from various chains and swap them to
    USDC.e on Polygon for trading on Polymarket.

    {1 Overview}

    Polymarket uses USDC.e (Bridged USDC) on Polygon as collateral for all
    trading activities. When you deposit assets from other chains:

    1. You can deposit from various supported chains (Ethereum, Solana,
    Arbitrum, Base, Bitcoin, etc.) 2. Your assets are automatically
    bridged/swapped to USDC.e on Polygon 3. USDC.e is credited to your
    Polymarket wallet 4. You can then trade on any Polymarket market

    {1 Example}

    {[
      (* Create the client *)
      let client =
        Bridge.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter ()
        |> Result.get_ok
      in

      (* Get deposit addresses for your wallet *)
      let address = Primitives.Address.make "0x..." |> Result.get_ok in
      let deposit = Bridge.create_deposit_addresses client ~address () in

      (* Get list of supported assets *)
      let assets = Bridge.get_supported_assets client ()
    ]} *)

include module type of struct
  include Types
end

type t
(** The Bridge API client type. *)

type init_error = Polymarket_http.Client.init_error
(** TLS/CA initialization error type *)

val string_of_init_error : init_error -> string
(** Convert initialization error to string *)

val default_base_url : string
(** Default base URL: https://bridge.polymarket.com *)

val create :
  ?base_url:string ->
  sw:Eio.Switch.t ->
  net:'a Eio.Net.t ->
  rate_limiter:Rate_limiter.t ->
  unit ->
  (t, init_error) result
(** Create a Bridge API client.
    @param base_url Override the default base URL
    @param sw Eio switch for resource management
    @param net Eio network capability
    @param rate_limiter Rate limiter for API requests
    @return Ok client on success, Error on TLS initialization failure *)

(** {1 Deposit Endpoint} *)

val create_deposit_addresses :
  t ->
  address:Common.Primitives.Address.t ->
  unit ->
  (deposit_response, error) result
(** Create unique deposit addresses for bridging assets to Polymarket.

    {b How it works:} 1. Request deposit addresses for your Polymarket wallet 2.
    Receive deposit addresses for each blockchain type (EVM, Solana, Bitcoin) 3.
    Send assets to the appropriate deposit address for your source chain 4.
    Assets are automatically bridged and swapped to USDC.e on Polygon 5. USDC.e
    is credited to your Polymarket wallet for trading

    @param address Your Polymarket wallet address (required)
    @return Deposit addresses for EVM, SVM, and BTC networks *)

(** {1 Supported Assets Endpoint} *)

val get_supported_assets : t -> unit -> (supported_asset list, error) result
(** Retrieve all supported chains and tokens for deposits.

    Each asset has a [min_checkout_usd] field indicating the minimum deposit
    amount required in USD. Make sure your deposit meets this minimum to avoid
    transaction failures.

    Supported chains include:
    - Ethereum (chainId: "1")
    - Polygon (chainId: "137")
    - Arbitrum (chainId: "42161")
    - Base (chainId: "8453")
    - Solana
    - Bitcoin

    @return List of supported assets with chain information and minimum amounts
*)

(** {1 Status Endpoint} *)

val get_status : t -> address:string -> unit -> (status_response, error) result
(** Get the transaction status for all deposits associated with a given deposit
    address.

    The address parameter accepts any deposit address type (EVM, Solana, or
    Bitcoin). Returns a list of all deposit transactions with their current
    status.

    @param address The deposit address to check status for (EVM, SVM, or BTC)
    @return List of deposit transactions with chain IDs, amounts, and status *)
