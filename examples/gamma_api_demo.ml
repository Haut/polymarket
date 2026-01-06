(** Live demo of the Polymarket Gamma API client.

    This example calls all Gamma API endpoints and prints the results. Run with:
    dune exec examples/gamma_api_demo.exe

    The demo fetches popular events/markets by volume to ensure meaningful data.
*)

open Polymarket

(** {1 Helper Functions} *)

let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name (Gamma.error_to_string err)

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name (Gamma.error_to_string err)

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let clock = Eio.Stdenv.clock env in

  Logger.info
    (Printf.sprintf "Starting Gamma API demo (%s)" Gamma.default_base_url);

  (* Create shared rate limiter with Polymarket presets *)
  let routes =
    match Rate_limit_presets.all ~behavior:Rate_limiter.Delay with
    | Ok r -> r
    | Error msg -> failwith ("Rate limit preset error: " ^ msg)
  in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in
  let client =
    match Gamma.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter () with
    | Ok c -> c
    | Error e -> failwith ("Gamma client error: " ^ Gamma.string_of_init_error e)
  in

  (* ===== Health Check ===== *)
  let status = Gamma.status client in
  print_result "status" status ~on_ok:(fun s -> s);

  (* ===== Events (sorted by volume to get popular ones) ===== *)
  let events =
    Gamma.get_events client ~limit:10 ~active:true ~order:[ "volume" ]
      ~ascending:false ()
  in
  print_result_count "get_events" events;

  let event_info =
    match events with Ok (e :: _) -> Some (e.id, e.slug) | _ -> None
  in

  (match event_info with
  | Some (id, slug) -> (
      let event = Gamma.get_event client ~id () in
      print_result "get_event" event ~on_ok:(fun (e : Gamma.event) ->
          Option.value ~default:"(no title)" e.title);

      let event_tags = Gamma.get_event_tags client ~id () in
      print_result_count "get_event_tags" event_tags;

      match slug with
      | Some s ->
          let event = Gamma.get_event_by_slug client ~slug:s () in
          print_result "get_event_by_slug" event
            ~on_ok:(fun (e : Gamma.event) ->
              Option.value ~default:"(no title)" e.title)
      | None -> Logger.skip "get_event_by_slug" "no event slug available")
  | None ->
      Logger.skip "get_event" "no event available";
      Logger.skip "get_event_tags" "no event available";
      Logger.skip "get_event_by_slug" "no event available");

  (* ===== Markets (sorted by volume) ===== *)
  let markets =
    Gamma.get_markets client ~limit:10 ~closed:false ~order:"volume"
      ~ascending:false ()
  in
  print_result_count "get_markets" markets;

  let market_info =
    match markets with Ok (m :: _) -> Some (m.id, m.slug) | _ -> None
  in

  (match market_info with
  | Some (id, slug) -> (
      let market = Gamma.get_market client ~id () in
      print_result "get_market" market ~on_ok:(fun (m : Gamma.market) ->
          Option.value ~default:"(no question)" m.question);

      let market_tags = Gamma.get_market_tags client ~id () in
      print_result_count "get_market_tags" market_tags;

      match slug with
      | Some s ->
          let market = Gamma.get_market_by_slug client ~slug:s () in
          print_result "get_market_by_slug" market
            ~on_ok:(fun (m : Gamma.market) ->
              Option.value ~default:"(no question)" m.question)
      | None -> Logger.skip "get_market_by_slug" "no market slug available")
  | None ->
      Logger.skip "get_market" "no market available";
      Logger.skip "get_market_tags" "no market available";
      Logger.skip "get_market_by_slug" "no market available");

  (* ===== Tags (use tags from a popular event) ===== *)
  let tag_info =
    match event_info with
    | Some (id, _) -> (
        match Gamma.get_event_tags client ~id () with
        | Ok (t :: _) -> (
            match t.slug with Some slug -> Some (t.id, slug) | None -> None)
        | _ -> None)
    | None -> None
  in

  let tags = Gamma.get_tags client ~limit:20 () in
  print_result_count "get_tags" tags;

  (* Fall back to first tag if event has no tags *)
  let tag_info =
    match tag_info with
    | Some _ -> tag_info
    | None -> (
        match tags with
        | Ok (t :: _) -> (
            match t.slug with Some slug -> Some (t.id, slug) | None -> None)
        | _ -> None)
  in

  (match tag_info with
  | Some (id, slug) ->
      let tag = Gamma.get_tag client ~id () in
      print_result "get_tag" tag ~on_ok:(fun (t : Gamma.tag) ->
          Option.value ~default:"(no label)" t.label);

      let tag_by_slug = Gamma.get_tag_by_slug client ~slug () in
      print_result "get_tag_by_slug" tag_by_slug ~on_ok:(fun (t : Gamma.tag) ->
          Option.value ~default:"(no label)" t.label);

      let related = Gamma.get_related_tags client ~id () in
      print_result_count "get_related_tags" related;

      let related_by_slug = Gamma.get_related_tags_by_slug client ~slug () in
      print_result_count "get_related_tags_by_slug" related_by_slug;

      let related_objs = Gamma.get_related_tag_tags client ~id () in
      print_result_count "get_related_tag_tags" related_objs;

      let related_objs_by_slug =
        Gamma.get_related_tag_tags_by_slug client ~slug ()
      in
      print_result_count "get_related_tag_tags_by_slug" related_objs_by_slug
  | None ->
      Logger.skip "get_tag" "no tag available";
      Logger.skip "get_tag_by_slug" "no tag available";
      Logger.skip "get_related_tags" "no tag available";
      Logger.skip "get_related_tags_by_slug" "no tag available";
      Logger.skip "get_related_tag_tags" "no tag available";
      Logger.skip "get_related_tag_tags_by_slug" "no tag available");

  (* ===== Series ===== *)
  let series_list = Gamma.get_series_list client ~limit:10 () in
  print_result_count "get_series_list" series_list;

  (match series_list with
  | Ok (s :: _) ->
      let series = Gamma.get_series client ~id:s.id () in
      print_result "get_series" series ~on_ok:(fun (s : Gamma.series) ->
          Option.value ~default:"(no title)" s.title)
  | _ -> Logger.skip "get_series" "no series available");

  (* ===== Comments (from popular event with comments) ===== *)
  let event_with_comments =
    match events with
    | Ok evs ->
        List.find_map
          (fun (e : Gamma.event) ->
            match (e.comment_count, int_of_string_opt e.id) with
            | Some count, Some eid when count > 0 -> Some eid
            | _ -> None)
          evs
    | Error _ -> None
  in

  (match event_with_comments with
  | Some event_id -> (
      let comments =
        Gamma.get_comments client
          ~parent_entity_type:Gamma.Parent_entity_type.Event
          ~parent_entity_id:event_id ~limit:10 ()
      in
      print_result_count "get_comments" comments;

      match comments with
      | Ok (c :: _) -> (
          (match Gamma.get_comment client ~id:c.id () with
          | Ok (Some comment) ->
              let body = Option.value ~default:"(no body)" comment.body in
              let truncated =
                if String.length body > 50 then String.sub body 0 50 ^ "..."
                else body
              in
              Logger.ok "get_comment" truncated
          | Ok None -> Logger.skip "get_comment" "comment not found"
          | Error err -> Logger.error "get_comment" (Gamma.error_to_string err));

          match c.user_address with
          | Some addr ->
              let user_comments =
                Gamma.get_user_comments client ~user_address:addr ~limit:5 ()
              in
              print_result_count "get_user_comments" user_comments
          | None -> Logger.skip "get_user_comments" "no user address on comment"
          )
      | _ ->
          Logger.skip "get_comment" "event has no comments";
          Logger.skip "get_user_comments" "no comments available")
  | None ->
      Logger.skip "get_comments" "no event with comments found";
      Logger.skip "get_comment" "no event with comments found";
      Logger.skip "get_user_comments" "no event with comments found");

  (* ===== Profiles ===== *)
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
  let search = Gamma.public_search client ~q:"trump" ~limit_per_type:5 () in
  print_result "public_search" search ~on_ok:(fun (s : Gamma.search) ->
      let event_count =
        match s.events with Some e -> List.length e | None -> 0
      in
      let tag_count = match s.tags with Some t -> List.length t | None -> 0 in
      Printf.sprintf "%d events, %d tags" event_count tag_count);

  (* ===== Summary ===== *)
  Logger.info "All endpoints exercised"

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
