# Polymarket OCaml Client

OCaml client library for the [Polymarket](https://polymarket.com) prediction market API.

## Features

- Full coverage of the Polymarket Data API, Gamma API, and CLOB API
- L1 (EIP-712 wallet signing) and L2 (HMAC-SHA256) authentication for CLOB API
- Type-safe interface with validated primitive types and OCaml variant types
- Built on [Eio](https://github.com/ocaml-multicore/eio) for efficient concurrent I/O
- TLS support for secure API connections
- Built-in rate limiting with official Polymarket API limits (GCRA algorithm)
- Comprehensive error handling with result types
- JSON serialization via ppx_yojson_conv
- Pretty printing and equality functions for all types

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
 (polymarket (>= 0.1.0)))
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

  (* Create a shared rate limiter with Polymarket presets *)
  let rate_limiter = Rate_limiter.create_polymarket ~clock () in

  (* Create a client *)
  let client = Gamma.create ~sw ~net ~rate_limiter () in

  (* Get active markets *)
  match Gamma.get_markets client ~active:true ~limit:(Nonneg_int.of_int_exn 10) () with
  | Ok markets ->
    List.iter (fun (m : Gamma.market) ->
      print_endline (Option.value ~default:"(no question)" m.question)
    ) markets
  | Error err ->
    print_endline ("Error: " ^ err.Http.error)
```

The library uses validated primitive types like `Address.t`, `Hash64.t`, `Limit.t`, and `Nonneg_int.t` for type safety. Create them with `*.of_int_exn`, `*.make_exn`, or handle errors with `*.of_int`, `*.make`.

## Data API Examples

### Get User Positions

```ocaml
open Polymarket

let user_address = Address.make_exn "0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d59" in
match Data.get_positions client
  ~user:user_address
  ~limit:(Limit.of_int_exn 10)
  ~sort_by:Data.CASHPNL
  ~sort_direction:Data.DESC
  ()
with
| Ok positions ->
  List.iter (fun pos ->
    Printf.printf "Position: %s, PnL: %s\n"
      (Option.value ~default:"(unknown)" pos.title)
      (Option.map string_of_float pos.cash_pnl
       |> Option.value ~default:"N/A")
  ) positions
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

### Get Recent Trades

```ocaml
match Data.get_trades client
  ~user:user_address
  ~side:Data.BUY
  ~limit:(Nonneg_int.of_int_exn 20)
  ()
with
| Ok trades ->
  List.iter (fun trade ->
    Printf.printf "Trade: %s @ %f\n"
      (Option.value ~default:"(unknown)" trade.title)
      (Option.value ~default:0.0 trade.price)
  ) trades
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

### Get Trader Leaderboard

```ocaml
match Data.get_trader_leaderboard client
  ~category:Data.POLITICS
  ~time_period:Data.WEEK
  ~order_by:Data.PNL
  ~limit:(Leaderboard_limit.of_int_exn 10)
  ()
with
| Ok leaders ->
  List.iter (fun entry ->
    Printf.printf "#%s: %s - PnL: %f\n"
      (Option.value ~default:"?" entry.rank)
      (Option.value ~default:"(anonymous)" entry.user_name)
      (Option.value ~default:0.0 entry.pnl)
  ) leaders
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

## Gamma API Examples

The Gamma API provides access to markets, events, series, and search functionality.

### Get Active Markets

```ocaml
let rate_limiter = Rate_limiter.create_polymarket ~clock () in
let client = Gamma.create ~sw ~net ~rate_limiter () in
match Gamma.get_markets client ~active:true ~limit:(Nonneg_int.of_int_exn 10) () with
| Ok markets ->
  List.iter (fun (m : Gamma.market) ->
    Printf.printf "Market: %s\n"
      (Option.value ~default:"(no question)" m.question)
  ) markets
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

### Get Events by Tag

```ocaml
match Gamma.get_events client ~tag_slug:"politics" ~limit:(Nonneg_int.of_int_exn 10) () with
| Ok events ->
  List.iter (fun (e : Gamma.event) ->
    Printf.printf "Event: %s\n"
      (Option.value ~default:"(no title)" e.title)
  ) events
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

### Search

```ocaml
match Gamma.public_search client ~q:"election" ~limit_per_type:5 () with
| Ok search ->
  let event_count = match search.events with Some e -> List.length e | None -> 0 in
  Printf.printf "Found %d events\n" event_count
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

## CLOB API Examples

The CLOB (Central Limit Order Book) API provides access to order books, pricing, and authenticated trading endpoints.

### Typestate Authentication (Recommended)

The CLOB client uses a **typestate pattern** to enforce authentication requirements at compile time. Three client types exist:

- `Clob.Unauthed.t`: Public endpoints only (order book, pricing, timeseries)
- `Clob.L1.t`: L1 wallet authentication (create/derive API keys) + public
- `Clob.L2.t`: L2 API key authentication (orders, trades) + L1 + public

```ocaml
open Polymarket

(* Start with an unauthenticated client for public data *)
let client = Clob.Unauthed.create ~sw ~net ~rate_limiter () in

(* Get order book - works on Unauthed client *)
match Clob.Unauthed.get_order_book client ~token_id () with
| Ok book -> Printf.printf "Bids: %d, Asks: %d\n"
    (List.length book.bids) (List.length book.asks)
| Error err -> Printf.printf "Error: %s\n" err.Http.error

(* Upgrade to L1 with private key *)
let l1_client = Clob.upgrade_to_l1 client ~private_key in
Printf.printf "Address: %s\n" (Clob.L1.address l1_client);

(* Derive API credentials and auto-upgrade to L2 *)
match Clob.L1.derive_api_key l1_client ~nonce:0 with
| Ok (l2_client, _resp) ->
    (* L2 client can access authenticated endpoints *)
    let _ = Clob.L2.get_orders l2_client () in
    let _ = Clob.L2.get_trades l2_client () in
    (* L2 can also call public endpoints *)
    let _ = Clob.L2.get_midpoint l2_client ~token_id () in
    ()
| Error err -> Printf.printf "Error: %s\n" err.Http.error
```

### State Transitions

```ocaml
(* Upgrade functions *)
val Clob.upgrade_to_l1 : unauthed -> private_key:string -> l1
val Clob.upgrade_to_l2 : l1 -> credentials:Auth_types.credentials -> l2
val Clob.L1.derive_api_key : l1 -> nonce:int -> (l2 * response, error) result

(* Downgrade functions *)
val Clob.l2_to_l1 : l2 -> l1
val Clob.l2_to_unauthed : l2 -> unauthed
val Clob.l1_to_unauthed : l1 -> unauthed
```

### Get Order Book

```ocaml
let rate_limiter = Rate_limiter.create_polymarket ~clock () in
let client = Clob.Unauthed.create ~sw ~net ~rate_limiter () in
let token_id = "12345..." in (* Token ID from Gamma API *)
match Clob.Unauthed.get_order_book client ~token_id () with
| Ok book ->
  Printf.printf "Bids: %d, Asks: %d\n"
    (List.length book.bids) (List.length book.asks)
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

### Get Price and Midpoint

```ocaml
(* Get price for a specific side *)
match Clob.Unauthed.get_price client ~token_id ~side:Clob.BUY () with
| Ok price -> Printf.printf "Price: %s\n" (Option.value ~default:"N/A" price.price)
| Error err -> Printf.printf "Error: %s\n" err.Http.error

(* Get midpoint price *)
match Clob.Unauthed.get_midpoint client ~token_id () with
| Ok mid -> Printf.printf "Midpoint: %s\n" (Option.value ~default:"N/A" mid.mid)
| Error err -> Printf.printf "Error: %s\n" err.Http.error
```

### L2 Authenticated Endpoints

Once you have an L2 client, you can access trading endpoints:

```ocaml
(* Get your open orders *)
match Clob.L2.get_orders l2_client () with
| Ok orders ->
  List.iter (fun order ->
    Printf.printf "Order: %s @ %s\n"
      (Option.value ~default:"" order.id)
      (Option.value ~default:"" order.price)
  ) orders
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error

(* Cancel all orders *)
match Clob.L2.cancel_all l2_client () with
| Ok resp -> Printf.printf "Cancelled: %d orders\n" (List.length resp.canceled)
| Error err -> Printf.printf "Error: %s\n" err.Http.error
```

### Legacy Client

The original client with optional credentials is still available:

```ocaml
let client = Clob.create ~sw ~net ~rate_limiter () in
(* Public endpoints work without credentials *)
let _ = Clob.get_order_book client ~token_id () in
(* Authenticated endpoints require with_credentials *)
let auth_client = Clob.with_credentials client ~credentials ~address in
let _ = Clob.get_orders auth_client () in
```

## Rate Limiting

The library includes built-in rate limiting that matches the official [Polymarket API rate limits](https://docs.polymarket.com/#/api-rate-limits). A shared rate limiter enforces limits across all API clients.

### Creating a Shared Rate Limiter

Create a single rate limiter and share it across all clients to properly enforce global rate limits:

```ocaml
open Polymarket

Eio_main.run @@ fun env ->
Eio.Switch.run @@ fun sw ->
let net = Eio.Stdenv.net env in
let clock = Eio.Stdenv.clock env in

(* Create a shared rate limiter with Polymarket presets *)
let rate_limiter = Rate_limiter.create_polymarket ~clock () in

(* Share the same rate limiter across all clients *)
let gamma_client = Gamma.create ~sw ~net ~rate_limiter () in
let data_client = Data.create ~sw ~net ~rate_limiter () in
let clob_client = Clob.create ~sw ~net ~rate_limiter () in
(* All clients now share rate limit state *)
```

### Rate Limit Behavior

When a rate limit is exceeded, the client can either delay (sleep) until the request can proceed, or return an error immediately. The default behavior is `Delay`, which is recommended for Cloudflare-protected APIs.

```ocaml
open Polymarket

(* Default: Delay behavior (sleeps until request can proceed) *)
let rate_limiter = Rate_limiter.create_polymarket ~clock () in

(* Or explicitly specify Error behavior *)
let rate_limiter = Rate_limiter.create_polymarket ~clock ~behavior:Rate_limiter.Error () in
```

### Configured Limits

The library includes pre-configured limits for all Polymarket APIs:

| API | General Limit | Notable Endpoint Limits |
|-----|---------------|------------------------|
| Data API | 1000/10s | `/trades`: 200/10s, `/positions`: 150/10s |
| Gamma API | 4000/10s | `/events`: 300/10s, `/markets`: 300/10s |
| CLOB API | 9000/10s | Trading endpoints with burst + sustained limits |
| Global | 15000/10s | Applies across all APIs |

## API Reference

### Module Structure

The library provides a flattened API through three main modules:

```
Polymarket
├── Gamma         (* Markets, events, series, search *)
├── Data          (* Positions, trades, activity, leaderboards *)
├── Clob          (* Order books, pricing, trading *)
│   ├── Typestate (* Typestate client: Unauthed, L1, L2 *)
│   ├── Auth      (* L1/L2 authentication *)
│   ├── Auth_types(* Credential types *)
│   └── Crypto    (* Signing and hashing *)
├── Http          (* HTTP client utilities *)
├── Rate_limiter  (* Rate limiting with GCRA algorithm *)
└── Primitives    (* Validated types: Address, Hash64, Limit, etc. *)
```

### Data API Endpoints

| Endpoint | Function | Description |
|----------|----------|-------------|
| `GET /health` | `health_check` | Check API health status |
| `GET /positions` | `get_positions` | Get current positions for a user |
| `GET /positions/closed` | `get_closed_positions` | Get closed positions for a user |
| `GET /trades` | `get_trades` | Get trades for a user or markets |
| `GET /activity` | `get_activity` | Get on-chain activity for a user |
| `GET /holders` | `get_holders` | Get top holders for markets |
| `GET /traded` | `get_traded` | Get total markets a user has traded |
| `GET /value` | `get_value` | Get total value of user positions |
| `GET /open-interest` | `get_open_interest` | Get open interest for markets |
| `GET /live-volume` | `get_live_volume` | Get live volume for an event |
| `GET /leaderboard/builder` | `get_builder_leaderboard` | Get builder leaderboard |
| `GET /leaderboard/builder/volume` | `get_builder_volume` | Get builder volume time-series |
| `GET /leaderboard/trader` | `get_trader_leaderboard` | Get trader leaderboard |

### Gamma API Endpoints

| Endpoint | Function | Description |
|----------|----------|-------------|
| `GET /status` | `status` | Check API health status |
| `GET /teams` | `get_teams` | Get list of sports teams |
| `GET /teams/{id}` | `get_team` | Get a team by ID |
| `GET /tags` | `get_tags` | Get list of tags |
| `GET /tags/{id}` | `get_tag` | Get a tag by ID |
| `GET /tags/slug/{slug}` | `get_tag_by_slug` | Get a tag by slug |
| `GET /tags/{id}/related` | `get_related_tags` | Get related tags |
| `GET /events` | `get_events` | Get list of events |
| `GET /events/{id}` | `get_event` | Get an event by ID |
| `GET /events/slug/{slug}` | `get_event_by_slug` | Get an event by slug |
| `GET /events/{id}/tags` | `get_event_tags` | Get tags for an event |
| `GET /markets` | `get_markets` | Get list of markets |
| `GET /markets/{id}` | `get_market` | Get a market by ID |
| `GET /markets/slug/{slug}` | `get_market_by_slug` | Get a market by slug |
| `GET /markets/{id}/tags` | `get_market_tags` | Get tags for a market |
| `GET /markets/{id}/description` | `get_market_description` | Get market description |
| `GET /series` | `get_series_list` | Get list of series |
| `GET /series/{id}` | `get_series` | Get a series by ID |
| `GET /series/{id}/summary` | `get_series_summary` | Get series summary |
| `GET /comments` | `get_comments` | Get list of comments |
| `GET /comments/{id}` | `get_comment` | Get a comment by ID |
| `GET /comments/user/{address}` | `get_user_comments` | Get comments by user |
| `GET /profiles/public/{address}` | `get_public_profile` | Get public profile |
| `GET /profiles/{address}` | `get_profile` | Get profile by address |
| `GET /sports` | `get_sports` | Get list of sports |
| `GET /sports/market-types` | `get_sports_market_types` | Get sports market types |
| `GET /search` | `public_search` | Search events, tags, profiles |

### CLOB API Endpoints

#### Public Endpoints

| Endpoint | Function | Description |
|----------|----------|-------------|
| `GET /book` | `get_order_book` | Get order book for a token |
| `POST /books` | `get_order_books` | Get order books for multiple tokens |
| `GET /price` | `get_price` | Get price for a token and side |
| `GET /midpoint` | `get_midpoint` | Get midpoint price for a token |
| `POST /prices` | `get_prices` | Get prices for multiple tokens |
| `POST /spreads` | `get_spreads` | Get spreads for multiple tokens |
| `GET /prices-history` | `get_price_history` | Get price history for a market |

#### Authenticated Endpoints (L1 - Wallet)

| Endpoint | Function | Description |
|----------|----------|-------------|
| `POST /auth/api-key` | `create_api_key` | Create new API credentials |
| `GET /auth/derive-api-key` | `derive_api_key` | Derive API credentials from wallet |

#### Authenticated Endpoints (L2 - API Key)

| Endpoint | Function | Description |
|----------|----------|-------------|
| `POST /order` | `create_order` | Submit a new order |
| `POST /orders` | `create_orders` | Submit multiple orders |
| `GET /data/order/{id}` | `get_order` | Get order by ID |
| `GET /data/orders` | `get_orders` | Get open orders |
| `DELETE /order` | `cancel_order` | Cancel an order |
| `DELETE /orders` | `cancel_orders` | Cancel multiple orders |
| `DELETE /cancel-all` | `cancel_all` | Cancel all orders |
| `DELETE /cancel-market-orders` | `cancel_market_orders` | Cancel orders for a market |
| `GET /data/trades` | `get_trades` | Get trade history |

### Type Reference

#### Validated Primitive Types

| Type | Description | Creation |
|------|-------------|----------|
| `Address.t` | Ethereum address (0x + 40 hex chars) | `Address.make_exn "0x..."` |
| `Hash64.t` | 64-character hex hash | `Hash64.make_exn "0x..."` |
| `Hash.t` | Variable-length hex string | `Hash.make_exn "0x..."` |
| `Nonneg_int.t` | Non-negative integer | `Nonneg_int.of_int_exn 5` |
| `Pos_int.t` | Positive integer | `Pos_int.of_int_exn 1` |
| `Limit.t` | Pagination limit (1-1000) | `Limit.of_int_exn 100` |
| `Offset.t` | Pagination offset (0-10000) | `Offset.of_int_exn 0` |
| `Timestamp.t` | Unix timestamp | `Timestamp.of_float_exn 1234567890.0` |

#### Data API Enums

| Type | Values |
|------|--------|
| `side` | `BUY`, `SELL` |
| `activity_type` | `TRADE`, `SPLIT`, `MERGE`, `REDEEM`, `REWARD`, `CONVERSION` |
| `sort_direction` | `ASC`, `DESC` |
| `time_period` | `DAY`, `WEEK`, `MONTH`, `ALL` |
| `leaderboard_category` | `OVERALL`, `POLITICS`, `SPORTS`, `CRYPTO`, `CULTURE`, `MENTIONS`, `WEATHER`, `ECONOMICS`, `TECH`, `FINANCE` |
| `position_sort_by` | `CURRENT`, `INITIAL`, `TOKENS`, `CASHPNL`, `PERCENTPNL`, `TITLE`, `RESOLVING`, `PRICE`, `AVGPRICE` |

#### Gamma API Enums

| Type | Values |
|------|--------|
| `status` | `Active`, `Closed`, `All` |
| `slug_size` | `Full`, `Slim` |
| `parent_entity_type` | `Event`, `Series`, `Market` |

#### CLOB API Enums

| Type | Values |
|------|--------|
| `order_side` | `BUY`, `SELL` |
| `order_type` | `GTC`, `GTD`, `FOK` |
| `time_interval` | `MAX`, `ONE_WEEK`, `ONE_DAY`, `SIX_HOURS`, `ONE_HOUR` |

## Sub-Libraries

For finer-grained control, you can depend on individual sub-libraries:

| Library | Description |
|---------|-------------|
| `polymarket` | Main library with flattened API (recommended) |
| `polymarket.common` | Shared primitives (`Address`, `Hash64`, etc.) and utilities |
| `polymarket.http` | HTTP client with TLS support and rate limiting |
| `polymarket.rate_limiter` | GCRA-based rate limiter (used internally by http) |
| `polymarket.gamma` | Gamma API client only |
| `polymarket.data` | Data API client only |
| `polymarket.clob` | CLOB API client only |

To use a sub-library, add it to your dune file:

```lisp
(executable
 (name my_app)
 (libraries polymarket.gamma polymarket.common))
```

## Development

### Building

```bash
# Install dependencies
opam install . --deps-only --with-test

# Build the project
dune build

# Build documentation
dune build @doc
```

### Testing

```bash
# Run all tests
dune runtest

# Run tests with verbose output
dune runtest --force --verbose
```

### Running the Demos

```bash
# Data API demo
dune exec examples/data_api_demo.exe

# Gamma API demo
dune exec examples/gamma_api_demo.exe

# CLOB API demo
dune exec examples/clob_api_demo.exe

# CLOB API demo with private key for authentication
POLY_PRIVATE_KEY=your_private_key_hex dune exec examples/clob_api_demo.exe
```

### Code Formatting

```bash
dune fmt
```

## Project Structure

```
polymarket/
├── lib/
│   ├── common/           # Shared utilities
│   │   ├── logger.ml     # Structured logging
│   │   └── primitives.ml # Validated types (Address, Hash64, Limit, etc.)
│   ├── http_client/      # HTTP client
│   │   └── client.ml     # TLS-enabled HTTP requests with rate limiting
│   ├── rate_limiter/     # GCRA-based rate limiter
│   │   ├── rate_limiter.ml  # Main rate limiter module
│   │   ├── presets.ml    # Polymarket API rate limit configs
│   │   ├── gcra.ml       # Generic Cell Rate Algorithm
│   │   ├── state.ml      # Thread-safe state management
│   │   ├── matcher.ml    # Route matching logic
│   │   └── builder.ml    # Route configuration builder
│   ├── data_api/         # Data API implementation
│   │   ├── client.ml     # API client
│   │   └── types.ml      # Response types and enums
│   ├── gamma_api/        # Gamma API implementation
│   │   ├── client.ml     # API client
│   │   ├── query.ml      # Query parameter types
│   │   └── responses.ml  # Response types
│   ├── clob_api/         # CLOB API implementation
│   │   ├── client.ml     # API client (optional credentials)
│   │   ├── client_typestate.ml  # Typestate client (compile-time auth)
│   │   ├── types.ml      # Response types
│   │   ├── auth.ml       # L1/L2 authentication
│   │   ├── auth_types.ml # Credential types
│   │   └── crypto.ml     # Signing and hashing
│   ├── polymarket.ml     # Main module (flattened API)
│   └── polymarket.mli    # Public interface
├── examples/
│   ├── data_api_demo.ml  # Data API live demo
│   ├── gamma_api_demo.ml # Gamma API live demo
│   ├── clob_api_demo.ml  # CLOB API live demo
│   └── logger.ml         # Demo logging utilities
├── test/                 # Test suite
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
└── SECURITY.md
```

## Documentation

- [API Reference](https://haut.github.io/polymarket) - Generated OCaml documentation
- [Polymarket API Docs](https://docs.polymarket.com/) - Official Polymarket documentation
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [SECURITY.md](SECURITY.md) - Security policy

## License

MIT - see [LICENSE](LICENSE) for details.
