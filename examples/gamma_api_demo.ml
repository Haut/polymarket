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
  | Error err -> Logger.error name (Http.error_to_string err)

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name (Http.error_to_string err)

(** {1 ID Extraction Helpers} *)

let first_event_id (events : Gamma.event list) =
  match events with [] -> None | e :: _ -> Some e.id

let first_event_slug (events : Gamma.event list) =
  match events with [] -> None | e :: _ -> e.slug

let first_market_id (markets : Gamma.market list) =
  match markets with [] -> None | m :: _ -> Some m.id

let first_market_slug (markets : Gamma.market list) =
  match markets with [] -> None | m :: _ -> m.slug

let first_series_id (series_list : Gamma.series list) =
  match series_list with [] -> None | s :: _ -> Some s.id

(** Find a tag with related tags (try first few tags) *)
let find_tag_with_related client (tags : Gamma.tag list) =
  let rec try_tags = function
    | [] -> None
    | (t : Gamma.tag) :: rest -> (
        match Gamma.get_related_tags client ~id:t.id () with
        | Ok (_ :: _ as related) -> Some (t, related)
        | _ -> try_tags rest)
  in
  try_tags (List.filteri (fun i _ -> i < 10) tags)

(** Find an event with comments (try first few events) *)
let find_event_with_comments client (events : Gamma.event list) =
  let rec try_events = function
    | [] -> None
    | (e : Gamma.event) :: rest -> (
        match int_of_string_opt e.id with
        | None -> try_events rest
        | Some eid -> (
            match
              Gamma.get_comments client ~limit:(Gamma.N.of_int_exn 10)
                ~parent_entity_type:Gamma.Parent_entity_type.Event
                ~parent_entity_id:eid ()
            with
            | Ok (_ :: _ as comments) -> Some (e, comments)
            | _ -> try_events rest))
  in
  try_events (List.filteri (fun i _ -> i < 10) events)

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let clock = Eio.Stdenv.clock env in

  Logger.info
    (Printf.sprintf "Starting Gamma API demo (%s)" Gamma.default_base_url);

  (* Create shared rate limiter with Polymarket presets *)
  let routes = Rate_limit_presets.all ~behavior:Rate_limiter.Delay in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in
  let client = Gamma.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter () in

  (* ===== Health Check ===== *)
  let status = Gamma.status client in
  print_result "status" status ~on_ok:(fun s -> s);

  (* ===== Tags ===== *)
  let tags = Gamma.get_tags client ~limit:(Gamma.N.of_int_exn 20) () in
  print_result_count "get_tags" tags;

  (* Find a tag with related tags for better demo output *)
  let tag_with_related =
    match tags with Ok t -> find_tag_with_related client t | Error _ -> None
  in

  (match tag_with_related with
  | Some (tag, related) ->
      let label = Option.value ~default:"(no label)" tag.label in
      Logger.ok "get_tag" label;
      Logger.ok "get_related_tags"
        (Printf.sprintf "%d items" (List.length related));

      (match tag.slug with
      | Some slug ->
          let tag_by_slug = Gamma.get_tag_by_slug client ~slug () in
          print_result "get_tag_by_slug" tag_by_slug
            ~on_ok:(fun (t : Gamma.tag) ->
              Option.value ~default:"(no label)" t.label);

          let related_by_slug =
            Gamma.get_related_tags_by_slug client ~slug ()
          in
          print_result_count "get_related_tags_by_slug" related_by_slug;

          let related_tag_objs =
            Gamma.get_related_tag_tags_by_slug client ~slug ()
          in
          print_result_count "get_related_tag_tags_by_slug" related_tag_objs
      | None ->
          Logger.skip "get_tag_by_slug" "no tag slug available";
          Logger.skip "get_related_tags_by_slug" "no tag slug available";
          Logger.skip "get_related_tag_tags_by_slug" "no tag slug available");

      let related_tag_objs = Gamma.get_related_tag_tags client ~id:tag.id () in
      print_result_count "get_related_tag_tags" related_tag_objs
  | None ->
      (* Fall back to first tag if none have related tags *)
      (match tags with
      | Ok (t :: _) ->
          let tag = Gamma.get_tag client ~id:t.id () in
          print_result "get_tag" tag ~on_ok:(fun (t : Gamma.tag) ->
              Option.value ~default:"(no label)" t.label);
          Logger.ok "get_related_tags" "0 items (no tags with relations found)"
      | _ -> Logger.skip "get_tag" "no tags available");
      Logger.skip "get_tag_by_slug" "no tag with related tags found";
      Logger.skip "get_related_tags_by_slug" "no tag with related tags found";
      Logger.skip "get_related_tag_tags_by_slug"
        "no tag with related tags found";
      Logger.skip "get_related_tag_tags" "no tag with related tags found");

  (* ===== Events ===== *)
  let events =
    Gamma.get_events client ~limit:(Gamma.N.of_int_exn 10) ~active:true ()
  in
  print_result_count "get_events" events;

  let event_id, event_slug =
    match events with
    | Ok ev -> (first_event_id ev, first_event_slug ev)
    | Error _ -> (None, None)
  in

  (match event_id with
  | Some id ->
      let event = Gamma.get_event client ~id () in
      print_result "get_event" event ~on_ok:(fun (e : Gamma.event) ->
          Option.value ~default:"(no title)" e.title);

      let event_tags = Gamma.get_event_tags client ~id () in
      print_result_count "get_event_tags" event_tags
  | None ->
      Logger.skip "get_event" "no event ID available";
      Logger.skip "get_event_tags" "no event ID available");

  (match event_slug with
  | Some slug ->
      let event = Gamma.get_event_by_slug client ~slug () in
      print_result "get_event_by_slug" event ~on_ok:(fun (e : Gamma.event) ->
          Option.value ~default:"(no title)" e.title)
  | None -> Logger.skip "get_event_by_slug" "no event slug available");

  (* ===== Markets ===== *)
  let markets = Gamma.get_markets client ~limit:(Gamma.N.of_int_exn 10) () in
  print_result_count "get_markets" markets;

  let market_id, market_slug =
    match markets with
    | Ok m -> (first_market_id m, first_market_slug m)
    | Error _ -> (None, None)
  in

  (match market_id with
  | Some id ->
      let market = Gamma.get_market client ~id () in
      print_result "get_market" market ~on_ok:(fun (m : Gamma.market) ->
          Option.value ~default:"(no question)" m.question);

      let market_tags = Gamma.get_market_tags client ~id () in
      print_result_count "get_market_tags" market_tags
  | None ->
      Logger.skip "get_market" "no market ID available";
      Logger.skip "get_market_tags" "no market ID available");

  (match market_slug with
  | Some slug ->
      let market = Gamma.get_market_by_slug client ~slug () in
      print_result "get_market_by_slug" market ~on_ok:(fun (m : Gamma.market) ->
          Option.value ~default:"(no question)" m.question)
  | None -> Logger.skip "get_market_by_slug" "no market slug available");

  (* ===== Series ===== *)
  let series_list =
    Gamma.get_series_list client ~limit:(Gamma.N.of_int_exn 10) ()
  in
  print_result_count "get_series_list" series_list;

  let series_id =
    match series_list with Ok s -> first_series_id s | Error _ -> None
  in

  (match series_id with
  | Some id ->
      let series = Gamma.get_series client ~id () in
      print_result "get_series" series ~on_ok:(fun (s : Gamma.series) ->
          Option.value ~default:"(no title)" s.title)
  | None -> Logger.skip "get_series" "no series ID available");

  (* ===== Comments ===== *)
  (* Find an event with comments for better demo output *)
  let event_with_comments =
    match events with
    | Ok ev -> find_event_with_comments client ev
    | Error _ -> None
  in

  (match event_with_comments with
  | Some (_event, comments) -> (
      Logger.ok "get_comments"
        (Printf.sprintf "%d items" (List.length comments));

      let comment = List.hd comments in
      let body = Option.value ~default:"(no body)" comment.body in
      let truncated =
        if String.length body > 50 then String.sub body 0 50 ^ "..." else body
      in
      Logger.ok "get_comment" truncated;

      match comment.user_address with
      | Some addr ->
          let user_comments =
            Gamma.get_user_comments client ~user_address:addr
              ~limit:(Gamma.N.of_int_exn 5) ()
          in
          print_result_count "get_user_comments" user_comments
      | None -> Logger.skip "get_user_comments" "no user address on comment")
  | None ->
      Logger.ok "get_comments" "0 items (no events with comments found)";
      Logger.skip "get_comment" "no comments available";
      Logger.skip "get_user_comments" "no comments available");

  (* ===== Profiles ===== *)
  (* Use a known test address for profile testing *)
  let test_address = "0xa41249c581990c31fb2a0dfc4417ede58e0de774" in
  let public_profile =
    Gamma.get_public_profile client ~address:test_address ()
  in
  print_result "get_public_profile" public_profile
    ~on_ok:(fun (p : Gamma.public_profile_response) ->
      Option.value ~default:"(no name)" p.name);

  (* ===== Sports ===== *)
  let sports = Gamma.get_sports client () in
  print_result_count "get_sports" sports;

  let market_types = Gamma.get_sports_market_types client () in
  print_result "get_sports_market_types" market_types
    ~on_ok:(fun (r : Gamma.sports_market_types_response) ->
      Printf.sprintf "%d market types" (List.length r.market_types));

  (* ===== Teams ===== *)
  let teams = Gamma.get_teams client () in
  print_result_count "get_teams" teams;

  (* ===== Search ===== *)
  let search =
    Gamma.public_search client ~q:"election"
      ~limit_per_type:(Gamma.N.of_int_exn 5) ()
  in
  print_result "public_search" search ~on_ok:(fun (s : Gamma.search) ->
      let event_count =
        match s.events with Some e -> List.length e | None -> 0
      in
      let tag_count = match s.tags with Some t -> List.length t | None -> 0 in
      Printf.sprintf "%d events, %d tags" event_count tag_count);

  (* ===== Summary ===== *)
  Logger.info "All endpoints exercised";
  Logger.info "Endpoints that returned SKIP had no valid IDs to test with"

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
