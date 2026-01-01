# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-01-01

### Added
- RTDS (Real-Time Data Socket) client for real-time crypto prices (Binance, Chainlink) and comments streaming
- RFQ (Request for Quote) API client with order builder for requesting and filling quotes
- Type-safe HTTP request builder with phantom types for compile-time auth enforcement
- Per-module `Logs.Src` structured logging for fine-grained log filtering
- PPX enum deriver (`ppx_polymarket_enum`) for zero-boilerplate string enums
- Extra field detection logging for API responses (forward compatibility warnings)
- WebSocket high-level client modules (`Market`, `User`) with subscription management
- Route-based rate limiter with GCRA algorithm and configurable behavior (delay/error)
- `with_l1_auth` and `with_l2_auth` helpers to Builder for ergonomic authentication
- Order builder modules for CLOB and RFQ with crypto signing

### Changed
- Migrated logging from `Common.Logger` to per-module `Logs.Src` for better filtering
- Reorganized lib into `generic/` (reusable) and `polymarket/` (API-specific) directories
- Made `private_key` abstract with `Private` submodule pattern for type safety
- Renamed WSS module to `wss_api` for consistency with other API modules
- Simplified types and consolidated API client structure

### Fixed
- Thread-safe hash table access in rate limiter state
- Regex patterns in odoc comments causing doc generation errors

## [0.1.0] - 2024-12-15

### Added
- CLOB API client with order book, pricing, and trading endpoints
- L1 authentication (EIP-712 wallet signing) for API key management
- L2 authentication (HMAC-SHA256) for authenticated trading endpoints
- Crypto module with keccak256, HMAC-SHA256, secp256k1 signing, and address derivation
- CLOB API demo (`examples/clob_api_demo.ml`)
- POST and DELETE methods with custom headers to Http_client
- Gamma API client with full endpoint coverage (teams, tags, events, markets, series, comments, profiles, sports, search)
- Structured logging via `Common.Logger` with configurable log levels (debug, info, off)
- `POLYMARKET_LOG_LEVEL` environment variable for controlling log output
- File output support for logging via `POLYMARKET_LOG_FILE` environment variable
- Gamma API demo (`examples/gamma_api_demo.ml`)
- TLS support for secure API connections
- Testing framework for reliable development
- Live demo functionality
- Error handling and JSON helpers to Http_client
- Generic Http_client module for reuse across APIs

### Changed
- Restructured lib directory for multi-API support
- Moved Http_client to its own module (`lib/http_client/`)
- Consolidated logging into `Common.Logger` module
- Refactored client to use pipe pattern for parameter building

### Removed
- Redundant tests now covered by dependency libraries
