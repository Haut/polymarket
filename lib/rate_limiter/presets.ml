(** Pre-configured rate limit presets for Polymarket APIs.

    Based on official documentation:
    https://docs.polymarket.com/#/api-rate-limits

    This module is internal and not exposed to library users. *)

module B = Builder

(* {1 General Rate Limits} *)

let general ~behavior =
  [ B.global ~requests:15000 ~window_seconds:10.0 ~behavior ]

(* {1 Data API Rate Limits} *)

let data_api_host = "data-api.polymarket.com"

let data_api ~behavior =
  [
    (* Specific endpoints first *)
    B.per_endpoint ~host:data_api_host ~method_:"GET" ~path:"/trades"
      ~requests:200 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:data_api_host ~method_:"GET" ~path:"/positions"
      ~requests:150 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:data_api_host ~method_:"GET" ~path:"/closed-positions"
      ~requests:150 ~window_seconds:10.0 ~behavior;
    (* General Data API limit *)
    B.per_host ~host:data_api_host ~requests:1000 ~window_seconds:10.0 ~behavior;
  ]

(* {1 Gamma API Rate Limits} *)

let gamma_api_host = "gamma-api.polymarket.com"

let gamma_api ~behavior =
  [
    (* Specific endpoints first *)
    B.per_endpoint ~host:gamma_api_host ~method_:"GET" ~path:"/comments"
      ~requests:200 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:gamma_api_host ~method_:"GET" ~path:"/events"
      ~requests:300 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:gamma_api_host ~method_:"GET" ~path:"/markets"
      ~requests:300 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:gamma_api_host ~method_:"GET" ~path:"/tags"
      ~requests:200 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:gamma_api_host ~method_:"GET" ~path:"/search"
      ~requests:300 ~window_seconds:10.0 ~behavior;
    (* General Gamma API limit *)
    B.per_host ~host:gamma_api_host ~requests:4000 ~window_seconds:10.0
      ~behavior;
  ]

(* {1 CLOB API Rate Limits} *)

let clob_api_host = "clob.polymarket.com"

(* CLOB Trading endpoints with burst + sustained limits *)
let clob_trading ~behavior =
  [
    (* POST /order: 3500/10s burst, 36000/10min sustained *)
    B.(
      route () |> host clob_api_host |> method_ "POST" |> path "/order"
      |> limit ~requests:3500 ~window_seconds:10.0
      |> limit ~requests:36000 ~window_seconds:600.0
      |> on_limit behavior |> build);
    (* DELETE /order: 3000/10s burst, 30000/10min sustained *)
    B.(
      route () |> host clob_api_host |> method_ "DELETE" |> path "/order"
      |> limit ~requests:3000 ~window_seconds:10.0
      |> limit ~requests:30000 ~window_seconds:600.0
      |> on_limit behavior |> build);
    (* POST /orders: 1000/10s burst, 15000/10min sustained *)
    B.(
      route () |> host clob_api_host |> method_ "POST" |> path "/orders"
      |> limit ~requests:1000 ~window_seconds:10.0
      |> limit ~requests:15000 ~window_seconds:600.0
      |> on_limit behavior |> build);
    (* DELETE /orders: 1000/10s burst, 15000/10min sustained *)
    B.(
      route () |> host clob_api_host |> method_ "DELETE" |> path "/orders"
      |> limit ~requests:1000 ~window_seconds:10.0
      |> limit ~requests:15000 ~window_seconds:600.0
      |> on_limit behavior |> build);
    (* DELETE /cancel-all: 250/10s burst, 6000/10min sustained *)
    B.(
      route () |> host clob_api_host |> method_ "DELETE" |> path "/cancel-all"
      |> limit ~requests:250 ~window_seconds:10.0
      |> limit ~requests:6000 ~window_seconds:600.0
      |> on_limit behavior |> build);
    (* DELETE /cancel-market-orders: 1000/10s burst, 1500/10min sustained *)
    B.(
      route () |> host clob_api_host |> method_ "DELETE"
      |> path "/cancel-market-orders"
      |> limit ~requests:1000 ~window_seconds:10.0
      |> limit ~requests:1500 ~window_seconds:600.0
      |> on_limit behavior |> build);
  ]

(* CLOB Market Data endpoints *)
let clob_market_data ~behavior =
  [
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/book"
      ~requests:1500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/books"
      ~requests:500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/price"
      ~requests:1500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/prices"
      ~requests:500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/midprice"
      ~requests:1500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/midprices"
      ~requests:500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/prices-history"
      ~requests:1000 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/tick-size"
      ~requests:200 ~window_seconds:10.0 ~behavior;
  ]

(* CLOB Ledger endpoints *)
let clob_ledger ~behavior =
  [
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/data/orders"
      ~requests:500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/data/trades"
      ~requests:500 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/notifications"
      ~requests:125 ~window_seconds:10.0 ~behavior;
    (* General ledger endpoints: /trades, /orders, /order *)
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/trades"
      ~requests:900 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/orders"
      ~requests:900 ~window_seconds:10.0 ~behavior;
  ]

(* CLOB Balance and Auth endpoints *)
let clob_other ~behavior =
  [
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/balance-allowance"
      ~requests:200 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"POST"
      ~path:"/balance-allowance" ~requests:50 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"GET" ~path:"/api-keys"
      ~requests:100 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"POST" ~path:"/api-keys"
      ~requests:100 ~window_seconds:10.0 ~behavior;
    B.per_endpoint ~host:clob_api_host ~method_:"DELETE" ~path:"/api-keys"
      ~requests:100 ~window_seconds:10.0 ~behavior;
  ]

let clob_api ~behavior =
  (* Trading endpoints first (most specific, with burst+sustained) *)
  clob_trading ~behavior @ clob_market_data ~behavior @ clob_ledger ~behavior
  @ clob_other ~behavior
  @ [
      (* General CLOB limit last *)
      B.per_host ~host:clob_api_host ~requests:9000 ~window_seconds:10.0
        ~behavior;
    ]

(* {1 Combined Presets} *)

let all ~behavior =
  data_api ~behavior @ gamma_api ~behavior @ clob_api ~behavior
  @ general ~behavior
