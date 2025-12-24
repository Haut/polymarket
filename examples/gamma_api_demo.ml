(** Live demo of the Polymarket Gamma API client.

    This example calls all Gamma API endpoints and prints the results. Run with:
    dune exec examples/gamma_api_demo.exe

    The demo dynamically discovers valid IDs from list endpoints to ensure
    detail endpoints are called with real data. *)

open Polymarket

(** {1 Helper Functions} *)

let log = Common.Logger.info
let section = Common.Logger.section
let log_ok = Common.Logger.ok
let log_error name err = Common.Logger.error name err.Http_client.Client.error
let log_skip = Common.Logger.skip

let print_result_count name result =
  match result with
  | Ok items -> log_ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> log_error name err

let print_result name ~on_ok result =
  match result with
  | Ok value -> log_ok name (on_ok value)
  | Error err -> log_error name err

(** {1 ID Extraction Helpers} *)

let first_event_id (events : Gamma_api.Types.event list) =
  match events with
  | [] -> None
  | e :: _ -> (
      match e.id with
      | Some id -> ( try Some (int_of_string id) with _ -> None)
      | None -> None)

let first_event_slug (events : Gamma_api.Types.event list) =
  match events with [] -> None | e :: _ -> e.slug

let first_market_id (markets : Gamma_api.Types.market list) =
  match markets with
  | [] -> None
  | m :: _ -> (
      match m.id with
      | Some id -> ( try Some (int_of_string id) with _ -> None)
      | None -> None)

let first_market_slug (markets : Gamma_api.Types.market list) =
  match markets with [] -> None | m :: _ -> m.slug

let first_series_id (series_list : Gamma_api.Types.series list) =
  match series_list with
  | [] -> None
  | s :: _ -> (
      match s.id with
      | Some id -> ( try Some (int_of_string id) with _ -> None)
      | None -> None)

let first_tag_id (tags : Gamma_api.Types.tag list) =
  match tags with [] -> None | t :: _ -> t.id

let first_tag_slug (tags : Gamma_api.Types.tag list) =
  match tags with [] -> None | t :: _ -> t.slug

let first_team_id (teams : Gamma_api.Types.team list) =
  match teams with [] -> None | t :: _ -> t.id

let first_comment_id (comments : Gamma_api.Types.comment list) =
  match comments with
  | [] -> None
  | c :: _ -> (
      match c.id with
      | Some id -> ( try Some (int_of_string id) with _ -> None)
      | None -> None)

let first_user_address (comments : Gamma_api.Types.comment list) =
  match comments with [] -> None | c :: _ -> c.user_address

(** {1 Main Demo} *)

let run_demo env =
  (* Initialize logging from POLYMARKET_LOG_LEVEL environment variable *)
  Common.Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in

  log "Polymarket Gamma API Demo";
  log "=========================";
  log (Printf.sprintf "Base URL: %s" Gamma_api.Client.default_base_url);

  let client = Gamma_api.Client.create ~sw ~net () in

  (* ===== Health Check ===== *)
  section "Health Check";
  let status = Gamma_api.Client.status client in
  print_result "status" status ~on_ok:(fun s -> s);

  (* ===== Teams ===== *)
  section "Teams";
  let teams = Gamma_api.Client.get_teams client () in
  print_result_count "get_teams" teams;

  let team_id = match teams with Ok t -> first_team_id t | Error _ -> None in
  (match team_id with
  | Some id ->
      let team = Gamma_api.Client.get_team client ~id () in
      print_result "get_team" team ~on_ok:(fun (t : Gamma_api.Types.team) ->
          Option.value ~default:"(no name)" t.name)
  | None -> log_skip "get_team" "no team ID available");

  (* ===== Tags ===== *)
  section "Tags";
  let tags = Gamma_api.Client.get_tags client ~limit:10 () in
  print_result_count "get_tags" tags;

  let tag_id, tag_slug =
    match tags with
    | Ok t -> (first_tag_id t, first_tag_slug t)
    | Error _ -> (None, None)
  in
  (match tag_id with
  | Some id ->
      let tag = Gamma_api.Client.get_tag client ~id () in
      print_result "get_tag" tag ~on_ok:(fun (t : Gamma_api.Types.tag) ->
          Option.value ~default:"(no label)" t.label);

      let related = Gamma_api.Client.get_related_tags client ~id () in
      print_result_count "get_related_tags" related
  | None ->
      log_skip "get_tag" "no tag ID available";
      log_skip "get_related_tags" "no tag ID available");

  (match tag_slug with
  | Some slug ->
      let tag = Gamma_api.Client.get_tag_by_slug client ~slug () in
      print_result "get_tag_by_slug" tag
        ~on_ok:(fun (t : Gamma_api.Types.tag) ->
          Option.value ~default:"(no label)" t.label)
  | None -> log_skip "get_tag_by_slug" "no tag slug available");

  (* ===== Events ===== *)
  section "Events";
  let events = Gamma_api.Client.get_events client ~limit:10 ~active:true () in
  print_result_count "get_events" events;

  let event_id, event_slug =
    match events with
    | Ok ev -> (first_event_id ev, first_event_slug ev)
    | Error _ -> (None, None)
  in

  (match event_id with
  | Some id ->
      let event = Gamma_api.Client.get_event client ~id () in
      print_result "get_event" event ~on_ok:(fun (e : Gamma_api.Types.event) ->
          Option.value ~default:"(no title)" e.title);

      let event_tags = Gamma_api.Client.get_event_tags client ~id () in
      print_result_count "get_event_tags" event_tags
  | None ->
      log_skip "get_event" "no event ID available";
      log_skip "get_event_tags" "no event ID available");

  (match event_slug with
  | Some slug ->
      let event = Gamma_api.Client.get_event_by_slug client ~slug () in
      print_result "get_event_by_slug" event
        ~on_ok:(fun (e : Gamma_api.Types.event) ->
          Option.value ~default:"(no title)" e.title)
  | None -> log_skip "get_event_by_slug" "no event slug available");

  (* ===== Markets ===== *)
  section "Markets";
  let markets = Gamma_api.Client.get_markets client ~limit:10 ~active:true () in
  print_result_count "get_markets" markets;

  let market_id, market_slug =
    match markets with
    | Ok m -> (first_market_id m, first_market_slug m)
    | Error _ -> (None, None)
  in

  (match market_id with
  | Some id ->
      let market = Gamma_api.Client.get_market client ~id () in
      print_result "get_market" market
        ~on_ok:(fun (m : Gamma_api.Types.market) ->
          Option.value ~default:"(no question)" m.question);

      let market_tags = Gamma_api.Client.get_market_tags client ~id () in
      print_result_count "get_market_tags" market_tags;

      let description = Gamma_api.Client.get_market_description client ~id () in
      print_result "get_market_description" description
        ~on_ok:(fun (d : Gamma_api.Types.market_description) ->
          let desc = Option.value ~default:"(none)" d.description in
          if String.length desc > 50 then String.sub desc 0 50 ^ "..." else desc)
  | None ->
      log_skip "get_market" "no market ID available";
      log_skip "get_market_tags" "no market ID available";
      log_skip "get_market_description" "no market ID available");

  (match market_slug with
  | Some slug ->
      let market = Gamma_api.Client.get_market_by_slug client ~slug () in
      print_result "get_market_by_slug" market
        ~on_ok:(fun (m : Gamma_api.Types.market) ->
          Option.value ~default:"(no question)" m.question)
  | None -> log_skip "get_market_by_slug" "no market slug available");

  (* ===== Series ===== *)
  section "Series";
  let series_list = Gamma_api.Client.get_series_list client ~limit:10 () in
  print_result_count "get_series_list" series_list;

  let series_id =
    match series_list with Ok s -> first_series_id s | Error _ -> None
  in

  (match series_id with
  | Some id ->
      let series = Gamma_api.Client.get_series client ~id () in
      print_result "get_series" series
        ~on_ok:(fun (s : Gamma_api.Types.series) ->
          Option.value ~default:"(no title)" s.title);

      let summary = Gamma_api.Client.get_series_summary client ~id () in
      print_result "get_series_summary" summary
        ~on_ok:(fun (s : Gamma_api.Types.series_summary) ->
          Printf.sprintf "%s (%d dates, %d weeks)"
            (Option.value ~default:"(no title)" s.title)
            (List.length s.event_dates)
            (List.length s.event_weeks))
  | None ->
      log_skip "get_series" "no series ID available";
      log_skip "get_series_summary" "no series ID available");

  (* ===== Comments ===== *)
  section "Comments";
  (* Comments require both parent_entity_type and parent_entity_id *)
  let comments =
    match event_id with
    | Some eid ->
        Gamma_api.Client.get_comments client
          ~parent_entity_type:Gamma_api.Params.Event ~parent_entity_id:eid
          ~limit:10 ()
    | None -> Error { Http_client.Client.error = "No event ID for comments" }
  in
  print_result_count "get_comments" comments;

  let comment_id, user_address =
    match comments with
    | Ok c -> (first_comment_id c, first_user_address c)
    | Error _ -> (None, None)
  in

  (match comment_id with
  | Some id ->
      let comment = Gamma_api.Client.get_comment client ~id () in
      print_result "get_comment" comment
        ~on_ok:(fun (c : Gamma_api.Types.comment) ->
          let body = Option.value ~default:"(no body)" c.body in
          if String.length body > 50 then String.sub body 0 50 ^ "..." else body)
  | None -> log_skip "get_comment" "no comment ID available");

  (match user_address with
  | Some addr ->
      let user_comments =
        Gamma_api.Client.get_user_comments client ~user_address:addr ~limit:5 ()
      in
      print_result_count "get_user_comments" user_comments
  | None -> log_skip "get_user_comments" "no user address available");

  (* ===== Profiles ===== *)
  section "Profiles";
  (* Use a known test address for profile testing *)
  let test_address = "0xa41249c581990c31fb2a0dfc4417ede58e0de774" in
  let public_profile =
    Gamma_api.Client.get_public_profile client ~address:test_address ()
  in
  print_result "get_public_profile" public_profile
    ~on_ok:(fun (p : Gamma_api.Types.public_profile_response) ->
      Option.value ~default:"(no name)" p.name);

  let profile =
    Gamma_api.Client.get_profile client ~user_address:test_address ()
  in
  print_result "get_profile" profile
    ~on_ok:(fun (p : Gamma_api.Types.profile) ->
      Option.value ~default:"(no pseudonym)" p.pseudonym);

  (* ===== Sports ===== *)
  section "Sports";
  let sports = Gamma_api.Client.get_sports client () in
  print_result_count "get_sports" sports;

  let market_types = Gamma_api.Client.get_sports_market_types client () in
  print_result "get_sports_market_types" market_types
    ~on_ok:(fun (r : Gamma_api.Types.sports_market_types_response) ->
      Printf.sprintf "%d market types" (List.length r.market_types));

  (* ===== Search ===== *)
  section "Search";
  let search =
    Gamma_api.Client.public_search client ~q:"election" ~limit_per_type:5 ()
  in
  print_result "public_search" search
    ~on_ok:(fun (s : Gamma_api.Types.search) ->
      let event_count =
        match s.events with Some e -> List.length e | None -> 0
      in
      let tag_count = match s.tags with Some t -> List.length t | None -> 0 in
      Printf.sprintf "%d events, %d tags" event_count tag_count);

  (* ===== Summary ===== *)
  section "Summary";
  log "Demo complete! All Gamma API endpoints were exercised.";
  log "Endpoints that returned [SKIP] had no valid IDs to test with.";
  log
    "JSON parse errors indicate the API response has fields not in the type \
     definitions."

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo
