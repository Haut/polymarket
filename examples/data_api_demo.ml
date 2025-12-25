(** Live demo of the Polymarket Data API client.

    This example calls all Data API endpoints and prints the results. Run with:
    dune exec examples/data_api_demo.exe

    Note: Some endpoints require valid user addresses or market IDs to return
    data. The demo uses sample values that may or may not have data. *)

open Polymarket

(* Sample data for testing - these are real Polymarket values *)

(* A known active trader address *)
let sample_user = Address.make_exn "0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d59"

(* A sample condition ID (market) - 2024 US Presidential Election Winner *)
let sample_market =
  Hash64.make_exn
    "0xdd22472e552920b8438f08c8830e189a5a159cc4e8d5f2fb0f0e8e9a7e3e2a5e"

(* A sample event ID *)
let sample_event_id = 903

(* Helper functions *)
let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name err.Http.error

let run_demo env =
  (* Initialize demo logger (disables noise from other libraries) *)
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in

  Logger.info "START"
    [ ("demo", "Data API"); ("base_url", Data.default_base_url) ];

  (* Create the client *)
  let client = Data.create ~sw ~net () in

  (* Health Check *)
  Logger.header "Health Check";
  let health = Data.health_check client in
  (match health with
  | Ok resp ->
      Logger.ok "health_check" "passed";
      Logger.info "DATA" [ ("value", resp.data) ]
  | Error err -> Logger.error "health_check" err.error);

  (* Positions *)
  Logger.header "Positions";
  let positions =
    Data.get_positions client ~user:sample_user ~limit:(Limit.of_int_exn 5) ()
  in
  print_result_count "get_positions" positions;
  (match positions with
  | Ok items when List.length items > 0 ->
      let pos = List.hd items in
      Logger.info "FIRST" [ ("position", pos.title) ]
  | _ -> ());

  (* Trades *)
  Logger.header "Trades";
  let trades = Data.get_trades client ~limit:(Nonneg_int.of_int_exn 5) () in
  print_result_count "get_trades (all)" trades;

  let user_trades =
    Data.get_trades client ~user:sample_user ~limit:(Nonneg_int.of_int_exn 5) ()
  in
  print_result_count "get_trades (by user)" user_trades;

  (* Activity *)
  Logger.header "Activity";
  let activity =
    Data.get_activity client ~user:sample_user ~limit:(Limit.of_int_exn 5) ()
  in
  print_result_count "get_activity" activity;

  (* Holders *)
  Logger.header "Holders";
  let holders =
    Data.get_holders client ~market:[ sample_market ]
      ~limit:(Holders_limit.of_int_exn 5)
      ()
  in
  print_result_count "get_holders" holders;

  (* Traded *)
  Logger.header "Traded";
  let traded = Data.get_traded client ~user:sample_user () in
  (match traded with
  | Ok t ->
      Logger.ok "get_traded"
        (Printf.sprintf "user has traded %d markets" t.traded)
  | Error err -> Logger.error "get_traded" err.error);

  (* Value *)
  Logger.header "Value";
  let value = Data.get_value client ~user:sample_user () in
  print_result_count "get_value" value;

  (* Open Interest *)
  Logger.header "Open Interest";
  let oi = Data.get_open_interest client () in
  print_result_count "get_open_interest (all)" oi;

  let oi_market = Data.get_open_interest client ~market:[ sample_market ] () in
  print_result_count "get_open_interest (by market)" oi_market;

  (* Live Volume *)
  Logger.header "Live Volume";
  let volume =
    Data.get_live_volume client ~id:(Pos_int.of_int_exn sample_event_id) ()
  in
  print_result_count "get_live_volume" volume;

  (* Closed Positions *)
  Logger.header "Closed Positions";
  let closed =
    Data.get_closed_positions client ~user:sample_user
      ~limit:(Closed_positions_limit.of_int_exn 5)
      ()
  in
  print_result_count "get_closed_positions" closed;

  (* Builder Leaderboard *)
  Logger.header "Builder Leaderboard";
  let builders =
    Data.get_builder_leaderboard client ~time_period:Data.WEEK
      ~limit:(Builder_limit.of_int_exn 5)
      ()
  in
  print_result_count "get_builder_leaderboard" builders;
  (match builders with
  | Ok items when List.length items > 0 ->
      let b = List.hd items in
      Logger.info "TOP" [ ("builder", b.builder) ]
  | _ -> ());

  (* Builder Volume *)
  Logger.header "Builder Volume";
  let builder_vol = Data.get_builder_volume client ~time_period:Data.WEEK () in
  print_result_count "get_builder_volume" builder_vol;

  (* Trader Leaderboard *)
  Logger.header "Trader Leaderboard";
  let traders =
    Data.get_trader_leaderboard client ~category:Data.OVERALL
      ~time_period:Data.WEEK ~order_by:Data.PNL
      ~limit:(Leaderboard_limit.of_int_exn 5)
      ()
  in
  print_result_count "get_trader_leaderboard" traders;
  (match traders with
  | Ok items when List.length items > 0 ->
      let t = List.hd items in
      Logger.info "TOP" [ ("trader", t.user_name); ("rank", t.rank) ]
  | _ -> ());

  (* Summary *)
  Logger.header "Summary";
  Logger.info "COMPLETE" [ ("status", "all endpoints called") ];
  Logger.info "NOTE"
    [
      ( "message",
        "Empty results may indicate no matching data for sample parameters" );
    ]

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo
