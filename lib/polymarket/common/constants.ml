(** Shared constants for Polymarket API clients.

    This module centralizes magic numbers and configuration values used across
    the codebase, providing documentation and a single source of truth. *)

(** {1 Polygon Network} *)

(** Polygon (formerly Matic) mainnet chain ID.
    @see <https://chainlist.org/chain/137> Polygon Mainnet *)
let polygon_chain_id = 137

(** {1 Token Decimals} *)

(** USDC and CTF tokens use 6 decimal places on Polygon. This scale factor
    converts between human-readable amounts and on-chain representation. For
    example, 1.0 USDC = 1_000_000 on-chain units. *)
let token_scale = 1_000_000.0

(** Number of decimal places for USDC/CTF tokens. *)
let token_decimals = 6

(** {1 Contract Addresses} *)

(** Zero address used for open orders (no specific taker). *)
let zero_address = "0x0000000000000000000000000000000000000000"

(** CTF Exchange contract address on Polygon mainnet.
    @see <https://polygonscan.com/address/0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E>
*)
let ctf_exchange_address = "0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E"

(** {1 Time Durations} *)

(** One year in seconds (365 days). Used as default order expiration. *)
let one_year_seconds = 31_536_000.0

(** {1 WebSocket Configuration} *)

(** RTDS (Real-Time Data Socket) recommended ping interval in seconds. Per
    Polymarket documentation, clients should ping every 5 seconds. *)
let rtds_ping_interval = 5.0

(** Default buffer size for WebSocket message streams. Allows buffering up to
    1000 messages before backpressure. *)
let message_buffer_size = 1000

(** {1 EIP-712 Domain Constants} *)

(** CLOB authentication domain name for EIP-712 signing. *)
let clob_domain_name = "ClobAuthDomain"

(** CLOB authentication domain version. *)
let clob_domain_version = "1"

(** The attestation message signed for CLOB authentication. *)
let auth_message_text = "This message attests that I control the given wallet"

(** CTF Exchange domain name for order signing. *)
let ctf_exchange_domain_name = "Polymarket CTF Exchange"

(** CTF Exchange domain version. *)
let ctf_exchange_domain_version = "1"
