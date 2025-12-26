# Polymarket OCaml Client

OCaml client library for the [Polymarket](https://polymarket.com) prediction market API.

## Features

- Full coverage of the Polymarket Data API, Gamma API, and CLOB API
- L1 (EIP-712 wallet signing) and L2 (HMAC-SHA256) authentication for CLOB API
- Type-safe interface with validated primitive types and OCaml variant types
- Built on [Eio](https://github.com/ocaml-multicore/eio) for efficient concurrent I/O
- TLS support for secure API connections
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

  (* Create a client *)
  let client = Gamma.create ~sw ~net:(Eio.Stdenv.net env) () in

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
let client = Gamma.create ~sw ~net:(Eio.Stdenv.net env) () in
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

### Get Order Book

```ocaml
let client = Clob.create ~sw ~net:(Eio.Stdenv.net env) () in
let token_id = "12345..." in (* Token ID from Gamma API *)
match Clob.get_order_book client ~token_id () with
| Ok book ->
  Printf.printf "Best bid: %s, Best ask: %s\n"
    (Option.value ~default:"N/A" book.best_bid)
    (Option.value ~default:"N/A" book.best_ask)
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

### Get Price and Midpoint

```ocaml
(* Get price for a specific side *)
match Clob.get_price client ~token_id ~side:Clob.BUY () with
| Ok price -> Printf.printf "Price: %s\n" price.price
| Error err -> Printf.printf "Error: %s\n" err.Http.error

(* Get midpoint price *)
match Clob.get_midpoint client ~token_id () with
| Ok mid -> Printf.printf "Midpoint: %s\n" mid.mid
| Error err -> Printf.printf "Error: %s\n" err.Http.error
```

### Authentication

The CLOB API supports two authentication levels:
- **L1 (Wallet)**: EIP-712 signing with your Ethereum private key for API key management
- **L2 (API Key)**: HMAC-SHA256 signing with API credentials for trading endpoints

```ocaml
(* Derive API credentials from wallet *)
let private_key = "your_private_key_hex_without_0x" in
let nonce = int_of_float (Unix.gettimeofday () *. 1000.0) mod 1000000 in
match Clob.derive_api_key client ~private_key ~nonce with
| Ok resp ->
  let creds = Clob.Auth_types.credentials_of_derive_response resp in
  let address = Clob.Crypto.private_key_to_address private_key in
  (* Create authenticated client *)
  let auth_client = Clob.with_credentials client ~credentials:creds ~address in
  (* Now use auth_client for authenticated endpoints *)
  ()
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error
```

### Authenticated Endpoints

Once you have an authenticated client, you can access trading endpoints:

```ocaml
(* Get your open orders *)
match Clob.get_orders auth_client () with
| Ok orders ->
  List.iter (fun order ->
    Printf.printf "Order: %s @ %s\n" order.id order.price
  ) orders
| Error err ->
  Printf.printf "Error: %s\n" err.Http.error

(* Cancel all orders *)
match Clob.cancel_all auth_client () with
| Ok resp -> Printf.printf "Cancelled: %b\n" resp.canceled
| Error err -> Printf.printf "Error: %s\n" err.Http.error
```

## API Reference

### Module Structure

The library provides a flattened API through three main modules:

```
Polymarket
├── Gamma         (* Markets, events, series, search *)
├── Data          (* Positions, trades, activity, leaderboards *)
├── Clob          (* Order books, pricing, trading *)
│   ├── Auth      (* L1/L2 authentication *)
│   ├── Auth_types(* Credential types *)
│   └── Crypto    (* Signing and hashing *)
├── Http          (* HTTP client utilities *)
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
| `polymarket.http` | HTTP client with TLS support |
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
│   │   └── client.ml     # TLS-enabled HTTP requests
│   ├── data_api/         # Data API implementation
│   │   ├── client.ml     # API client
│   │   └── types.ml      # Response types and enums
│   ├── gamma_api/        # Gamma API implementation
│   │   ├── client.ml     # API client
│   │   ├── query.ml      # Query parameter types
│   │   └── responses.ml  # Response types
│   ├── clob_api/         # CLOB API implementation
│   │   ├── client.ml     # API client
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
