# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Install dependencies
opam install . --deps-only --with-test

# Build
dune build

# Run all tests
dune runtest

# Run tests with verbose output
dune runtest --force

# Format code (required before commit)
dune fmt

# Build and watch for changes
dune build --watch

# Generate documentation
dune build @doc

# Run a specific demo
dune exec examples/gamma_api_demo.exe
dune exec examples/clob_api_demo.exe
```

## Architecture

OCaml client library for Polymarket prediction market API. Built on Eio for async I/O.

### Three-Layer Structure

**Infrastructure** (`lib/http`, `lib/rate_limiter`, `lib/ws`):
- Generic, reusable components with no Polymarket-specific knowledge
- HTTP client with TLS and rate limiter integration via `before_request` hook
- GCRA-based rate limiting with route matching and delay/error behaviors
- WebSocket protocol with auto-reconnection and exponential backoff

**Common** (`lib/polymarket/common`):
- `primitives.ml`: Validated types (Address, Hash64, Timestamp, Decimal) with typed validation errors
- `crypto.ml`: EIP-712, HMAC-SHA256, keccak256, private key to address derivation
- `auth.ml`: L1 (EIP-712) and L2 (HMAC-SHA256) authentication header builders
- `rate_limit_presets.ml`: Pre-configured limits matching official API docs

**API Clients** (`lib/polymarket/{gamma,data,clob,rfq,wss,rtds,bridge}`):
- Each follows same structure: `client.ml`, `client.mli`, `types.ml`, `types.mli`
- Main module (`polymarket.ml`) re-exports everything with flattened structure

### CLOB Typestate Pattern

The CLOB client enforces authentication at compile time with three distinct types:
- `Clob.Unauthed.t` - public endpoints only
- `Clob.L1.t` - public + key creation (requires wallet signature)
- `Clob.L2.t` - full access including trading (requires API credentials)

Upgrade functions: `Clob.upgrade_to_l1` and `Clob.L1.derive_api_key` return new client types.

## Coding Conventions

### Naming (Jane Street Style)
- `make` / `of_*` - returns `Result` with typed error
- `unsafe_of_*` - returns value directly, for trusted sources only

### Error Handling
- API responses: always `(response, Error.t) result`
- Validation: return typed `validation_error`
- No bare `failwith` in library code

### Type Design
- Primitive wrappers: abstract types with `make`, `unsafe_of_string`, `to_string`, `equal`, `pp`, yojson converters
- Enums: use `[@@deriving enum]` (custom PPX in `ppx/ppx_polymarket_enum`) - generates UPPERCASE strings by default, use `[@value "custom"]` for custom mapping
- Response types: use `ppx_yojson_conv` with `[@yojson.option]` for optional fields

### Request Builder Pattern
```ocaml
open Polymarket_http.Request
new_get t.http "/events"
|> query_option "limit" string_of_int limit
|> query_add "tag_slug" tag_slug
|> fetch_json_list event_of_yojson
```

## Testing

Tests use Alcotest. Structure mirrors lib: `test/common/`, `test/gamma_api/`, etc.

Run specific test file by editing `test/test_runner.ml` to include only desired suites.

Test patterns:
- Validation tests: check valid and invalid inputs with typed errors
- Roundtrip tests: JSON serialization/deserialization

## Security Notes

- Always use `Mirage_crypto_rng` for cryptographic operations, never `Random`
- Initialize RNG at startup: `Mirage_crypto_rng_unix.use_default ()`

## Environment Variables

For authenticated demos:
- `POLY_PRIVATE_KEY` - Ethereum private key (hex)
- `POLY_API_KEY`, `POLY_API_SECRET`, `POLY_API_PASSPHRASE` - API credentials for RFQ
