# Polymarket OCaml Client

OCaml client library for the [Polymarket](https://polymarket.com) prediction market API.

## Features

- **Full API coverage**: Data, Gamma, CLOB, RFQ, WebSocket, and RTDS APIs
- **Type-safe**: Validated primitives, module-based enums, and compile-time authentication enforcement
- **Async I/O**: Built on [Eio](https://github.com/ocaml-multicore/eio) for efficient concurrent operations
- **Rate limiting**: Built-in GCRA algorithm with official Polymarket API limits
- **Pure-OCaml TLS**: Cross-platform compatibility via tls-eio (no OpenSSL dependency)
- **Result-based errors**: Structured error handling with `(response, error) result` returns

## Requirements

- OCaml >= 5.1
- Dune >= 3.16

## Installation

```bash
opam install polymarket
```

Or add to your `dune-project`:

```lisp
(depends
 (polymarket (>= 0.2.0)))
```

## Quick Start

```ocaml
open Polymarket

let () =
  (* Initialize RNG for TLS *)
  Mirage_crypto_rng_unix.use_default ();

  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  (* Create a shared rate limiter *)
  let routes = Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in

  (* Create a Gamma API client *)
  let client = Gamma.create ~sw ~net ~rate_limiter () in

  (* Fetch active markets *)
  match Gamma.get_markets client ~active:true ~limit:5 () with
  | Ok markets ->
    List.iter (fun (m : Gamma.Types.market) ->
      print_endline (Option.value ~default:"(no question)" m.question)
    ) markets
  | Error err ->
    print_endline ("Error: " ^ Error.to_string err)
```

## Architecture

The library is organized into three layers:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Your Application                               │
├─────────────────────────────────────────────────────────────────────┤
│  Gamma   Data   Clob   Rfq   Wss   Rtds   (API Clients)            │
├─────────────────────────────────────────────────────────────────────┤
│  Primitives │ Auth │ Crypto │ Rate_limit_presets  (Common)         │
├─────────────────────────────────────────────────────────────────────┤
│  HTTP Client   │   Rate Limiter   │   WebSocket   (Infrastructure) │
└─────────────────────────────────────────────────────────────────────┘
```

**Infrastructure** (`lib/http`, `lib/rate_limiter`, `lib/ws`):
- HTTP client with TLS and rate limiter integration
- GCRA-based rate limiting with route matching
- WebSocket protocol with auto-reconnection

**Common** (`lib/polymarket/common`):
- Validated primitive types (Address, Hash64, Timestamp, etc.)
- Cryptographic utilities (EIP-712, HMAC-SHA256)
- Authentication header builders
- Pre-configured API rate limits

**API Clients** (`lib/polymarket/{gamma,data,clob,rfq,wss,rtds}`):
- Each client wraps a specific Polymarket API
- Consistent patterns: `create`, endpoint functions, result-based returns

## Authentication

Polymarket uses two authentication levels for the CLOB API:

### L1: Wallet Authentication

Used for creating or deriving API credentials. Signs messages with your Ethereum private key using EIP-712.

```ocaml
(* Upgrade unauthenticated client to L1 *)
let l1_client = Clob.upgrade_to_l1 unauthed_client ~private_key in
Printf.printf "Wallet address: %s\n" (Clob.L1.address l1_client)
```

### L2: API Key Authentication

Used for trading operations (orders, trades). Signs requests with HMAC-SHA256 using your API credentials.

```ocaml
(* Derive API credentials from wallet (auto-upgrades to L2) *)
match Clob.L1.derive_api_key l1_client ~nonce:0 with
| Ok (l2_client, response) ->
    Printf.printf "API Key: %s\n" response.api_key;
    (* Now you can trade *)
    let _ = Clob.L2.get_orders l2_client () in
    ()
| Error err ->
    Printf.printf "Error: %s\n" (Error.to_string err)
```

### Typestate Pattern

The CLOB client enforces authentication at compile time:

```ocaml
(* Type: Clob.Unauthed.t - only public endpoints *)
let unauthed = Clob.Unauthed.create ~sw ~net ~rate_limiter () in
let _ = Clob.Unauthed.get_order_book unauthed ~token_id () in  (* OK *)
(* Clob.Unauthed.get_orders unauthed ()  -- Won't compile! *)

(* Type: Clob.L1.t - public + key creation *)
let l1 = Clob.upgrade_to_l1 unauthed ~private_key in

(* Type: Clob.L2.t - full access *)
match Clob.L1.derive_api_key l1 ~nonce:0 with
| Ok (l2, _) ->
    let _ = Clob.L2.get_orders l2 () in       (* OK - trading endpoint *)
    let _ = Clob.L2.get_order_book l2 ~token_id () in  (* OK - public still works *)
    ()
| Error _ -> ()
```

## Examples

### Fetch Market Data (Gamma API)

```ocaml
let client = Gamma.create ~sw ~net ~rate_limiter () in

(* Get markets by tag *)
match Gamma.get_events client ~tag_slug:"politics" ~limit:10 () with
| Ok events ->
    List.iter (fun (e : Gamma.Types.event) ->
      Printf.printf "Event: %s\n" (Option.value ~default:"" e.title)
    ) events
| Error err -> Printf.printf "Error: %s\n" (Error.to_string err)

(* Search across events, tags, and profiles *)
match Gamma.public_search client ~q:"bitcoin" ~limit_per_type:5 () with
| Ok results ->
    let count = match results.events with Some e -> List.length e | None -> 0 in
    Printf.printf "Found %d events\n" count
| Error err -> Printf.printf "Error: %s\n" (Error.to_string err)
```

### Track User Positions (Data API)

```ocaml
let client = Data.create ~sw ~net ~rate_limiter () in
let user = Primitives.Address.make_exn "0x1234..." in

match Data.get_positions client
  ~user
  ~sort_by:Data.Types.Position_sort_by.Cashpnl
  ~sort_direction:Primitives.Sort_dir.Desc
  ()
with
| Ok positions ->
    List.iter (fun (p : Data.Types.position) ->
      Printf.printf "%s: PnL %.2f\n"
        (Option.value ~default:"" p.title)
        (Option.value ~default:0.0 p.cash_pnl)
    ) positions
| Error err -> Printf.printf "Error: %s\n" (Error.to_string err)
```

### Get Order Book (CLOB API)

```ocaml
let client = Clob.Unauthed.create ~sw ~net ~rate_limiter () in
let token_id = "12345..." in  (* From Gamma API market.clob_token_ids *)

match Clob.Unauthed.get_order_book client ~token_id () with
| Ok book ->
    Printf.printf "Bids: %d, Asks: %d\n"
      (List.length book.bids) (List.length book.asks);
    List.iter (fun (bid : Clob.Types.order_book_entry) ->
      Printf.printf "  Bid: %s @ %s\n" bid.size bid.price
    ) book.bids
| Error err -> Printf.printf "Error: %s\n" (Error.to_string err)
```

### Stream Real-Time Data (WebSocket)

```ocaml
(* Market channel - public orderbook updates *)
let asset_ids = ["token_id_1"; "token_id_2"] in
let client = Wss.Market.connect ~sw ~net ~clock ~asset_ids () in
let stream = Wss.Market.stream client in

let rec process () =
  match Eio.Stream.take stream with
  | Wss.Types.Market (Book book) ->
      Printf.printf "Book update: %s - %d bids\n"
        book.asset_id (List.length book.bids);
      process ()
  | Wss.Types.Market (Price_change changes) ->
      Printf.printf "Price changes: %d updates\n"
        (List.length changes.price_changes);
      process ()
  | _ -> process ()
in
process ()
```

### Stream Crypto Prices (RTDS)

```ocaml
(* Connect to Binance price feed *)
let client = Rtds.Crypto_prices.connect_binance
  ~sw ~net ~clock
  ~symbols:["btcusdt"; "ethusdt"]
  ()
in
let stream = Rtds.Crypto_prices.stream client in

match Eio.Stream.take stream with
| `Binance msg ->
    Printf.printf "%s: $%.2f\n" msg.payload.symbol msg.payload.value
| _ -> ()
```

## Rate Limiting

All clients share a rate limiter that enforces Polymarket's official limits:

```ocaml
(* Create with Delay behavior (recommended) - sleeps until request allowed *)
let routes = Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
let rate_limiter = Rate_limiter.create ~routes ~clock () in

(* Or use Error behavior - returns error immediately when limited *)
let routes = Rate_limit_presets.all ~behavior:Rate_limiter.Error in
```

Share the same rate limiter across all clients:

```ocaml
let gamma = Gamma.create ~sw ~net ~rate_limiter () in
let data = Data.create ~sw ~net ~rate_limiter () in
let clob = Clob.Unauthed.create ~sw ~net ~rate_limiter () in
(* All three clients share rate limit state *)
```

Pre-configured limits match [official documentation](https://docs.polymarket.com/#/api-rate-limits):

| API | Global Limit | Notable Endpoint Limits |
|-----|--------------|------------------------|
| Data | 1000/10s | `/trades`: 200/10s, `/positions`: 150/10s |
| Gamma | 4000/10s | `/events`: 300/10s, `/markets`: 300/10s |
| CLOB | 9000/10s | Trading endpoints with burst + sustained limits |

## API Modules

| Module | Description | Auth Required |
|--------|-------------|---------------|
| `Gamma` | Markets, events, series, search, tags | None |
| `Data` | Positions, trades, leaderboards, activity | None |
| `Clob.Unauthed` | Order books, pricing, timeseries | None |
| `Clob.L1` | Create/derive API keys | Wallet (EIP-712) |
| `Clob.L2` | Orders, trades, cancellations | API Key (HMAC) |
| `Rfq` | Request for Quote block trades | API Key (HMAC) |
| `Wss.Market` | Real-time orderbook updates | None |
| `Wss.User` | Real-time trade/order notifications | API Key |
| `Rtds` | Crypto prices, comments | None |

## Sub-libraries

For finer-grained dependencies:

| Library | Description |
|---------|-------------|
| `polymarket` | Main library with full API (recommended) |
| `polymarket.common` | Primitives, auth, crypto utilities |
| `polymarket.http` | HTTP client with TLS |
| `polymarket.rate_limiter` | GCRA rate limiter |
| `polymarket.gamma` | Gamma API only |
| `polymarket.data` | Data API only |
| `polymarket.clob` | CLOB API only |
| `polymarket.rfq` | RFQ API only |
| `polymarket.wss` | WebSocket client only |
| `polymarket.rtds` | RTDS client only |

## Running the Examples

```bash
# Build everything
dune build

# Run demos
dune exec examples/gamma_api_demo.exe
dune exec examples/data_api_demo.exe
dune exec examples/clob_api_demo.exe
dune exec examples/wss_demo.exe
dune exec examples/rtds_demo.exe

# With authentication (for CLOB trading)
POLY_PRIVATE_KEY=your_hex_key dune exec examples/clob_api_demo.exe

# With full credentials (for RFQ)
POLY_PRIVATE_KEY=key \
POLY_API_KEY=api_key \
POLY_API_SECRET=secret \
POLY_API_PASSPHRASE=passphrase \
dune exec examples/rfq_demo.exe
```

## Documentation

- [API Reference](https://haut.github.io/polymarket) - Generated OCaml documentation
- [Official Polymarket Docs](https://docs.polymarket.com/) - API specifications
- [DEVELOPMENT.md](DEVELOPMENT.md) - Contributor guide
- [CHANGELOG.md](CHANGELOG.md) - Version history

## License

MIT - see [LICENSE](LICENSE) for details.
