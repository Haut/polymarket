# Polymarket OCaml Client

OCaml client library for the [Polymarket](https://polymarket.com) prediction market API.

## Features

- Full coverage of the Polymarket Data API, Gamma API, CLOB API, and RFQ API
- Real-time WebSocket streaming for market data and user events
- RTDS (Real-Time Data Socket) for crypto prices and comments
- L1 (EIP-712 wallet signing) and L2 (HMAC-SHA256) authentication for CLOB API
- Type-safe interface with validated primitive types and OCaml variant types
- Built on [Eio](https://github.com/ocaml-multicore/eio) for efficient concurrent I/O
- Pure-OCaml TLS for cross-platform compatibility (via tls-eio)
- Built-in rate limiting with official Polymarket API limits (GCRA algorithm)
- Type-safe HTTP request builder with phantom types
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
  let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in

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
  ~sort_by:Data.Position_sort_by.Cashpnl
  ~sort_direction:Data.Sort_direction.Desc
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
  ~side:Data.Side.Buy
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
  ~category:Data.Leaderboard_category.Politics
  ~time_period:Data.Time_period.Week
  ~order_by:Data.Leaderboard_order_by.Pnl
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
let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
let rate_limiter = Rate_limiter.create ~routes ~clock () in
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
val Clob.upgrade_to_l2 : l1 -> credentials:Auth.credentials -> l2
val Clob.L1.derive_api_key : l1 -> nonce:int -> (l2 * response, error) result

(* Downgrade functions *)
val Clob.l2_to_l1 : l2 -> l1
val Clob.l2_to_unauthed : l2 -> unauthed
val Clob.l1_to_unauthed : l1 -> unauthed
```

### Get Order Book

```ocaml
let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
let rate_limiter = Rate_limiter.create ~routes ~clock () in
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
match Clob.Unauthed.get_price client ~token_id ~side:Clob.Types.Side.Buy () with
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

## RFQ API Examples

The RFQ (Request for Quote) API enables large block trades by allowing traders to request quotes and execute trades off the order book.

### Creating an RFQ Client

All RFQ endpoints require L2 authentication:

```ocaml
open Polymarket

let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
let rate_limiter = Rate_limiter.create ~routes ~clock () in
let private_key = Crypto.private_key_of_string "your_private_key_hex" in
let credentials = Auth.{ api_key = "..."; secret = "..."; passphrase = "..." } in
let client = Rfq.create ~sw ~net ~rate_limiter ~private_key ~credentials () in
```

### Get Active Requests

```ocaml
match Rfq.get_requests client ~state:Rfq.Types.State_filter.Active () with
| Ok resp ->
  List.iter (fun req ->
    Printf.printf "Request %s: %s %s @ %s\n"
      req.id req.side req.asset_id req.price
  ) resp.requests
| Error err ->
  Printf.printf "Error: %s\n" (Rfq.Types.error_to_string err)
```

### Get Quotes

```ocaml
match Rfq.get_quotes client ~state:Rfq.Types.State_filter.Active () with
| Ok resp ->
  List.iter (fun quote ->
    Printf.printf "Quote %s: %s\n" quote.id quote.price
  ) resp.quotes
| Error err ->
  Printf.printf "Error: %s\n" (Rfq.Types.error_to_string err)
```

### RFQ API Endpoints

| Endpoint | Function | Description |
|----------|----------|-------------|
| `POST /rfq/request` | `create_request` | Create a new RFQ request |
| `DELETE /rfq/request` | `cancel_request` | Cancel an RFQ request |
| `GET /rfq/request` | `get_requests` | Get RFQ requests |
| `POST /rfq/quote` | `create_quote` | Create a quote for an RFQ |
| `DELETE /rfq/quote` | `cancel_quote` | Cancel a quote |
| `GET /rfq/quote` | `get_quotes` | Get quotes |
| `POST /rfq/accept` | `accept_quote` | Accept a quote |

## WebSocket Streaming

The library provides real-time WebSocket streaming for market data and user events using pure-OCaml TLS (tls-eio) for cross-platform compatibility.

### Market Channel (Public)

Subscribe to orderbook updates for specific asset IDs:

```ocaml
open Polymarket

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  (* Get token IDs from Gamma API *)
  let asset_ids = ["token_id_1"; "token_id_2"] in

  (* Connect to market channel *)
  let client = Wss.Market.connect ~sw ~net ~clock ~asset_ids () in
  let stream = Wss.Market.stream client in

  (* Process messages *)
  let rec loop () =
    match Eio.Stream.take stream with
    | Wss.Types.Market (Book book) ->
        Printf.printf "Book: %s - %d bids, %d asks\n"
          book.asset_id (List.length book.bids) (List.length book.asks);
        loop ()
    | Wss.Types.Market (Price_change change) ->
        Printf.printf "Price change: %d updates\n"
          (List.length change.price_changes);
        loop ()
    | Wss.Types.Market (Last_trade_price trade) ->
        Printf.printf "Trade: %s @ %s\n" trade.asset_id trade.price;
        loop ()
    | _ -> loop ()
  in
  loop ()
```

### User Channel (Authenticated)

Subscribe to your trades and orders with API credentials:

```ocaml
let credentials = Clob.Auth.{
  api_key = "...";
  secret = "...";
  passphrase = "...";
} in
let markets = ["condition_id_1"; "condition_id_2"] in

let client = Wss.User.connect ~sw ~net ~clock ~credentials ~markets () in
let stream = Wss.User.stream client in

match Eio.Stream.take stream with
| Wss.Types.User (Trade trade) ->
    Printf.printf "Trade: %s @ %s\n" trade.id trade.price
| Wss.Types.User (Order order) ->
    Printf.printf "Order: %s %s @ %s\n" order.id order.side order.price
| _ -> ()
```

### Dynamic Subscriptions

Add or remove asset subscriptions on the fly:

```ocaml
(* Subscribe to additional assets *)
Wss.Market.subscribe client ~asset_ids:["new_token_id"];

(* Unsubscribe from assets *)
Wss.Market.unsubscribe client ~asset_ids:["old_token_id"];

(* Close connection *)
Wss.Market.close client
```

### Message Types

| Channel | Message Type | Description |
|---------|--------------|-------------|
| Market | `Book` | Full orderbook snapshot |
| Market | `Price_change` | Incremental orderbook update |
| Market | `Last_trade_price` | Last trade price update |
| Market | `Best_bid_ask` | Best bid/ask update |
| Market | `Tick_size_change` | Tick size change notification |
| User | `Trade` | Trade execution notification |
| User | `Order` | Order status update |

## RTDS (Real-Time Data Socket)

The RTDS client provides streaming access to crypto prices and comments via the `ws-live-data.polymarket.com` WebSocket.

### Crypto Prices (Binance)

Stream real-time crypto prices from Binance:

```ocaml
open Polymarket

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  (* Connect to Binance crypto prices *)
  let client =
    Rtds.Crypto_prices.connect_binance ~sw ~net ~clock
      ~symbols:[ "btcusdt"; "ethusdt"; "solusdt" ]
      ()
  in
  let stream = Rtds.Crypto_prices.stream client in

  (* Process price updates *)
  let rec loop () =
    match Eio.Stream.take stream with
    | `Binance msg ->
        Printf.printf "%s: %.2f\n" msg.payload.symbol msg.payload.value;
        loop ()
    | _ -> loop ()
  in
  loop ()
```

### Crypto Prices (Chainlink)

Stream oracle prices from Chainlink:

```ocaml
let client =
  Rtds.Crypto_prices.connect_chainlink ~sw ~net ~clock ~symbol:"eth/usd" ()
in
let stream = Rtds.Crypto_prices.stream client in

match Eio.Stream.take stream with
| `Chainlink msg -> Printf.printf "ETH: %.2f\n" msg.payload.value
| _ -> ()
```

### Comments Stream

Subscribe to real-time comment and reaction updates:

```ocaml
let client = Rtds.Comments.connect ~sw ~net ~clock () in
let stream = Rtds.Comments.stream client in

match Eio.Stream.take stream with
| `Comment_created msg ->
    Printf.printf "New comment by %s: %s\n"
      msg.payload.profile.name msg.payload.body
| `Comment_removed msg ->
    Printf.printf "Comment removed: %s\n" msg.payload.id
| `Reaction_created msg ->
    Printf.printf "Reaction added to: %s\n" msg.payload.id
| `Reaction_removed msg ->
    Printf.printf "Reaction removed from: %s\n" msg.payload.id
```

### Unified RTDS Client

Subscribe to multiple topics with a single connection:

```ocaml
let client = Rtds.connect ~sw ~net ~clock () in

(* Subscribe to crypto prices and comments *)
let subscriptions =
  [
    Rtds.Types.crypto_prices_subscription
      ~filters:(Rtds.Types.binance_symbol_filter [ "btcusdt" ])
      ();
    Rtds.Types.comments_subscription ();
  ]
in
Rtds.subscribe client ~subscriptions;

let stream = Rtds.stream client in

(* Handle all message types *)
match Eio.Stream.take stream with
| `Crypto (`Binance msg) ->
    Printf.printf "BTC: %.2f\n" msg.payload.value
| `Crypto (`Chainlink msg) ->
    Printf.printf "Chainlink: %.2f\n" msg.payload.value
| `Comment (`Comment_created msg) ->
    Printf.printf "Comment: %s\n" msg.payload.body
| _ -> ()
```

### RTDS Message Types

| Topic | Message Type | Description |
|-------|--------------|-------------|
| `crypto_prices` | `Binance` | Real-time Binance price updates |
| `crypto_prices_chainlink` | `Chainlink` | Chainlink oracle price updates |
| `comments` | `Comment_created` | New comment posted |
| `comments` | `Comment_removed` | Comment deleted |
| `comments` | `Reaction_created` | Reaction added to comment |
| `comments` | `Reaction_removed` | Reaction removed from comment |

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
let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
let rate_limiter = Rate_limiter.create ~routes ~clock () in

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
let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
let rate_limiter = Rate_limiter.create ~routes ~clock () in

(* Or explicitly specify Error behavior *)
let routes = Polymarket_common.Rate_limit_presets.all ~behavior:Rate_limiter.Error in
let rate_limiter = Rate_limiter.create ~routes ~clock () in
```

### Configured Limits

The library includes pre-configured limits for all Polymarket APIs:

| API | General Limit | Notable Endpoint Limits |
|-----|---------------|------------------------|
| Data API | 1000/10s | `/trades`: 200/10s, `/positions`: 150/10s |
| Gamma API | 4000/10s | `/events`: 300/10s, `/markets`: 300/10s |
| CLOB API | 9000/10s | Trading endpoints with burst + sustained limits |
| Global | 15000/10s | Applies across all APIs |

## HTTP Request Builder

The library provides a type-safe request builder with **phantom types** that enforce correct usage at compile time. The builder is used internally by all API modules and is also available for direct use when building custom requests.

**Note:** The builder is accessed via `Polymarket_http.Builder`. The high-level API modules (`Polymarket.Gamma`, `Polymarket.Data`, etc.) use the builder internally, so most users won't need to use it directly.

- `GET` and `DELETE` requests are ready to execute immediately
- `POST` requests require a body via `with_body` before execution
- Authentication can be added via `with_l1_auth` or `with_l2_auth`

### Basic Usage

```ocaml
open Polymarket_http.Builder

(* GET request with query parameters *)
let positions =
  new_get client "/positions"
  |> query_param "user" address
  |> query_option "limit" string_of_int (Some 10)
  |> fetch_json_list position_of_yojson

(* POST request - requires body before execution *)
let order =
  new_post client "/order"
  |> with_body order_json        (* Changes not_ready -> ready *)
  |> fetch_json order_of_yojson

(* DELETE request *)
let result =
  new_delete client "/order"
  |> query_param "id" order_id
  |> fetch_unit
```

### Query Parameter Helpers

| Function | Description |
|----------|-------------|
| `query_param key value` | Add a required string parameter |
| `query_add key opt` | Add an optional string parameter |
| `query_option key to_string opt` | Add optional param with converter |
| `query_list key to_string opts` | Join list values with commas |
| `query_bool key opt` | Add boolean as "true"/"false" |
| `query_each key to_string opts` | Add each value as separate param |

### Authentication Helpers

```ocaml
(* L1 wallet authentication for API key creation *)
new_post client "/auth/api-key"
|> with_l1_auth ~private_key ~address ~nonce:0
|> with_body ""
|> fetch_json api_key_response_of_yojson

(* L2 API key authentication for trading - call after with_body for POST *)
new_post client "/order"
|> with_body order_json
|> with_l2_auth ~credentials ~address
|> fetch_json order_of_yojson

(* L2 auth for GET/DELETE *)
new_get client "/data/orders"
|> with_l2_auth ~credentials ~address
|> fetch_json_list order_of_yojson
```

### Response Parsers

| Function | Description |
|----------|-------------|
| `fetch` | Raw `(status, body)` for custom handling |
| `fetch_json parser` | Parse response as JSON object |
| `fetch_json_list parser` | Parse response as JSON array |
| `fetch_text` | Return body as string |
| `fetch_unit` | Discard body, succeed on 200/201/204 |

### Compile-Time Safety

The phantom types prevent common errors:

```ocaml
(* This won't compile - POST needs a body *)
let _ = new_post client "/order" |> fetch_json parser
(* Error: This expression has type not_ready t
          but was expected of type ready t *)

(* This compiles - body provided *)
let _ = new_post client "/order" |> with_body "{}" |> fetch_json parser
```

## API Reference

### Module Structure

The library provides a flattened API through these main modules:

```
Polymarket
├── Gamma         (* Markets, events, series, search *)
├── Data          (* Positions, trades, activity, leaderboards *)
├── Clob          (* Order books, pricing, trading *)
│   ├── Unauthed  (* Public endpoints client *)
│   ├── L1        (* Wallet auth client *)
│   ├── L2        (* API key auth client *)
│   ├── Types     (* order_side, order_type, time_interval, etc. *)
│   ├── Auth      (* L1/L2 authentication *)
│   └── Crypto    (* Signing and hashing *)
├── Rfq           (* Request for Quote API for block trades *)
│   └── Types     (* RFQ types and enums *)
├── Wss           (* Real-time WebSocket streaming *)
│   ├── Market    (* Public market data channel *)
│   ├── User      (* Authenticated user channel *)
│   └── Types     (* Message types *)
├── Rtds          (* Real-Time Data Socket streaming *)
│   ├── Crypto_prices  (* Binance/Chainlink price streams *)
│   ├── Comments  (* Comment and reaction streams *)
│   └── Types     (* RTDS message types *)
├── Http          (* HTTP client - alias for Polymarket_http.Client *)
├── Rate_limiter  (* Rate limiting with GCRA algorithm *)
├── Auth          (* Authentication types and header builders *)
├── Crypto        (* Cryptographic utilities *)
└── Primitives    (* Validated types: Address, Hash64, Limit, etc. *)

Polymarket_http   (* Direct access to HTTP client components *)
├── Client        (* HTTP client with TLS and rate limiting *)
├── Builder       (* Type-safe request builder with phantom types *)
└── Json          (* JSON parsing utilities *)
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

#### Data API Enums (Module-based)

| Module | Type | Values |
|--------|------|--------|
| `Data.Side` | `t` | `Buy`, `Sell` |
| `Data.Activity_type` | `t` | `Trade`, `Split`, `Merge`, `Redeem`, `Reward`, `Conversion` |
| `Data.Sort_direction` | `t` | `Asc`, `Desc` |
| `Data.Time_period` | `t` | `Day`, `Week`, `Month`, `All` |
| `Data.Leaderboard_category` | `t` | `Overall`, `Politics`, `Sports`, `Crypto`, `Culture`, `Mentions`, `Weather`, `Economics`, `Tech`, `Finance` |
| `Data.Position_sort_by` | `t` | `Current`, `Initial`, `Tokens`, `Cashpnl`, `Percentpnl`, `Title`, `Resolving`, `Price`, `Avgprice` |

#### Gamma API Enums (Module-based)

| Module | Type | Values |
|--------|------|--------|
| `Gamma.Status` | `t` | `Active`, `Closed`, `All` |
| `Gamma.Slug_size` | `t` | `Sm`, `Md`, `Lg` |
| `Gamma.Parent_entity_type` | `t` | `Event`, `Series`, `Market` |

#### CLOB API Enums (Module-based)

| Module | Type | Values |
|--------|------|--------|
| `Clob.Types.Side` | `t` | `Buy`, `Sell` |
| `Clob.Types.Order_type` | `t` | `Gtc`, `Gtd`, `Fok` |
| `Clob.Types.Time_interval` | `t` | `Max`, `One_week`, `One_day`, `Six_hours`, `One_hour` |

## Sub-Libraries

For finer-grained control, you can depend on individual sub-libraries:

| Library | Description |
|---------|-------------|
| `polymarket` | Main library with flattened API (recommended) |
| `polymarket.common` | Shared primitives (`Address`, `Hash64`, etc.) and utilities |
| `polymarket.http` | HTTP client with TLS support, type-safe request builder |
| `polymarket.rate_limiter` | GCRA-based rate limiter (used internally by http) |
| `polymarket.websocket` | Low-level WebSocket protocol implementation |
| `polymarket.gamma` | Gamma API client only |
| `polymarket.data` | Data API client only |
| `polymarket.clob` | CLOB API client only |
| `polymarket.rfq` | RFQ API client for block trades |
| `polymarket.wss` | WebSocket client for market/user streams |
| `polymarket.rtds` | RTDS client for crypto prices and comments |

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

# RFQ API demo (requires credentials)
POLY_PRIVATE_KEY=your_private_key_hex \
POLY_API_KEY=your_api_key \
POLY_API_SECRET=your_api_secret \
POLY_API_PASSPHRASE=your_passphrase \
dune exec examples/rfq_demo.exe

# WebSocket streaming demo
dune exec examples/wss_demo.exe

# RTDS streaming demo (crypto prices, comments)
dune exec examples/rtds_demo.exe
```

### Code Formatting

```bash
dune fmt
```

## Project Structure

```
polymarket/
├── lib/
│   ├── generic/              # Reusable infrastructure
│   │   ├── http_client/      # HTTP client
│   │   │   ├── client.ml     # TLS-enabled HTTP requests with rate limiting
│   │   │   ├── builder.ml    # Type-safe request builder with phantom types
│   │   │   └── json.ml       # JSON parsing utilities
│   │   ├── rate_limiter/     # GCRA-based rate limiter
│   │   │   ├── rate_limiter.ml  # Main rate limiter module
│   │   │   ├── gcra.ml       # Generic Cell Rate Algorithm
│   │   │   ├── state.ml      # Thread-safe state management
│   │   │   ├── matcher.ml    # Route matching logic
│   │   │   ├── builder.ml    # Route configuration builder
│   │   │   └── types.ml      # Rate limiter types
│   │   └── websocket/        # WebSocket protocol implementation
│   │       ├── connection.ml # Connection management with reconnect
│   │       ├── frame.ml      # WebSocket frame encoding/decoding
│   │       └── handshake.ml  # HTTP upgrade handshake
│   ├── polymarket/           # Polymarket-specific APIs
│   │   ├── common/           # Shared utilities
│   │   │   ├── primitives.ml # Validated types (Address, Hash64, Limit, etc.)
│   │   │   ├── auth.ml       # L1/L2 authentication header builders
│   │   │   ├── crypto.ml     # Signing and hashing utilities
│   │   │   ├── order_signing.ml # Order signing utilities
│   │   │   ├── constants.ml  # API constants
│   │   │   ├── error.ml      # Error types
│   │   │   └── rate_limit_presets.ml # Polymarket API rate limit configs
│   │   ├── data/             # Data API implementation
│   │   │   ├── client.ml     # API endpoint implementations
│   │   │   └── types.ml      # Response types and enums
│   │   ├── gamma/            # Gamma API implementation
│   │   │   ├── client.ml     # API endpoint implementations
│   │   │   └── types.ml      # Types and module-based enums
│   │   ├── clob/             # CLOB API implementation
│   │   │   ├── client.ml     # Typestate client (compile-time auth)
│   │   │   ├── order_builder.ml # Order construction utilities
│   │   │   └── types.ml      # Types and module-based enums
│   │   ├── rfq/              # RFQ API implementation
│   │   │   ├── client.ml     # Request for Quote client
│   │   │   ├── order_builder.ml # RFQ order utilities
│   │   │   └── types.ml      # RFQ types
│   │   ├── wss/              # WebSocket streaming client
│   │   │   ├── client.ml     # Market and User channel clients
│   │   │   └── types.ml      # Message types
│   │   └── rtds/             # Real-Time Data Socket client
│   │       ├── client.ml     # Crypto_prices and Comments clients
│   │       └── types.ml      # RTDS message types
│   ├── polymarket.ml         # Main module (flattened API)
│   └── polymarket.mli        # Public interface
├── examples/
│   ├── data_api_demo.ml      # Data API live demo
│   ├── gamma_api_demo.ml     # Gamma API live demo
│   ├── clob_api_demo.ml      # CLOB API live demo
│   ├── rfq_demo.ml           # RFQ API live demo
│   ├── wss_demo.ml           # WebSocket streaming demo
│   ├── rtds_demo.ml          # RTDS streaming demo
│   └── logger.ml             # Demo logging utilities
├── ppx/                      # Custom PPX preprocessors
├── scripts/                  # Build and utility scripts
├── test/                     # Test suite
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
