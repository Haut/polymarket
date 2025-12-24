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

(* Helper to print section headers *)
let section name =
  Printf.printf "\n%s\n%s\n" name (String.make (String.length name) '=')

(* Helper to print results *)
let print_result_count name result =
  match result with
  | Ok items -> Printf.printf "[OK] %s: %d items\n" name (List.length items)
  | Error err ->
      Printf.printf "[ERROR] %s: %s\n" name err.Common.Http_client.error

let run_demo env =
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in

  Printf.printf "Polymarket Data API Demo\n";
  Printf.printf "========================\n";
  Printf.printf "Base URL: %s\n" Data_api.Client.default_base_url;

  (* Create the client *)
  let client = Data_api.Client.create ~sw ~net () in

  (* Health Check *)
  section "Health Check";
  let health = Data_api.Client.health_check client in
  (match health with
  | Ok resp -> (
      Printf.printf "[OK] Health check passed\n";
      match resp.data with
      | Some d -> Printf.printf "    Data: %s\n" d
      | None -> ())
  | Error err -> Printf.printf "[ERROR] %s\n" err.error);

  (* Positions *)
  section "Positions";
  let positions =
    Data_api.Client.get_positions client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_positions" positions;
  (match positions with
  | Ok items when List.length items > 0 ->
      let pos = List.hd items in
      Printf.printf "    First position: %s\n"
        (Option.value ~default:"(no title)" pos.title)
  | _ -> ());

  (* Trades *)
  section "Trades";
  let trades = Data_api.Client.get_trades client ~limit:5 () in
  print_result_count "get_trades (all)" trades;

  let user_trades =
    Data_api.Client.get_trades client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_trades (by user)" user_trades;

  (* Activity *)
  section "Activity";
  let activity =
    Data_api.Client.get_activity client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_activity" activity;

  (* Holders *)
  section "Holders";
  let holders =
    Data_api.Client.get_holders client ~market:[ sample_market ] ~limit:5 ()
  in
  print_result_count "get_holders" holders;

  (* Traded *)
  section "Traded";
  let traded = Data_api.Client.get_traded client ~user:sample_user () in
  (match traded with
  | Ok t ->
      Printf.printf "[OK] get_traded: user has traded %d markets\n"
        (Option.value ~default:0 t.traded)
  | Error err -> Printf.printf "[ERROR] get_traded: %s\n" err.error);

  (* Value *)
  section "Value";
  let value = Data_api.Client.get_value client ~user:sample_user () in
  print_result_count "get_value" value;

  (* Open Interest *)
  section "Open Interest";
  let oi = Data_api.Client.get_open_interest client () in
  print_result_count "get_open_interest (all)" oi;

  let oi_market =
    Data_api.Client.get_open_interest client ~market:[ sample_market ] ()
  in
  print_result_count "get_open_interest (by market)" oi_market;

  (* Live Volume *)
  section "Live Volume";
  let volume = Data_api.Client.get_live_volume client ~id:sample_event_id () in
  print_result_count "get_live_volume" volume;

  (* Closed Positions *)
  section "Closed Positions";
  let closed =
    Data_api.Client.get_closed_positions client ~user:sample_user ~limit:5 ()
  in
  print_result_count "get_closed_positions" closed;

  (* Builder Leaderboard *)
  section "Builder Leaderboard";
  let builders =
    Data_api.Client.get_builder_leaderboard client
      ~time_period:Data_api.Params.WEEK ~limit:5 ()
  in
  print_result_count "get_builder_leaderboard" builders;
  (match builders with
  | Ok items when List.length items > 0 ->
      let b = List.hd items in
      Printf.printf "    Top builder: %s\n"
        (Option.value ~default:"(unknown)" b.builder)
  | _ -> ());

  (* Builder Volume *)
  section "Builder Volume";
  let builder_vol =
    Data_api.Client.get_builder_volume client ~time_period:Data_api.Params.WEEK
      ()
  in
  print_result_count "get_builder_volume" builder_vol;

  (* Trader Leaderboard *)
  section "Trader Leaderboard";
  let traders =
    Data_api.Client.get_trader_leaderboard client
      ~category:Data_api.Params.OVERALL ~time_period:Data_api.Params.WEEK
      ~order_by:Data_api.Params.PNL ~limit:5 ()
  in
  print_result_count "get_trader_leaderboard" traders;
  (match traders with
  | Ok items when List.length items > 0 ->
      let t = List.hd items in
      Printf.printf "    Top trader: %s (rank %s)\n"
        (Option.value ~default:"(anonymous)" t.user_name)
        (Option.value ~default:"?" t.rank)
  | _ -> ());

  (* Summary *)
  section "Summary";
  Printf.printf "Demo complete! All endpoints were called.\n";
  Printf.printf
    "Note: Empty results may indicate no matching data for sample parameters.\n"

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo
