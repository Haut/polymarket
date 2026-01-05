(** Pre-configured rate limit presets for Polymarket APIs.

    Based on official documentation:
    https://docs.polymarket.com/#/api-rate-limits *)

module B = Rate_limiter.Builder

(** Helper to collect Results into a single Result of list *)
let collect_results results =
  let rec loop acc = function
    | [] -> Ok (List.rev acc)
    | Ok x :: rest -> loop (x :: acc) rest
    | Error e :: _ -> Error e
  in
  loop [] results

(* {1 General Rate Limits} *)

let general ~behavior =
  collect_results [ B.global ~requests:15000 ~window_seconds:10.0 ~behavior ]

(* {1 Data API Rate Limits} *)

let data_api_host = "data-api.polymarket.com"

let data_api ~behavior =
  collect_results
    [
      (* Specific endpoints first *)
      B.per_endpoint ~host:data_api_host ~method_:"GET" ~path:"/trades"
        ~requests:200 ~window_seconds:10.0 ~behavior;
      B.per_endpoint ~host:data_api_host ~method_:"GET" ~path:"/positions"
        ~requests:150 ~window_seconds:10.0 ~behavior;
      B.per_endpoint ~host:data_api_host ~method_:"GET"
        ~path:"/closed-positions" ~requests:150 ~window_seconds:10.0 ~behavior;
      (* General Data API limit *)
      B.per_host ~host:data_api_host ~requests:1000 ~window_seconds:10.0
        ~behavior;
    ]

(* {1 Gamma API Rate Limits} *)

let gamma_api_host = "gamma-api.polymarket.com"

let gamma_api ~behavior =
  collect_results
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

(* CLOB Trading endpoints with burst (10s) + sustained (10min) limits *)
let clob_trading ~behavior =
  let ep ~meth ~p ~burst ~sustained =
    B.(
      route () |> host clob_api_host |> method_ meth |> path p
      |> limit ~requests:burst ~window_seconds:10.0
      |> limit ~requests:sustained ~window_seconds:600.0
      |> on_limit behavior |> build)
  in
  collect_results
    [
      ep ~meth:"POST" ~p:"/order" ~burst:3500 ~sustained:36000;
      ep ~meth:"DELETE" ~p:"/order" ~burst:3000 ~sustained:30000;
      ep ~meth:"POST" ~p:"/orders" ~burst:1000 ~sustained:15000;
      ep ~meth:"DELETE" ~p:"/orders" ~burst:1000 ~sustained:15000;
      ep ~meth:"DELETE" ~p:"/cancel-all" ~burst:250 ~sustained:6000;
      ep ~meth:"DELETE" ~p:"/cancel-market-orders" ~burst:1000 ~sustained:1500;
    ]

(* CLOB Market Data endpoints *)
let clob_market_data ~behavior =
  collect_results
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
  collect_results
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
  collect_results
    [
      B.per_endpoint ~host:clob_api_host ~method_:"GET"
        ~path:"/balance-allowance" ~requests:200 ~window_seconds:10.0 ~behavior;
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
  (* Combine all CLOB configs *)
  match
    ( clob_trading ~behavior,
      clob_market_data ~behavior,
      clob_ledger ~behavior,
      clob_other ~behavior,
      B.per_host ~host:clob_api_host ~requests:9000 ~window_seconds:10.0
        ~behavior )
  with
  | Ok trading, Ok market_data, Ok ledger, Ok other, Ok general_limit ->
      Ok (trading @ market_data @ ledger @ other @ [ general_limit ])
  | Error e, _, _, _, _ -> Error e
  | _, Error e, _, _, _ -> Error e
  | _, _, Error e, _, _ -> Error e
  | _, _, _, Error e, _ -> Error e
  | _, _, _, _, Error e -> Error e

(* {1 Combined Presets} *)

let all ~behavior =
  match
    ( data_api ~behavior,
      gamma_api ~behavior,
      clob_api ~behavior,
      general ~behavior )
  with
  | Ok data, Ok gamma, Ok clob, Ok gen -> Ok (data @ gamma @ clob @ gen)
  | Error e, _, _, _ -> Error e
  | _, Error e, _, _ -> Error e
  | _, _, Error e, _ -> Error e
  | _, _, _, Error e -> Error e
