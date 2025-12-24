# Polymarket OCaml Client

OCaml client library for the [Polymarket](https://polymarket.com) prediction market API.

## Features

- Full coverage of the Polymarket Data API and Gamma API
- Type-safe interface with OCaml variant types for enums
- Built on [Eio](https://github.com/ocaml-multicore/eio) for efficient concurrent I/O
- TLS support for secure API connections
- Comprehensive error handling with result types
- Structured logging with configurable log levels
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

  (* Optional: Enable logging (levels: debug, info, off) *)
  (* Common.Logger.setup () reads POLYMARKET_LOG_LEVEL env var *)
  Common.Logger.setup ();

  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->

  (* Create a client *)
  let client = Data_api.Client.create
    ~sw
    ~net:(Eio.Stdenv.net env)
    ()
  in

  (* Check API health *)
  match Data_api.Client.health_check client with
  | Ok response ->
    print_endline (Option.value ~default:"OK" response.data)
  | Error err ->
    print_endline ("Error: " ^ err.error)
```

## Data API Examples

### Get User Positions

```ocaml
let user_address = "0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d59" in
match Data_api.Client.get_positions client
  ~user:user_address
  ~limit:10
  ~sort_by:Data_api.Params.CASHPNL
  ~sort_direction:Data_api.Params.DESC
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
  Printf.printf "Error: %s\n" err.error
```

### Get Recent Trades

```ocaml
match Data_api.Client.get_trades client
  ~user:user_address
  ~side:Data_api.Types.BUY
  ~limit:20
  ()
with
| Ok trades ->
  List.iter (fun trade ->
    Printf.printf "Trade: %s @ %f\n"
      (Option.value ~default:"(unknown)" trade.title)
      (Option.value ~default:0.0 trade.price)
  ) trades
| Error err ->
  Printf.printf "Error: %s\n" err.error
```

### Get Trader Leaderboard

```ocaml
match Data_api.Client.get_trader_leaderboard client
  ~category:Data_api.Params.POLITICS
  ~time_period:Data_api.Params.WEEK
  ~order_by:Data_api.Params.PNL
  ~limit:10
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
  Printf.printf "Error: %s\n" err.error
```

## Gamma API Examples

The Gamma API provides access to markets, events, series, and search functionality.

### Get Active Markets

```ocaml
let client = Gamma_api.Client.create ~sw ~net:(Eio.Stdenv.net env) () in
match Gamma_api.Client.get_markets client ~active:true ~limit:10 () with
| Ok markets ->
  List.iter (fun (m : Gamma_api.Types.market) ->
    Printf.printf "Market: %s\n"
      (Option.value ~default:"(no question)" m.question)
  ) markets
| Error err ->
  Printf.printf "Error: %s\n" err.error
```

### Get Events by Tag

```ocaml
match Gamma_api.Client.get_events client ~tag_slug:"politics" ~limit:10 () with
| Ok events ->
  List.iter (fun (e : Gamma_api.Types.event) ->
    Printf.printf "Event: %s\n"
      (Option.value ~default:"(no title)" e.title)
  ) events
| Error err ->
  Printf.printf "Error: %s\n" err.error
```

### Search

```ocaml
match Gamma_api.Client.public_search client ~q:"election" ~limit_per_type:5 () with
| Ok search ->
  let event_count = match search.events with Some e -> List.length e | None -> 0 in
  Printf.printf "Found %d events\n" event_count
| Error err ->
  Printf.printf "Error: %s\n" err.error
```

## Logging

The library includes structured logging via `Common.Logger`. Enable it by setting the `POLYMARKET_LOG_LEVEL` environment variable:

```bash
# Debug level - detailed logging including HTTP response bodies
POLYMARKET_LOG_LEVEL=debug dune exec examples/data_api_demo.exe

# Info level - request URLs and response status codes
POLYMARKET_LOG_LEVEL=info dune exec examples/data_api_demo.exe

# Off (default) - no logging
dune exec examples/data_api_demo.exe
```

Log messages follow a structured format:

```
[HTTP_CLIENT] [REQUEST] method="GET" url="https://..."
[HTTP_CLIENT] [RESPONSE] method="GET" url="..." status="200"
[DATA_API] [CALL] endpoint="/positions" user="0x..."
```

## API Reference

### Module Structure

```
Polymarket
├── Common          (* Shared utilities *)
│   └── Logger      (* Structured logging *)
├── Http_client     (* HTTP client with TLS support *)
│   └── Client      (* HTTP request functions *)
├── Data_api        (* Data API client *)
│   ├── Client      (* API client functions *)
│   ├── Types       (* Response types *)
│   └── Params      (* Query parameter types *)
└── Gamma_api       (* Gamma API client *)
    ├── Client      (* API client functions *)
    ├── Types       (* Response types *)
    └── Params      (* Query parameter types *)
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

### Type Reference

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

#### Primitive Types

| Type | Description | Pattern |
|------|-------------|---------|
| `address` | Ethereum address | `^0x[a-fA-F0-9]{40}$` |
| `hash64` | 64-character hex hash | `^0x[a-fA-F0-9]{64}$` |

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

# With debug logging enabled
POLYMARKET_LOG_LEVEL=debug dune exec examples/data_api_demo.exe
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
│   │   └── logger.ml     # Structured logging
│   ├── http_client/      # HTTP client
│   │   └── client.ml     # TLS-enabled HTTP requests
│   ├── data_api/         # Data API implementation
│   │   ├── client.ml     # API client
│   │   ├── params.ml     # Query parameters
│   │   └── types.ml      # Response types
│   ├── gamma_api/        # Gamma API implementation
│   │   ├── client.ml     # API client
│   │   ├── params.ml     # Query parameters
│   │   └── types.ml      # Response types
│   └── polymarket.ml     # Main module
├── examples/
│   ├── data_api_demo.ml  # Data API live demo
│   ├── gamma_api_demo.ml # Gamma API live demo
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
