(** Live demo of the Polymarket Gamma API client.

    This example calls all Gamma API endpoints and prints the results. Run with:
    dune exec examples/gamma_api_demo.exe

    The demo dynamically discovers valid IDs from list endpoints to ensure
    detail endpoints are called with real data. *)

open Polymarket

(** {1 Helper Functions} *)

let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name err.Http_client.Client.error

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name err.Http_client.Client.error

(** {1 ID Extraction Helpers} *)

let first_event_id (events : Gamma_api.Responses.event list) =
  match events with
  | [] -> None
  | e :: _ -> (
      match e.id with
      | Some id -> ( try Some (int_of_string id) with _ -> None)
      | None -> None)

let first_event_slug (events : Gamma_api.Responses.event list) =
  match events with [] -> None | e :: _ -> e.slug

let first_market_id (markets : Gamma_api.Responses.market list) =
  match markets with
  | [] -> None
  | m :: _ -> (
      match m.id with
      | Some id -> ( try Some (int_of_string id) with _ -> None)
      | None -> None)

let first_market_slug (markets : Gamma_api.Responses.market list) =
  match markets with [] -> None | m :: _ -> m.slug

let first_series_id (series_list : Gamma_api.Responses.series list) =
  match series_list with
  | [] -> None
  | s :: _ -> Option.bind s.id (fun id -> int_of_string_opt id)

let first_tag_id (tags : Gamma_api.Responses.tag list) =
  match tags with [] -> None | t :: _ -> t.id

let first_tag_slug (tags : Gamma_api.Responses.tag list) =
  match tags with [] -> None | t :: _ -> t.slug

let first_comment_id (comments : Gamma_api.Responses.comment list) =
  match comments with [] -> None | c :: _ -> int_of_string_opt c.id

let first_user_address (comments : Gamma_api.Responses.comment list) =
  match comments with [] -> None | c :: _ -> c.user_address

(** {1 Main Demo} *)

let run_demo env =
  (* Initialize demo logger (disables noise from other libraries) *)
  Logger.setup ();
  (* Initialize library logging from POLYMARKET_LOG_LEVEL environment variable *)
  Common.Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in

  Logger.info "START"
    [ ("demo", "Gamma API"); ("base_url", Gamma_api.Client.default_base_url) ];

  let client = Gamma_api.Client.create ~sw ~net () in

  (* ===== Health Check ===== *)
  Logger.header "Health Check";
  let status = Gamma_api.Client.status client in
  print_result "status" status ~on_ok:(fun s -> s);

  (* ===== Teams ===== *)
  Logger.header "Teams";
  let teams = Gamma_api.Client.get_teams client () in
  print_result_count "get_teams" teams;

  (* ===== Tags ===== *)
  Logger.header "Tags";
  let tags =
    Gamma_api.Client.get_tags client
      ~limit:(Http_client.Client.Nonneg_int.of_int_exn 10)
      ()
  in
  print_result_count "get_tags" tags;

  let tag_id, tag_slug =
    match tags with
    | Ok t -> (first_tag_id t, first_tag_slug t)
    | Error _ -> (None, None)
  in
  (match tag_id with
  | Some id ->
      let tag = Gamma_api.Client.get_tag client ~id () in
      print_result "get_tag" tag ~on_ok:(fun (t : Gamma_api.Responses.tag) ->
          Option.value ~default:"(no label)" t.label);

      let related = Gamma_api.Client.get_related_tags client ~id () in
      print_result_count "get_related_tags" related
  | None ->
      Logger.skip "get_tag" "no tag ID available";
      Logger.skip "get_related_tags" "no tag ID available");

  (match tag_slug with
  | Some slug ->
      let tag = Gamma_api.Client.get_tag_by_slug client ~slug () in
      print_result "get_tag_by_slug" tag
        ~on_ok:(fun (t : Gamma_api.Responses.tag) ->
          Option.value ~default:"(no label)" t.label)
  | None -> Logger.skip "get_tag_by_slug" "no tag slug available");

  (* ===== Events ===== *)
  Logger.header "Events";
  let events =
    Gamma_api.Client.get_events client
      ~limit:(Http_client.Client.Nonneg_int.of_int_exn 10)
      ~active:true ()
  in
  print_result_count "get_events" events;

  let event_id, event_slug =
    match events with
    | Ok ev -> (first_event_id ev, first_event_slug ev)
    | Error _ -> (None, None)
  in

  (match event_id with
  | Some id ->
      let event = Gamma_api.Client.get_event client ~id () in
      print_result "get_event" event
        ~on_ok:(fun (e : Gamma_api.Responses.event) ->
          Option.value ~default:"(no title)" e.title);

      let event_tags = Gamma_api.Client.get_event_tags client ~id () in
      print_result_count "get_event_tags" event_tags
  | None ->
      Logger.skip "get_event" "no event ID available";
      Logger.skip "get_event_tags" "no event ID available");

  (match event_slug with
  | Some slug ->
      let event = Gamma_api.Client.get_event_by_slug client ~slug () in
      print_result "get_event_by_slug" event
        ~on_ok:(fun (e : Gamma_api.Responses.event) ->
          Option.value ~default:"(no title)" e.title)
  | None -> Logger.skip "get_event_by_slug" "no event slug available");

  (* ===== Markets ===== *)
  Logger.header "Markets";
  let markets =
    Gamma_api.Client.get_markets client
      ~limit:(Http_client.Client.Nonneg_int.of_int_exn 10)
      ()
  in
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
        ~on_ok:(fun (m : Gamma_api.Responses.market) ->
          Option.value ~default:"(no question)" m.question);

      let market_tags = Gamma_api.Client.get_market_tags client ~id () in
      print_result_count "get_market_tags" market_tags
  | None ->
      Logger.skip "get_market" "no market ID available";
      Logger.skip "get_market_tags" "no market ID available");

  (match market_slug with
  | Some slug ->
      let market = Gamma_api.Client.get_market_by_slug client ~slug () in
      print_result "get_market_by_slug" market
        ~on_ok:(fun (m : Gamma_api.Responses.market) ->
          Option.value ~default:"(no question)" m.question)
  | None -> Logger.skip "get_market_by_slug" "no market slug available");

  (* ===== Series ===== *)
  Logger.header "Series";
  let series_list =
    Gamma_api.Client.get_series_list client
      ~limit:(Http_client.Client.Nonneg_int.of_int_exn 10)
      ()
  in
  print_result_count "get_series_list" series_list;

  let series_id =
    match series_list with Ok s -> first_series_id s | Error _ -> None
  in

  (match series_id with
  | Some id ->
      let series = Gamma_api.Client.get_series client ~id () in
      print_result "get_series" series
        ~on_ok:(fun (s : Gamma_api.Responses.series) ->
          Option.value ~default:"(no title)" s.title)
  | None -> Logger.skip "get_series" "no series ID available");

  (* ===== Comments ===== *)
  Logger.header "Comments";
  (* Comments require both parent_entity_type and parent_entity_id *)
  let comments =
    match event_id with
    | Some eid ->
        Gamma_api.Client.get_comments client
          ~limit:(Http_client.Client.Nonneg_int.of_int_exn 10)
          ~parent_entity_type:Gamma_api.Query.Event ~parent_entity_id:eid ()
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
        ~on_ok:(fun (c : Gamma_api.Responses.comment) ->
          let body = Option.value ~default:"(no body)" c.body in
          if String.length body > 50 then String.sub body 0 50 ^ "..." else body)
  | None -> Logger.skip "get_comment" "no comment ID available");

  (match user_address with
  | Some addr ->
      let user_comments =
        Gamma_api.Client.get_user_comments client ~user_address:addr
          ~limit:(Http_client.Client.Nonneg_int.of_int_exn 5)
          ()
      in
      print_result_count "get_user_comments" user_comments
  | None -> Logger.skip "get_user_comments" "no user address available");

  (* ===== Profiles ===== *)
  Logger.header "Profiles";
  (* Use a known test address for profile testing *)
  let test_address = "0xa41249c581990c31fb2a0dfc4417ede58e0de774" in
  let public_profile =
    Gamma_api.Client.get_public_profile client ~address:test_address ()
  in
  print_result "get_public_profile" public_profile
    ~on_ok:(fun (p : Gamma_api.Responses.public_profile_response) ->
      Option.value ~default:"(no name)" p.name);

  let profile =
    Gamma_api.Client.get_profile client ~user_address:test_address ()
  in
  print_result "get_profile" profile
    ~on_ok:(fun (p : Gamma_api.Responses.profile) ->
      Option.value ~default:"(no pseudonym)" p.pseudonym);

  (* ===== Sports ===== *)
  Logger.header "Sports";
  let sports = Gamma_api.Client.get_sports client () in
  print_result_count "get_sports" sports;

  let market_types = Gamma_api.Client.get_sports_market_types client () in
  print_result "get_sports_market_types" market_types
    ~on_ok:(fun (r : Gamma_api.Responses.sports_market_types_response) ->
      Printf.sprintf "%d market types" (List.length r.market_types));

  (* ===== Search ===== *)
  Logger.header "Search";
  let search =
    Gamma_api.Client.public_search client ~q:"election" ~limit_per_type:5 ()
  in
  print_result "public_search" search
    ~on_ok:(fun (s : Gamma_api.Responses.search) ->
      let event_count =
        match s.events with Some e -> List.length e | None -> 0
      in
      let tag_count = match s.tags with Some t -> List.length t | None -> 0 in
      Printf.sprintf "%d events, %d tags" event_count tag_count);

  (* ===== Summary ===== *)
  Logger.header "Summary";
  Logger.info "COMPLETE" [ ("status", "all endpoints exercised") ];
  Logger.info "NOTE"
    [
      ("message", "Endpoints that returned SKIP had no valid IDs to test with");
    ]

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
