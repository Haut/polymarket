(** Live demo of the Polymarket Data API client.

    This example calls all Data API endpoints and prints the results. Run with:
    dune exec examples/data_api_demo.exe

    Note: Some endpoints require valid user addresses or market IDs to return
    data. The demo uses sample values that may or may not have data. *)

open Polymarket

(* Sample data for testing - these are real Polymarket values *)

(* A known active trader address *)
let sample_user = "0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d59"

(* A sample condition ID (market) - 2024 US Presidential Election Winner *)
let sample_market =
  "0xdd22472e552920b8438f08c8830e189a5a159cc4e8d5f2fb0f0e8e9a7e3e2a5e"

(* A sample event ID *)
let sample_event_id = 903

(* Helper functions *)
let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name err.Http_client.Client.error

let run_demo env =
  (* Initialize demo logger (disables noise from other libraries) *)
  Logger.setup ();
  (* Initialize library logging from POLYMARKET_LOG_LEVEL environment variable *)
  Common.Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in

  Logger.info "START"
    [ ("demo", "Data API"); ("base_url", Data_api.Client.default_base_url) ];

  (* Create the client *)
  let client = Data_api.Client.create ~sw ~net () in

  (* Health Check *)
  Logger.header "Health Check";
  let health = Data_api.Client.health_check client in
  (match health with
  | Ok resp -> (
      Logger.ok "health_check" "passed";
      match resp.data with
      | Some d -> Logger.info "DATA" [ ("value", d) ]
      | None -> ())
  | Error err -> Logger.error "health_check" err.error);

  (* Positions *)
  Logger.header "Positions";
  let positions =
    Data_api.Client.get_positions client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_positions" positions;
  (match positions with
  | Ok items when List.length items > 0 ->
      let pos = List.hd items in
      Logger.info "FIRST"
        [ ("position", Option.value ~default:"(no title)" pos.title) ]
  | _ -> ());

  (* Trades *)
  Logger.header "Trades";
  let trades = Data_api.Client.get_trades client ~limit:5 () in
  print_result_count "get_trades (all)" trades;

  let user_trades =
    Data_api.Client.get_trades client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_trades (by user)" user_trades;

  (* Activity *)
  Logger.header "Activity";
  let activity =
    Data_api.Client.get_activity client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_activity" activity;

  (* Holders *)
  Logger.header "Holders";
  let holders =
    Data_api.Client.get_holders client ~market:[ sample_market ] ~limit:5 ()
  in
  print_result_count "get_holders" holders;

  (* Traded *)
  Logger.header "Traded";
  let traded = Data_api.Client.get_traded client ~user:sample_user () in
  (match traded with
  | Ok t ->
      Logger.ok "get_traded"
        (Printf.sprintf "user has traded %d markets"
           (Option.value ~default:0 t.traded))
  | Error err -> Logger.error "get_traded" err.error);

  (* Value *)
  Logger.header "Value";
  let value = Data_api.Client.get_value client ~user:sample_user () in
  print_result_count "get_value" value;

  (* Open Interest *)
  Logger.header "Open Interest";
  let oi = Data_api.Client.get_open_interest client () in
  print_result_count "get_open_interest (all)" oi;

  let oi_market =
    Data_api.Client.get_open_interest client ~market:[ sample_market ] ()
  in
  print_result_count "get_open_interest (by market)" oi_market;

  (* Live Volume *)
  Logger.header "Live Volume";
  let volume = Data_api.Client.get_live_volume client ~id:sample_event_id () in
  print_result_count "get_live_volume" volume;

  (* Closed Positions *)
  Logger.header "Closed Positions";
  let closed =
    Data_api.Client.get_closed_positions client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_closed_positions" closed;

  (* Builder Leaderboard *)
  Logger.header "Builder Leaderboard";
  let builders =
    Data_api.Client.get_builder_leaderboard client
      ~time_period:Data_api.Types.WEEK ~limit:5 ()
  in
  print_result_count "get_builder_leaderboard" builders;
  (match builders with
  | Ok items when List.length items > 0 ->
      let b = List.hd items in
      Logger.info "TOP"
        [ ("builder", Option.value ~default:"(unknown)" b.builder) ]
  | _ -> ());

  (* Builder Volume *)
  Logger.header "Builder Volume";
  let builder_vol =
    Data_api.Client.get_builder_volume client ~time_period:Data_api.Types.WEEK
      ()
  in
  print_result_count "get_builder_volume" builder_vol;

  (* Trader Leaderboard *)
  Logger.header "Trader Leaderboard";
  let traders =
    Data_api.Client.get_trader_leaderboard client
      ~category:Data_api.Types.OVERALL ~time_period:Data_api.Types.WEEK
      ~order_by:Data_api.Types.PNL ~limit:5 ()
  in
  print_result_count "get_trader_leaderboard" traders;
  (match traders with
  | Ok items when List.length items > 0 ->
      let t = List.hd items in
      Logger.info "TOP"
        [
          ("trader", Option.value ~default:"(anonymous)" t.user_name);
          ("rank", Option.value ~default:"?" t.rank);
        ]
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
