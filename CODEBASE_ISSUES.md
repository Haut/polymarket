# Codebase Analysis: Key Issues

Based on comprehensive analysis, here are the **biggest issues** with the codebase, ranked by severity.

---

## Critical

### ~~Insecure Random Number Generation~~ (FIXED)

**Files:**
- `lib/polymarket/common/order_signing.ml` - Salt generation for financial orders
- `lib/ws/handshake.ml` - WebSocket key generation
- `lib/ws/frame.ml` - WebSocket masking keys

**Status:** FIXED - Now using `Mirage_crypto_rng.generate` for cryptographically secure random bytes.

---

## High

### ~~Excessive `failwith` Instead of Result Types~~ (FIXED)

**Files:**
- `lib/polymarket/clob/types.ml`
- `lib/polymarket/wss/types.ml`
- `lib/polymarket/rtds/types.ml`
- `lib/polymarket/data/types.ml`
- `lib/polymarket/common/primitives.ml`
- `lib/ws/handshake.ml`
- `lib/ws/connection.ml`
- `lib/http/client.ml`

**Status:** FIXED - Converted to proper error handling:
- JSON parsing now uses `Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error` for structured errors
- `parse_message` functions in WSS/RTDS return `Result` types
- HTTP client `create` returns `(t, init_error) result`
- API clients (gamma, data) provide both `create` (Result) and `create_exn` (exception) variants
- Only intentional `*_exn` functions retain `failwith` (standard OCaml convention)

---

### Code Duplication

#### 1. Duplicated `find_path_to_value` function

- `lib/http/json.ml:8-24`
- `lib/http/client.ml:209-226`

The exact same 18-line function appears in both files.

#### 2. Similar order builder logic (~80% identical)

- `lib/polymarket/clob/order_builder.ml:18-85`
- `lib/polymarket/rfq/order_builder.ml:18-71`

Both have nearly identical salt generation, address extraction, and signing flows.

#### 3. Repeated client patterns

All API clients (gamma, data, clob, rfq) follow identical boilerplate.

---

## Medium

### Disabled Private Modules

**File:** `lib/polymarket/dune:33`

```
; Temporarily disabled private_modules for debugging
```

Internal modules are exposed publicly, breaking encapsulation. Users can depend on internals that should be private.

---

### No Interface Files (.mli)

The codebase has **zero `.mli` files** for library modules. All implementation details are exposed with no clear public API boundary.

**Impact:**
- No documentation of intended public interface
- Internal changes can break consumers
- IDE autocomplete shows internal functions

---

### Inconsistent Error Handling

Three different error patterns coexist:

1. **Result types** - `lib/http/client.ml`
2. **Exceptions** - Rate_limiter (`Rate_limit_exceeded`)
3. **Polymorphic variants** - `lib/polymarket/common/error.ml` (defined but largely unused)

---

### Complex Functions with 20+ Parameters

**File:** `lib/polymarket/gamma/client.ml:100-133`

`get_events` has 26 optional parameters in a single function. Similar issue in `get_markets`.

---

## Low

### Incomplete TODO

**File:** `lib/polymarket/gamma/types.ml:727`

```ocaml
created_at : string option; (* @TODO check real type*)
```

Field typed as `string` when it should likely be `Timestamp.t`.

---

### Inconsistent Module Aliases

Different files use different aliases for the same modules:

- CLOB: `H`, `B`, `J`, `Auth`, `Crypto`
- Data: `B`, `P`
- Gamma: `P`, `B`

---

## Summary

| Priority | Issue | Count | Status |
|----------|-------|-------|--------|
| Critical | Insecure RNG | 3 files | **FIXED** |
| High | failwith usage | 30+ occurrences | **FIXED** |
| High | Code duplication | ~40% of order builders | Open |
| Medium | Missing .mli files | 0 interface files | Open |
| Medium | Disabled private modules | 1 config issue | Open |
| Medium | Inconsistent errors | 3 patterns | Open |

---

## Positive Notes

The codebase has several strengths:

- Excellent use of phantom types for type safety (typestate pattern in CLOB client)
- Good module organization with clear separation of concerns
- Comprehensive logging throughout
- Well-structured rate limiting infrastructure
- Clean request builder pattern with compile-time safety
