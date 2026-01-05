(** Live demo of the Polymarket Data API client.

    This example calls all Data API endpoints and prints the results. Run with:
    dune exec examples/data_api_demo.exe

    Uses Gamma API to discover real user addresses and market IDs for better
    results. *)

open Polymarket

(** {1 Helper Functions} *)

let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name (Data.error_to_string err)

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name (Data.error_to_string err)

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let clock = Eio.Stdenv.clock env in
  let net = Eio.Stdenv.net env in

  Logger.info
    (Printf.sprintf "Starting Data API demo (%s)" Data.default_base_url);

  (* Create shared rate limiter *)
  let routes =
    match Rate_limit_presets.all ~behavior:Rate_limiter.Delay with
    | Ok r -> r
    | Error msg -> failwith ("Rate limit preset error: " ^ msg)
  in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in

  (* Create clients *)
  let data_client =
    match Data.create ~sw ~net ~rate_limiter () with
    | Ok c -> c
    | Error e -> failwith ("Data client error: " ^ Data.string_of_init_error e)
  in
  let gamma_client =
    match Gamma.create ~sw ~net ~rate_limiter () with
    | Ok c -> c
    | Error e -> failwith ("Gamma client error: " ^ Gamma.string_of_init_error e)
  in

  (* ===== Health Check ===== *)
  let health = Data.health_check data_client in
  print_result "health_check" health ~on_ok:(fun (r : Data.health_response) ->
      r.data);

  (* ===== Global Trades ===== *)
  let trades = Data.get_trades data_client ~limit:10 () in
  print_result_count "get_trades" trades;

  (* Extract a market (condition_id) from trades for later use *)
  let trade_market =
    match trades with
    | Ok ((t : Data.trade) :: _) -> Some t.condition_id
    | _ -> None
  in

  (* ===== Open Interest ===== *)
  let oi = Data.get_open_interest data_client () in
  print_result_count "get_open_interest" oi;

  (match trade_market with
  | Some market ->
      let oi_market =
        Data.get_open_interest data_client ~market:[ market ] ()
      in
      print_result "get_open_interest (market)" oi_market ~on_ok:(fun items ->
          Printf.sprintf "%d items" (List.length items))
  | None -> Logger.skip "get_open_interest (market)" "no market from trades");

  (* ===== Live Volume ===== *)
  (* Get an event ID from Gamma for live volume *)
  let events = Gamma.get_events gamma_client ~limit:1 ~active:true () in
  (match events with
  | Ok ((e : Gamma.event) :: _) -> (
      match int_of_string_opt e.id with
      | Some event_id ->
          let volume = Data.get_live_volume data_client ~id:event_id () in
          print_result_count "get_live_volume" volume
      | None -> Logger.skip "get_live_volume" "event ID not an int")
  | _ -> Logger.skip "get_live_volume" "no events from Gamma");

  (* ===== Leaderboards ===== *)
  let builders =
    Data.get_builder_leaderboard data_client ~time_period:Data.Time_period.Week
      ~limit:5 ()
  in
  print_result "get_builder_leaderboard" builders ~on_ok:(fun items ->
      Printf.sprintf "%d items" (List.length items));

  let builder_vol =
    Data.get_builder_volume data_client ~time_period:Data.Time_period.Week ()
  in
  print_result "get_builder_volume" builder_vol ~on_ok:(fun items ->
      Printf.sprintf "%d items" (List.length items));

  let traders =
    Data.get_trader_leaderboard data_client
      ~category:Data.Leaderboard_category.Overall
      ~time_period:Data.Time_period.Week ~order_by:Data.Leaderboard_order_by.Pnl
      ~limit:5 ()
  in
  print_result "get_trader_leaderboard" traders ~on_ok:(fun items ->
      Printf.sprintf "%d items" (List.length items));

  (* Get a real user address from trader leaderboard *)
  let active_user =
    match traders with
    | Ok ((t : Data.trader_leaderboard_entry) :: _) ->
        Logger.info (Printf.sprintf "Using trader: %s" t.user_name);
        Some t.proxy_wallet
    | _ -> None
  in

  (* ===== User Data ===== *)
  (match active_user with
  | Some user ->
      let positions = Data.get_positions data_client ~user ~limit:5 () in
      print_result_count "get_positions" positions;

      let user_trades = Data.get_trades data_client ~user ~limit:5 () in
      print_result_count "get_trades (user)" user_trades;

      let activity = Data.get_activity data_client ~user ~limit:5 () in
      print_result_count "get_activity" activity;

      let traded = Data.get_traded data_client ~user () in
      print_result "get_traded" traded ~on_ok:(fun (t : Data.traded) ->
          Printf.sprintf "%d markets" t.traded);

      let value = Data.get_value data_client ~user () in
      print_result_count "get_value" value;

      let closed = Data.get_closed_positions data_client ~user ~limit:5 () in
      print_result_count "get_closed_positions" closed
  | None ->
      Logger.skip "get_positions" "no active user found";
      Logger.skip "get_trades (user)" "no active user found";
      Logger.skip "get_activity" "no active user found";
      Logger.skip "get_traded" "no active user found";
      Logger.skip "get_value" "no active user found";
      Logger.skip "get_closed_positions" "no active user found");

  (* ===== Market Data ===== *)
  (match trade_market with
  | Some market ->
      let holders =
        Data.get_holders data_client ~market:[ market ] ~limit:5 ()
      in
      print_result_count "get_holders" holders
  | None -> Logger.skip "get_holders" "no market from trades");

  (* ===== Summary ===== *)
  Logger.info "All endpoints exercised"

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
