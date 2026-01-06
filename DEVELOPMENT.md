# Development Guide

Guide for contributing to the Polymarket OCaml SDK.

## Getting Started

### Prerequisites

- OCaml >= 5.1
- opam >= 2.0
- Dune >= 3.16

### Setup

```bash
# Clone the repository
git clone https://github.com/haut/polymarket.git
cd polymarket

# Install dependencies
opam install . --deps-only --with-test

# Build
dune build

# Run tests
dune runtest

# Format code
dune fmt
```

### Development Workflow

```bash
# Build and watch for changes
dune build --watch

# Run a specific demo
dune exec examples/gamma_api_demo.exe

# Run tests with verbose output
dune runtest --force

# Generate documentation
dune build @doc
# Open _build/default/_doc/_html/index.html
```

## Architecture

### Project Structure

```
lib/
├── http/                   HTTP client infrastructure
│   ├── client.ml           TLS-enabled HTTP with rate limiter integration
│   ├── json.ml             JSON parsing utilities
│   └── request.ml          Type-safe request builder
├── rate_limiter/           GCRA-based rate limiting
│   ├── rate_limiter.ml     Main rate limiter module
│   ├── gcra.ml             Generic Cell Rate Algorithm
│   ├── state.ml            Thread-safe state management
│   ├── matcher.ml          Route matching logic
│   └── builder.ml          Route configuration DSL
├── ws/                     WebSocket protocol
│   ├── connection.ml       Connection with auto-reconnect
│   ├── frame.ml            Frame encoding/decoding
│   └── handshake.ml        HTTP upgrade handshake
└── polymarket/             Polymarket-specific code
    ├── common/             Shared utilities
    │   ├── primitives.ml   Validated types (Address, Hash64, etc.)
    │   ├── auth.ml         L1/L2 header builders
    │   ├── crypto.ml       EIP-712, HMAC-SHA256, keccak256
    │   ├── order_signing.ml Order signature generation
    │   └── rate_limit_presets.ml API rate limit configs
    ├── gamma/              Gamma API (markets, events, search)
    ├── data/               Data API (positions, trades, leaderboards)
    ├── clob/               CLOB API (order books, trading)
    ├── rfq/                RFQ API (block trades)
    ├── wss/                WebSocket streaming
    ├── rtds/               Real-time data socket
    ├── polymarket.ml       Main module (re-exports)
    └── polymarket.mli      Public interface
```

### Layer Responsibilities

**Infrastructure** (`lib/http`, `lib/rate_limiter`, `lib/ws`)

Generic, reusable components with no Polymarket-specific knowledge:

- `http/client.ml`: Wraps cohttp-eio, integrates rate limiter via `before_request` hook
- `rate_limiter/rate_limiter.ml`: Route-based GCRA with delay/error behaviors
- `ws/connection.ml`: WebSocket with exponential backoff reconnection

**Common** (`lib/polymarket/common`)

Shared Polymarket utilities used by all API clients:

- `primitives.ml`: Type-safe wrappers with validation (`Address.make`, `Hash64.make`)
- `auth.ml`: Builds L1 (EIP-712) and L2 (HMAC-SHA256) authentication headers
- `crypto.ml`: Cryptographic operations, private key to address derivation
- `rate_limit_presets.ml`: Pre-configured limits matching official API docs

**API Clients** (`lib/polymarket/{gamma,data,clob,rfq,wss,rtds}`)

Each client follows the same structure:

```
{api}/
├── client.ml     Endpoint implementations
├── client.mli    Public interface
├── types.ml      Response types with PPX derivers
└── types.mli     Type definitions
```

### Data Flow

```
Application
    │
    ▼
API Client (Gamma.get_events)
    │
    ▼
Request Builder (query params, optional auth headers)
    │
    ▼
HTTP Client
    │
    ├── before_request() → Rate Limiter (delay or error)
    │
    ▼
cohttp-eio + tls-eio
    │
    ▼
Response Parsing (JSON → typed records)
    │
    ▼
Result<response, error>
```

### Typestate Pattern (CLOB)

The CLOB client uses distinct types to enforce authentication at compile time:

```ocaml
(* Three separate types, not a single type with modes *)
type unauthed = { http : Http.Client.t }
type l1 = { http : Http.Client.t; private_key : key; address : string }
type l2 = { http : Http.Client.t; private_key : key; address : string; creds : Auth.credentials }

(* Functions constrained to specific types *)
val get_order_book : unauthed -> ...  (* Works on any level *)
val create_api_key : l1 -> ...        (* Requires L1 or higher *)
val create_order : l2 -> ...          (* Requires L2 *)

(* Upgrade functions return new types *)
val upgrade_to_l1 : unauthed -> private_key:string -> (l1, Crypto.error) result
val upgrade_to_l2 : l1 -> credentials:Auth.credentials -> l2
```

## Coding Conventions

### Naming (Jane Street Style)

The "easy" name is the safe one:

| Pattern | Returns | Use When |
|---------|---------|----------|
| `foo` | `Result` | Default - handles invalid input |
| `unsafe_of_*` | value directly | For trusted/validated sources only |

```ocaml
(* Safe by default - returns typed error *)
match Address.make user_input with
| Ok addr -> use addr
| Error e -> handle_error (Primitives.string_of_validation_error e)

(* Unsafe - use only for trusted sources *)
let addr = Address.unsafe_of_string "0x1234..."
```

### Error Handling

**API responses**: Always return `(response, error) result`

```ocaml
match Gamma.get_events client () with
| Ok events -> process events
| Error err -> log (Error.to_string err)
```

**JSON parsing errors**: Use structured yojson errors

```ocaml
let t_of_yojson json =
  match json with
  | `String s -> parse s
  | _ ->
      raise (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
               (Failure "expected string", json))
```

**Validation errors**: Return typed errors

```ocaml
(* Primitives use validation_error *)
let make input =
  if is_valid input then Ok (create input)
  else Error (Invalid_length { type_name = "Address"; expected = 42; actual = len })

(* Crypto uses Crypto.error *)
match Crypto.sign_hash ~private_key hash with
| Ok sig -> use sig
| Error Crypto.Invalid_private_key -> handle_invalid_key ()
| Error e -> log (Crypto.string_of_error e)
```

### Module Organization

Every public module needs a `.mli` file that:
- Documents the API with odoc comments
- Hides implementation details (abstract types)
- Provides usage examples

```ocaml
(* client.mli *)
type t
(** Opaque client type. *)

val create : sw:Eio.Switch.t -> net:_ Eio.Net.t -> rate_limiter:Rate_limiter.t
            -> unit -> t
(** Create a client.

    @param sw Eio switch for resource management
    @param net Network capability
    @param rate_limiter Shared rate limiter *)

val get_events : t -> ?limit:int -> unit -> (event list, Error.t) result
(** Fetch events from the API.

    @param limit Maximum events to return (default 100) *)
```

### Request Builder Pattern

Use the chainable builder for HTTP requests:

```ocaml
open Polymarket_http.Request

new_get t.http "/events"
|> query_option "limit" string_of_int limit
|> query_option "active" string_of_bool active
|> query_add "tag_slug" tag_slug
|> fetch_json_list event_of_yojson
```

Available helpers:

| Function | Description |
|----------|-------------|
| `query_param k v` | Required string parameter |
| `query_add k opt` | Optional string parameter |
| `query_option k f opt` | Optional with converter |
| `query_bool k opt` | Boolean as "true"/"false" |
| `query_list k f list` | Join with commas |
| `query_each k f list` | Repeat parameter per value |

### Type Design

**Primitive wrappers**: Abstract types with typed validation errors

```ocaml
module Address : sig
  type t
  val make : string -> (t, validation_error) result
  val unsafe_of_string : string -> t  (* For trusted sources *)
  val to_string : t -> string
  val equal : t -> t -> bool
  val pp : Format.formatter -> t -> unit
  val of_yojson : Yojson.Safe.t -> (t, validation_error) result
  val yojson_of_t : t -> Yojson.Safe.t
end
```

**Module-based enums**: Use custom PPX for string conversion

```ocaml
module Side = struct
  type t = Buy | Sell [@@deriving polymarket_enum]
end
(* Generates: to_string, of_string, of_string_opt, equal, pp, yojson converters *)
```

**Response types**: Use ppx_yojson_conv with optional fields

```ocaml
type event = {
  id : int;
  title : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  active : bool option; [@yojson.option]
} [@@deriving yojson, show, eq]
```

## Testing

### Test Organization

```
test/
├── common/           Primitive validation tests
├── gamma_api/        Gamma type serialization
├── data_api/         Data type serialization
├── clob_api/         CLOB type validation
├── websocket_client/ WebSocket message parsing
├── test_runner.ml    Aggregates all suites
└── test_utils.ml     Shared test helpers
```

### Test Patterns

**Validation tests**: Check valid and invalid inputs

```ocaml
let valid_addresses = [
  ("lowercase", "0x1234567890abcdef1234567890abcdef12345678");
  ("uppercase", "0xABCDEF1234567890ABCDEF1234567890ABCDEF12");
]

let invalid_addresses = [
  ("too short", "0x1234");
  ("missing prefix", "1234567890abcdef1234567890abcdef12345678");
  ("non-hex", "0xGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG");
]

let test_valid () =
  List.iter (fun (name, input) ->
    match Address.make input with
    | Ok _ -> ()
    | Error e -> Alcotest.fail (Printf.sprintf "%s: %s" name e)
  ) valid_addresses

let test_invalid () =
  List.iter (fun (name, input) ->
    match Address.make input with
    | Error _ -> ()
    | Ok _ -> Alcotest.fail (Printf.sprintf "%s should fail" name)
  ) invalid_addresses
```

**Roundtrip tests**: JSON serialization

```ocaml
let test_roundtrip () =
  let original = Side.Buy in
  let json = Side.yojson_of_t original in
  let result = Side.t_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (Side.equal original result)
```

**Test registration**:

```ocaml
let tests = [
  Alcotest.test_case "valid addresses" `Quick test_valid;
  Alcotest.test_case "invalid addresses" `Quick test_invalid;
  Alcotest.test_case "roundtrip" `Quick test_roundtrip;
]
```

## Code Review Checklist

Before submitting a PR:

- [ ] Functions that can fail return `Result` with typed errors
- [ ] Unsafe variants have `unsafe_of_*` naming for trusted sources
- [ ] New public modules have `.mli` files
- [ ] Types use appropriate PPX derivers (`yojson`, `show`, `eq`)
- [ ] Rate limits configured for new endpoints
- [ ] Tests added for new functionality
- [ ] No `Random` usage for security (use `mirage-crypto-rng`)
- [ ] No bare `failwith` in library code (use Result types)

## Security

Never use `Random` for cryptographic operations:

```ocaml
(* WRONG - predictable *)
let nonce = String.init 32 (fun _ -> Char.chr (Random.int 256))

(* CORRECT - cryptographically secure *)
let nonce = Mirage_crypto_rng.generate 32
```

Always initialize the RNG at application startup:

```ocaml
let () =
  Mirage_crypto_rng_unix.use_default ();
  (* ... rest of application *)
```

## Building and Publishing

```bash
# Build
dune build

# Run tests
dune runtest

# Format
dune fmt

# Clean
dune clean

# Build docs
dune build @doc

# Create release
dune-release tag
dune-release distrib
dune-release publish
dune-release opam pkg
dune-release opam submit
```
