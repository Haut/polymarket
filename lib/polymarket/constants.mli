(** Shared constants for Polymarket API clients.

    This module centralizes magic numbers and configuration values used across
    the codebase, providing documentation and a single source of truth. *)

(** {1 Polygon Network} *)

val polygon_chain_id : int
(** Polygon (formerly Matic) mainnet chain ID (137).
    @see <https://chainlist.org/chain/137> Polygon Mainnet *)

(** {1 Token Decimals} *)

val token_scale : float
(** USDC and CTF tokens use 6 decimal places on Polygon. This scale factor
    (1_000_000.0) converts between human-readable amounts and on-chain
    representation. *)

val token_decimals : int
(** Number of decimal places for USDC/CTF tokens (6). *)

(** {1 Contract Addresses} *)

val zero_address : string
(** Zero address used for open orders (no specific taker). *)

val ctf_exchange_address : string
(** CTF Exchange contract address on Polygon mainnet.
    @see <https://polygonscan.com/address/0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E>
*)

(** {1 Time Durations} *)

val one_year_seconds : float
(** One year in seconds (31_536_000.0). Used as default order expiration. *)

(** {1 WebSocket Configuration} *)

val rtds_ping_interval : float
(** RTDS (Real-Time Data Socket) recommended ping interval (5.0 seconds). *)

val message_buffer_size : int
(** Default buffer size for WebSocket message streams (1000). *)

(** {1 EIP-712 Domain Constants} *)

val clob_domain_name : string
(** CLOB authentication domain name for EIP-712 signing ("ClobAuthDomain"). *)

val clob_domain_version : string
(** CLOB authentication domain version ("1"). *)

val auth_message_text : string
(** The attestation message signed for CLOB authentication. *)

val ctf_exchange_domain_name : string
(** CTF Exchange domain name for order signing ("Polymarket CTF Exchange"). *)

val ctf_exchange_domain_version : string
(** CTF Exchange domain version ("1"). *)
