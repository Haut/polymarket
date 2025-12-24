(** Unit tests for Gamma_api.Types module *)

open Polymarket.Gamma_api.Types

let float_testable = Alcotest.float 0.0001
let option_float = Alcotest.option float_testable
let option_int = Alcotest.option Alcotest.int
let option_bool = Alcotest.option Alcotest.bool

(** {1 Pagination Tests} *)

let test_pagination_empty () =
  let p = empty_pagination in
  Alcotest.(check (option bool)) "has_more is None" None p.has_more;
  Alcotest.(check option_int) "total_results is None" None p.total_results

let test_pagination_roundtrip () =
  let p = { has_more = Some true; total_results = Some 100 } in
  let json = yojson_of_pagination p in
  let result = pagination_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_pagination p result)

let test_pagination_partial_json () =
  let json = Yojson.Safe.from_string {|{"hasMore": true}|} in
  let result = pagination_of_yojson json in
  Alcotest.(check option_bool) "has_more" (Some true) result.has_more;
  Alcotest.(check option_int) "total_results" None result.total_results

(** {1 Count Tests} *)

let test_count_empty () =
  let c = empty_count in
  Alcotest.(check option_int) "count is None" None c.count

let test_count_roundtrip () =
  let c = { count = Some 42 } in
  let json = yojson_of_count c in
  let result = count_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_count c result)

(** {1 Event Tweet Count Tests} *)

let test_event_tweet_count_empty () =
  let etc = empty_event_tweet_count in
  Alcotest.(check option_int) "tweet_count is None" None etc.tweet_count

let test_event_tweet_count_roundtrip () =
  let etc = { tweet_count = Some 500 } in
  let json = yojson_of_event_tweet_count etc in
  let result = event_tweet_count_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_event_tweet_count etc result)

(** {1 Market Description Tests} *)

let test_market_description_empty () =
  let md = empty_market_description in
  Alcotest.(check (option string)) "description is None" None md.description

let test_market_description_roundtrip () =
  let md =
    {
      empty_market_description with
      description = Some "Test market description";
    }
  in
  let json = yojson_of_market_description md in
  let result = market_description_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_market_description md result)

(** {1 Image Optimization Tests} *)

let test_image_optimization_empty () =
  let io = empty_image_optimization in
  Alcotest.(check (option string)) "id is None" None io.id;
  Alcotest.(check (option string))
    "image_url_source is None" None io.image_url_source

let test_image_optimization_roundtrip () =
  let io =
    {
      empty_image_optimization with
      id = Some "img_123";
      image_url_source = Some "https://example.com/source.png";
      image_url_optimized = Some "https://example.com/optimized.png";
      image_size_kb_source = Some 1024.5;
      image_optimized_complete = Some true;
    }
  in
  let json = yojson_of_image_optimization io in
  let result = image_optimization_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_image_optimization io result)

(** {1 Team Tests} *)

let test_team_empty () =
  let t = empty_team in
  Alcotest.(check option_int) "id is None" None t.id;
  Alcotest.(check (option string)) "name is None" None t.name

let test_team_roundtrip () =
  let t =
    {
      empty_team with
      id = Some 1;
      name = Some "Lakers";
      league = Some "NBA";
      abbreviation = Some "LAL";
    }
  in
  let json = yojson_of_team t in
  let result = team_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_team t result)

(** {1 Tag Tests} *)

let test_tag_empty () =
  let t = empty_tag in
  Alcotest.(check (option string)) "id is None" None t.id;
  Alcotest.(check (option string)) "label is None" None t.label

let test_tag_roundtrip () =
  let t =
    {
      empty_tag with
      id = Some "tag_123";
      label = Some "Politics";
      slug = Some "politics";
      force_show = Some true;
      is_carousel = Some false;
    }
  in
  let json = yojson_of_tag t in
  let result = tag_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_tag t result)

(** {1 Related Tag Tests} *)

let test_related_tag_empty () =
  let rt = empty_related_tag in
  Alcotest.(check (option string)) "id is None" None rt.id;
  Alcotest.(check option_int) "rank is None" None rt.rank

let test_related_tag_roundtrip () =
  let rt =
    { id = Some "1"; tag_id = Some 10; related_tag_id = Some 20; rank = Some 1 }
  in
  let json = yojson_of_related_tag rt in
  let result = related_tag_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_related_tag rt result)

(** {1 Category Tests} *)

let test_category_empty () =
  let c = empty_category in
  Alcotest.(check (option string)) "id is None" None c.id;
  Alcotest.(check (option string)) "label is None" None c.label

let test_category_roundtrip () =
  let c =
    {
      empty_category with
      id = Some "cat_1";
      label = Some "Sports";
      slug = Some "sports";
      parent_category = Some "main";
    }
  in
  let json = yojson_of_category c in
  let result = category_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_category c result)

(** {1 Event Creator Tests} *)

let test_event_creator_empty () =
  let ec = empty_event_creator in
  Alcotest.(check (option string)) "id is None" None ec.id;
  Alcotest.(check (option string)) "creator_name is None" None ec.creator_name

let test_event_creator_roundtrip () =
  let ec =
    {
      empty_event_creator with
      id = Some "creator_1";
      creator_name = Some "John Doe";
      creator_handle = Some "@johndoe";
      creator_url = Some "https://twitter.com/johndoe";
    }
  in
  let json = yojson_of_event_creator ec in
  let result = event_creator_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_event_creator ec result)

(** {1 Chat Tests} *)

let test_chat_empty () =
  let c = empty_chat in
  Alcotest.(check (option string)) "id is None" None c.id;
  Alcotest.(check option_bool) "live is None" None c.live

let test_chat_roundtrip () =
  let c =
    {
      empty_chat with
      id = Some "chat_1";
      channel_id = Some "channel_123";
      channel_name = Some "General";
      live = Some true;
    }
  in
  let json = yojson_of_chat c in
  let result = chat_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_chat c result)

(** {1 Template Tests} *)

let test_template_empty () =
  let t = empty_template in
  Alcotest.(check (option string)) "id is None" None t.id;
  Alcotest.(check (option string)) "event_title is None" None t.event_title

let test_template_roundtrip () =
  let t =
    {
      empty_template with
      id = Some "tpl_1";
      event_title = Some "Test Event";
      market_title = Some "Test Market";
      neg_risk = Some false;
    }
  in
  let json = yojson_of_template t in
  let result = template_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_template t result)

(** {1 Search Tag Tests} *)

let test_search_tag_empty () =
  let st = empty_search_tag in
  Alcotest.(check (option string)) "id is None" None st.id;
  Alcotest.(check option_int) "event_count is None" None st.event_count

let test_search_tag_roundtrip () =
  let st =
    {
      id = Some "st_1";
      label = Some "Politics";
      slug = Some "politics";
      event_count = Some 50;
    }
  in
  let json = yojson_of_search_tag st in
  let result = search_tag_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_search_tag st result)

(** {1 Comment Position Tests} *)

let test_comment_position_empty () =
  let cp = empty_comment_position in
  Alcotest.(check (option string)) "token_id is None" None cp.token_id

let test_comment_position_roundtrip () =
  let cp = { token_id = Some "token_123"; position_size = Some "100.5" } in
  let json = yojson_of_comment_position cp in
  let result = comment_position_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_comment_position cp result)

(** {1 Comment Profile Tests} *)

let test_comment_profile_empty () =
  let cp = empty_comment_profile in
  Alcotest.(check (option string)) "name is None" None cp.name;
  Alcotest.(
    check
      (list
         (module struct
           type t = comment_position

           let equal = equal_comment_position
           let pp = pp_comment_position
         end)))
    "positions is empty" [] cp.positions

let test_comment_profile_roundtrip () =
  let cp =
    {
      empty_comment_profile with
      name = Some "Test User";
      pseudonym = Some "testuser";
      is_mod = Some true;
      bio = Some "Test bio";
    }
  in
  let json = yojson_of_comment_profile cp in
  let result = comment_profile_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_comment_profile cp result)

(** {1 Reaction Tests} *)

let test_reaction_empty () =
  let r = empty_reaction in
  Alcotest.(check (option string)) "id is None" None r.id;
  Alcotest.(check (option string)) "reaction_type is None" None r.reaction_type

let test_reaction_roundtrip () =
  let r =
    {
      empty_reaction with
      id = Some "r_1";
      comment_id = Some 42;
      reaction_type = Some "like";
      icon = Some "👍";
    }
  in
  let json = yojson_of_reaction r in
  let result = reaction_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_reaction r result)

(** {1 Comment Tests} *)

let test_comment_empty () =
  let c = empty_comment in
  Alcotest.(check (option string)) "id is None" None c.id;
  Alcotest.(check (option string)) "body is None" None c.body

let test_comment_roundtrip () =
  let c =
    {
      empty_comment with
      id = Some "comment_1";
      body = Some "This is a test comment";
      parent_entity_type = Some "Event";
      parent_entity_id = Some 123;
      reaction_count = Some 5;
    }
  in
  let json = yojson_of_comment c in
  let result = comment_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_comment c result)

(** {1 Public Profile User Tests} *)

let test_public_profile_user_empty () =
  let ppu = empty_public_profile_user in
  Alcotest.(check (option string)) "id is None" None ppu.id;
  Alcotest.(check option_bool) "creator is None" None ppu.creator

let test_public_profile_user_roundtrip () =
  let ppu = { id = Some "user_1"; creator = Some true; mod_ = Some false } in
  let json = yojson_of_public_profile_user ppu in
  let result = public_profile_user_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_public_profile_user ppu result)

(** {1 Public Profile Error Tests} *)

let test_public_profile_error_empty () =
  let ppe = empty_public_profile_error in
  Alcotest.(check (option string)) "type_ is None" None ppe.type_;
  Alcotest.(check (option string)) "error is None" None ppe.error

let test_public_profile_error_roundtrip () =
  let ppe = { type_ = Some "not_found"; error = Some "User not found" } in
  let json = yojson_of_public_profile_error ppe in
  let result = public_profile_error_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_public_profile_error ppe result)

(** {1 Public Profile Response Tests} *)

let test_public_profile_response_empty () =
  let ppr = empty_public_profile_response in
  Alcotest.(check (option string)) "name is None" None ppr.name;
  Alcotest.(check (option string)) "pseudonym is None" None ppr.pseudonym

let test_public_profile_response_roundtrip () =
  let ppr =
    {
      empty_public_profile_response with
      name = Some "Test User";
      pseudonym = Some "testuser";
      bio = Some "Test bio";
      verified_badge = Some true;
      proxy_wallet = Some "0x1234";
    }
  in
  let json = yojson_of_public_profile_response ppr in
  let result = public_profile_response_of_yojson json in
  Alcotest.(check bool)
    "roundtrip" true
    (equal_public_profile_response ppr result)

(** {1 Profile Tests} *)

let test_profile_empty () =
  let p = empty_profile in
  Alcotest.(check (option string)) "id is None" None p.id;
  Alcotest.(check (option string)) "name is None" None p.name

let test_profile_roundtrip () =
  let p =
    {
      empty_profile with
      id = Some "profile_1";
      name = Some "Test User";
      pseudonym = Some "testuser";
      wallet_activated = Some true;
      is_close_only = Some false;
    }
  in
  let json = yojson_of_profile p in
  let result = profile_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_profile p result)

(** {1 Collection Tests} *)

let test_collection_empty () =
  let c = empty_collection in
  Alcotest.(check (option string)) "id is None" None c.id;
  Alcotest.(check (option string)) "title is None" None c.title

let test_collection_roundtrip () =
  let c =
    {
      empty_collection with
      id = Some "col_1";
      title = Some "Test Collection";
      slug = Some "test-collection";
      active = Some true;
      featured = Some false;
    }
  in
  let json = yojson_of_collection c in
  let result = collection_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_collection c result)

(** {1 Series Summary Tests} *)

let test_series_summary_empty () =
  let ss = empty_series_summary in
  Alcotest.(check (option string)) "id is None" None ss.id;
  Alcotest.(check (list string)) "event_dates is empty" [] ss.event_dates

let test_series_summary_roundtrip () =
  let ss =
    {
      id = Some "ss_1";
      title = Some "Test Series";
      slug = Some "test-series";
      event_dates = [ "2024-01-01"; "2024-01-08" ];
      event_weeks = [ 1; 2 ];
      earliest_open_week = Some 1;
      earliest_open_date = Some "2024-01-01";
    }
  in
  let json = yojson_of_series_summary ss in
  let result = series_summary_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_series_summary ss result)

(** {1 Market Tests} *)

let test_market_empty () =
  let m = empty_market in
  Alcotest.(check (option string)) "id is None" None m.id;
  Alcotest.(check (option string)) "question is None" None m.question;
  Alcotest.(check option_bool) "active is None" None m.active

let test_market_roundtrip () =
  let m =
    {
      empty_market with
      id = Some "market_1";
      question = Some "Will it rain tomorrow?";
      slug = Some "will-it-rain";
      active = Some true;
      closed = Some false;
      volume_num = Some 10000.0;
      liquidity_num = Some 5000.0;
    }
  in
  let json = yojson_of_market m in
  let result = market_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_market m result)

let test_market_partial_json () =
  let json =
    Yojson.Safe.from_string
      {|{"id": "123", "question": "Test?", "active": true, "volumeNum": 100.5}|}
  in
  let result = market_of_yojson json in
  Alcotest.(check (option string)) "id" (Some "123") result.id;
  Alcotest.(check (option string)) "question" (Some "Test?") result.question;
  Alcotest.(check option_bool) "active" (Some true) result.active;
  Alcotest.(check option_float) "volume_num" (Some 100.5) result.volume_num;
  Alcotest.(check (option string)) "slug is None" None result.slug

(** {1 Event Tests} *)

let test_event_empty () =
  let e = empty_event in
  Alcotest.(check (option string)) "id is None" None e.id;
  Alcotest.(check (option string)) "title is None" None e.title;
  Alcotest.(check option_bool) "active is None" None e.active

let test_event_roundtrip () =
  let e =
    {
      empty_event with
      id = Some "event_1";
      title = Some "US Election 2024";
      slug = Some "us-election-2024";
      active = Some true;
      volume = Some 1000000.0;
      liquidity = Some 500000.0;
      neg_risk = Some true;
    }
  in
  let json = yojson_of_event e in
  let result = event_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_event e result)

let test_event_partial_json () =
  let json =
    Yojson.Safe.from_string
      {|{"id": "456", "title": "Test Event", "active": false, "volume": 5000.0}|}
  in
  let result = event_of_yojson json in
  Alcotest.(check (option string)) "id" (Some "456") result.id;
  Alcotest.(check (option string)) "title" (Some "Test Event") result.title;
  Alcotest.(check option_bool) "active" (Some false) result.active;
  Alcotest.(check option_float) "volume" (Some 5000.0) result.volume

(** {1 Series Tests} *)

let test_series_empty () =
  let s = empty_series in
  Alcotest.(check (option string)) "id is None" None s.id;
  Alcotest.(check (option string)) "title is None" None s.title;
  Alcotest.(check option_bool) "active is None" None s.active

let test_series_roundtrip () =
  let s =
    {
      empty_series with
      id = Some "series_1";
      title = Some "NFL 2024";
      slug = Some "nfl-2024";
      series_type = Some "sports";
      active = Some true;
      volume = Some 2000000.0;
    }
  in
  let json = yojson_of_series s in
  let result = series_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_series s result)

(** {1 Events Pagination Tests} *)

let test_events_pagination_empty () =
  let ep = empty_events_pagination in
  Alcotest.(
    check
      (list
         (module struct
           type t = event

           let equal = equal_event
           let pp = pp_event
         end)))
    "data is empty" [] ep.data

let test_events_pagination_roundtrip () =
  let ep =
    {
      data = [ { empty_event with id = Some "e1"; title = Some "Event 1" } ];
      pagination = Some { has_more = Some true; total_results = Some 100 };
    }
  in
  let json = yojson_of_events_pagination ep in
  let result = events_pagination_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_events_pagination ep result)

(** {1 Search Tests} *)

let test_search_empty () =
  let s = empty_search in
  Alcotest.(check bool) "events is None" true (Option.is_none s.events);
  Alcotest.(check bool) "tags is None" true (Option.is_none s.tags)

let test_search_roundtrip () =
  let s =
    {
      events = Some [ { empty_event with id = Some "e1" } ];
      tags =
        Some
          [
            {
              id = Some "t1";
              label = Some "Tag";
              slug = Some "tag";
              event_count = Some 10;
            };
          ];
      profiles = None;
      pagination = Some { has_more = Some false; total_results = Some 1 };
    }
  in
  let json = yojson_of_search s in
  let result = search_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_search s result)

(** {1 Sports Metadata Tests} *)

let test_sports_metadata_empty () =
  let sm = empty_sports_metadata in
  Alcotest.(check (option string)) "sport is None" None sm.sport

let test_sports_metadata_roundtrip () =
  let sm =
    {
      id = Some 1;
      sport = Some "football";
      image = Some "https://example.com/football.png";
      resolution = Some "manual";
      ordering = Some "alphabetical";
      tags = Some "nfl,ncaa";
      series = Some "nfl-2024";
      created_at = Some "2024-01-01T00:00:00Z";
    }
  in
  let json = yojson_of_sports_metadata sm in
  let result = sports_metadata_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_sports_metadata sm result)

(** {1 Sports Market Types Response Tests} *)

let test_sports_market_types_response_empty () =
  let smtr = empty_sports_market_types_response in
  Alcotest.(check (list string)) "market_types is empty" [] smtr.market_types

let test_sports_market_types_response_roundtrip () =
  let smtr = { market_types = [ "moneyline"; "spread"; "total" ] } in
  let json = yojson_of_sports_market_types_response smtr in
  let result = sports_market_types_response_of_yojson json in
  Alcotest.(check bool)
    "roundtrip" true
    (equal_sports_market_types_response smtr result)

(** {1 Markets Information Body Tests} *)

let test_markets_information_body_empty () =
  let mib = empty_markets_information_body in
  Alcotest.(check bool) "id is None" true (Option.is_none mib.id);
  Alcotest.(check option_float)
    "liquidity_num_min is None" None mib.liquidity_num_min

let test_markets_information_body_roundtrip () =
  let mib =
    {
      empty_markets_information_body with
      id = Some [ 1; 2; 3 ];
      slug = Some [ "market-1"; "market-2" ];
      closed = Some false;
      liquidity_num_min = Some 1000.0;
      volume_num_max = Some 100000.0;
    }
  in
  let json = yojson_of_markets_information_body mib in
  let result = markets_information_body_of_yojson json in
  Alcotest.(check bool)
    "roundtrip" true
    (equal_markets_information_body mib result)

(** {1 Test Suite} *)

let tests =
  [
    ( "pagination",
      [
        ("empty", `Quick, test_pagination_empty);
        ("roundtrip", `Quick, test_pagination_roundtrip);
        ("partial json", `Quick, test_pagination_partial_json);
      ] );
    ( "count",
      [
        ("empty", `Quick, test_count_empty);
        ("roundtrip", `Quick, test_count_roundtrip);
      ] );
    ( "event_tweet_count",
      [
        ("empty", `Quick, test_event_tweet_count_empty);
        ("roundtrip", `Quick, test_event_tweet_count_roundtrip);
      ] );
    ( "market_description",
      [
        ("empty", `Quick, test_market_description_empty);
        ("roundtrip", `Quick, test_market_description_roundtrip);
      ] );
    ( "image_optimization",
      [
        ("empty", `Quick, test_image_optimization_empty);
        ("roundtrip", `Quick, test_image_optimization_roundtrip);
      ] );
    ( "team",
      [
        ("empty", `Quick, test_team_empty);
        ("roundtrip", `Quick, test_team_roundtrip);
      ] );
    ( "tag",
      [
        ("empty", `Quick, test_tag_empty);
        ("roundtrip", `Quick, test_tag_roundtrip);
      ] );
    ( "related_tag",
      [
        ("empty", `Quick, test_related_tag_empty);
        ("roundtrip", `Quick, test_related_tag_roundtrip);
      ] );
    ( "category",
      [
        ("empty", `Quick, test_category_empty);
        ("roundtrip", `Quick, test_category_roundtrip);
      ] );
    ( "event_creator",
      [
        ("empty", `Quick, test_event_creator_empty);
        ("roundtrip", `Quick, test_event_creator_roundtrip);
      ] );
    ( "chat",
      [
        ("empty", `Quick, test_chat_empty);
        ("roundtrip", `Quick, test_chat_roundtrip);
      ] );
    ( "template",
      [
        ("empty", `Quick, test_template_empty);
        ("roundtrip", `Quick, test_template_roundtrip);
      ] );
    ( "search_tag",
      [
        ("empty", `Quick, test_search_tag_empty);
        ("roundtrip", `Quick, test_search_tag_roundtrip);
      ] );
    ( "comment_position",
      [
        ("empty", `Quick, test_comment_position_empty);
        ("roundtrip", `Quick, test_comment_position_roundtrip);
      ] );
    ( "comment_profile",
      [
        ("empty", `Quick, test_comment_profile_empty);
        ("roundtrip", `Quick, test_comment_profile_roundtrip);
      ] );
    ( "reaction",
      [
        ("empty", `Quick, test_reaction_empty);
        ("roundtrip", `Quick, test_reaction_roundtrip);
      ] );
    ( "comment",
      [
        ("empty", `Quick, test_comment_empty);
        ("roundtrip", `Quick, test_comment_roundtrip);
      ] );
    ( "public_profile_user",
      [
        ("empty", `Quick, test_public_profile_user_empty);
        ("roundtrip", `Quick, test_public_profile_user_roundtrip);
      ] );
    ( "public_profile_error",
      [
        ("empty", `Quick, test_public_profile_error_empty);
        ("roundtrip", `Quick, test_public_profile_error_roundtrip);
      ] );
    ( "public_profile_response",
      [
        ("empty", `Quick, test_public_profile_response_empty);
        ("roundtrip", `Quick, test_public_profile_response_roundtrip);
      ] );
    ( "profile",
      [
        ("empty", `Quick, test_profile_empty);
        ("roundtrip", `Quick, test_profile_roundtrip);
      ] );
    ( "collection",
      [
        ("empty", `Quick, test_collection_empty);
        ("roundtrip", `Quick, test_collection_roundtrip);
      ] );
    ( "series_summary",
      [
        ("empty", `Quick, test_series_summary_empty);
        ("roundtrip", `Quick, test_series_summary_roundtrip);
      ] );
    ( "market",
      [
        ("empty", `Quick, test_market_empty);
        ("roundtrip", `Quick, test_market_roundtrip);
        ("partial json", `Quick, test_market_partial_json);
      ] );
    ( "event",
      [
        ("empty", `Quick, test_event_empty);
        ("roundtrip", `Quick, test_event_roundtrip);
        ("partial json", `Quick, test_event_partial_json);
      ] );
    ( "series",
      [
        ("empty", `Quick, test_series_empty);
        ("roundtrip", `Quick, test_series_roundtrip);
      ] );
    ( "events_pagination",
      [
        ("empty", `Quick, test_events_pagination_empty);
        ("roundtrip", `Quick, test_events_pagination_roundtrip);
      ] );
    ( "search",
      [
        ("empty", `Quick, test_search_empty);
        ("roundtrip", `Quick, test_search_roundtrip);
      ] );
    ( "sports_metadata",
      [
        ("empty", `Quick, test_sports_metadata_empty);
        ("roundtrip", `Quick, test_sports_metadata_roundtrip);
      ] );
    ( "sports_market_types_response",
      [
        ("empty", `Quick, test_sports_market_types_response_empty);
        ("roundtrip", `Quick, test_sports_market_types_response_roundtrip);
      ] );
    ( "markets_information_body",
      [
        ("empty", `Quick, test_markets_information_body_empty);
        ("roundtrip", `Quick, test_markets_information_body_roundtrip);
      ] );
  ]
