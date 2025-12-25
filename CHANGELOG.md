# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
