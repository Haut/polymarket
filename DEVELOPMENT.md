# Development Guide

Coding conventions and patterns for the Polymarket OCaml SDK.

## Naming Conventions

We follow **Jane Street conventions** (safe by default):

| Pattern | Returns | Example |
|---------|---------|---------|
| `foo` | `Result` or `option` | `Address.make`, `Builder.build` |
| `foo_opt` | `option` | `Signature_type.of_int_opt` |
| `foo_exn` | raises exception | `Address.make_exn`, `Builder.build_exn` |

The easy-to-type name should be the safe one. You explicitly opt into exceptions.

```ocaml
(* Good: safe by default *)
let address = Address.make user_input in  (* Returns Result *)
match address with
| Ok addr -> use addr
| Error msg -> handle_error msg

(* When you know it's valid *)
let addr = Address.make_exn "0x1234..." (* Raises on invalid *)
```

## Error Handling

### JSON Parsing

Use `Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error` for structured errors:

```ocaml
let t_of_yojson json =
  match json with
  | `String s -> parse s
  | _ ->
      raise
        (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
           (Failure "expected string", json))
```

### API Client Initialization

Return `Result` for operations that can fail during setup:

```ocaml
type init_error = Ca_certs_error of string | Tls_config_error of string

let create ~sw ~net ~rate_limiter () : (t, init_error) result = ...

let create_exn ~sw ~net ~rate_limiter () : t =
  match create ~sw ~net ~rate_limiter () with
  | Ok t -> t
  | Error e -> failwith (string_of_init_error e)
```

### API Responses

All API calls return `(response, error) result`:

```ocaml
match Gamma.get_markets client ~limit:10 () with
| Ok markets -> process markets
| Error err -> Logger.error "API" (Gamma.error_to_string err)
```

## Module Organization

### Directory Structure

```
lib/
├── polymarket/           # Main SDK
│   ├── common/           # Shared types, auth, crypto
│   ├── clob/             # CLOB API client
│   ├── gamma/            # Gamma API client
│   ├── data/             # Data API client
│   ├── rfq/              # RFQ API client
│   ├── wss/              # WebSocket (market/user channels)
│   └── rtds/             # Real-time data streams
├── http/                 # HTTP client infrastructure
├── ws/                   # WebSocket infrastructure
└── rate_limiter/         # Rate limiting
```

### Interface Files (.mli)

Every public module should have a `.mli` file that:
- Documents the public API
- Hides implementation details
- Provides type documentation

```ocaml
(* client.mli *)
type t
(** The API client type *)

val create : ... -> (t, init_error) result
(** Create a client. @return Ok on success, Error on TLS failure *)
```

## Type Design

### Primitive Wrappers

Use abstract types with validation for domain values:

```ocaml
module Address : sig
  type t
  val make : string -> (t, string) result
  val make_exn : string -> t
  val to_string : t -> string
end
```

### Enums with PPX

Use `[@@deriving enum]` for enums that need string/int conversion:

```ocaml
module Side = struct
  type t = Buy | Sell [@@deriving enum]
end
(* Generates: to_string, of_string, of_string_opt, etc. *)
```

### Typestate Pattern

For clients with authentication levels, use phantom types:

```ocaml
type unauthed = { http : H.t }
type l1 = { http : H.t; private_key : key; address : string }
type l2 = { http : H.t; private_key : key; address : string; creds : creds }

(* Functions require specific auth level *)
val get_order_book : unauthed -> ...  (* Public endpoint *)
val create_api_key : l1 -> ...        (* Requires L1 auth *)
val create_order : l2 -> ...          (* Requires L2 auth *)
```

## Request Builder Pattern

Use the fluent builder for HTTP requests:

```ocaml
B.new_get t.http "/endpoint"
|> B.query_param "required" value
|> B.query_option "optional" string_of_int opt_value
|> B.query_bool "flag" (Some true)
|> B.fetch_json response_of_yojson
```

## Rate Limiting

Use the shared rate limiter with presets:

```ocaml
let routes = Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
let rate_limiter = Rate_limiter.create ~routes ~clock () in

(* Pass to all clients *)
let gamma = Gamma.create_exn ~sw ~net ~rate_limiter () in
let data = Data.create_exn ~sw ~net ~rate_limiter () in
```

Custom routes with the builder:

```ocaml
Rate_limiter.Builder.(
  route ()
  |> host "api.example.com"
  |> method_ "POST"
  |> path "/orders"
  |> limit ~requests:100 ~window_seconds:10.0
  |> on_limit Delay
  |> build_exn
)
```

## Testing

### Test Organization

```
test/
├── common/         # Primitives, auth tests
├── clob_api/       # CLOB types and client tests
├── gamma_api/      # Gamma types tests
├── data_api/       # Data types tests
└── wss/            # WebSocket message parsing tests
```

### Test Patterns

Use Alcotest with descriptive names:

```ocaml
let test_roundtrip () =
  let original = Side.Buy in
  let s = Side.to_string original in
  let result = Side.of_string_exn s in
  Alcotest.(check bool) "roundtrip" true (Side.equal original result)

let tests = [
  ("roundtrip", `Quick, test_roundtrip);
]
```

## Logging

Use the `Logs` library with source tags:

```ocaml
let src = Logs.Src.create "polymarket.gamma" ~doc:"Gamma API"
module Log = (val Logs.src_log src : Logs.LOG)

Log.debug (fun m -> m "Fetching markets limit=%d" limit);
Log.err (fun m -> m "Request failed: %s" (error_to_string err));
```

## Security

**Never** use `Random` for security-sensitive operations:

```ocaml
(* BAD: Predictable, insecure *)
let key = String.init 16 (fun _ -> Char.chr (Random.int 256))

(* GOOD: Cryptographically secure *)
let key = Mirage_crypto_rng.generate 16
```

## Building

```bash
dune build        # Build
dune runtest      # Test
dune fmt          # Format
dune clean        # Clean
```

## Code Review Checklist

- [ ] Functions that can fail return `Result` or `option`
- [ ] Exception-raising variants have `_exn` suffix
- [ ] No `Random` usage for security (use `mirage-crypto-rng`)
- [ ] No bare `failwith` in library code (use proper error types)
- [ ] New public APIs have `.mli` declarations
- [ ] Rate limits configured for new endpoints
- [ ] Tests added for new functionality
