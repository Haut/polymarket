# Polymarket OCaml Client

OCaml client library for the [Polymarket](https://polymarket.com) prediction market API.

## Features

- Full coverage of the Polymarket Data API
- Type-safe interface with OCaml variant types for enums
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

## Usage Examples

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

## API Reference

### Module Structure

```
Polymarket
├── Common          (* Shared utilities *)
│   └── Http_client (* HTTP client with TLS support *)
└── Data_api        (* Data API client *)
    ├── Client      (* API client functions *)
    ├── Types       (* Response types *)
    └── Params      (* Query parameter types *)
```

### Supported Endpoints

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

### Type Reference

#### Enums

| Type | Values |
|------|--------|
| `side` | `BUY`, `SELL` |
| `activity_type` | `TRADE`, `SPLIT`, `MERGE`, `REDEEM`, `REWARD`, `CONVERSION` |
| `sort_direction` | `ASC`, `DESC` |
| `time_period` | `DAY`, `WEEK`, `MONTH`, `ALL` |
| `leaderboard_category` | `OVERALL`, `POLITICS`, `SPORTS`, `CRYPTO`, `CULTURE`, `MENTIONS`, `WEATHER`, `ECONOMICS`, `TECH`, `FINANCE` |
| `position_sort_by` | `CURRENT`, `INITIAL`, `TOKENS`, `CASHPNL`, `PERCENTPNL`, `TITLE`, `RESOLVING`, `PRICE`, `AVGPRICE` |

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

### Running the Demo

```bash
dune exec examples/data_api_demo.exe
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
│   │   └── http_client.ml
│   ├── data_api/         # Data API implementation
│   │   ├── client.ml     # API client
│   │   ├── params.ml     # Query parameters
│   │   └── types.ml      # Response types
│   └── polymarket.ml     # Main module
├── examples/
│   └── data_api_demo.ml  # Live demo
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
