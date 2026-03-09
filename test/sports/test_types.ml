(** Unit tests for Sports WebSocket message types *)

open Polymarket.Sports.Types

(** {1 Sport Result Parsing} *)

let test_parse_full_sport_result () =
  let json =
    {|{"slug":"nba-lakers-vs-celtics","live":true,"ended":false,"score":"102-98","period":"Q4","elapsed":"8:30","last_update":"2026-03-08T20:00:00Z","finished_timestamp":null,"turn":"home"}|}
  in
  match parse_message json with
  | [ Update result ] ->
      Alcotest.(check string) "slug" "nba-lakers-vs-celtics" result.slug;
      Alcotest.(check (option bool)) "live" (Some true) result.live;
      Alcotest.(check (option bool)) "ended" (Some false) result.ended;
      Alcotest.(check (option string)) "score" (Some "102-98") result.score;
      Alcotest.(check (option string)) "period" (Some "Q4") result.period;
      Alcotest.(check (option string)) "elapsed" (Some "8:30") result.elapsed;
      Alcotest.(check (option string))
        "last_update" (Some "2026-03-08T20:00:00Z") result.last_update;
      Alcotest.(check (option string))
        "finished_timestamp" None result.finished_timestamp;
      Alcotest.(check (option string)) "turn" (Some "home") result.turn
  | _ -> Alcotest.fail "Expected single Update message"

let test_parse_minimal_sport_result () =
  let json = {|{"slug":"nfl-chiefs-vs-ravens"}|} in
  match parse_message json with
  | [ Update result ] ->
      Alcotest.(check string) "slug" "nfl-chiefs-vs-ravens" result.slug;
      Alcotest.(check (option bool)) "live" None result.live;
      Alcotest.(check (option bool)) "ended" None result.ended;
      Alcotest.(check (option string)) "score" None result.score;
      Alcotest.(check (option string)) "period" None result.period;
      Alcotest.(check (option string)) "elapsed" None result.elapsed;
      Alcotest.(check (option string)) "last_update" None result.last_update;
      Alcotest.(check (option string))
        "finished_timestamp" None result.finished_timestamp;
      Alcotest.(check (option string)) "turn" None result.turn
  | _ -> Alcotest.fail "Expected single Update message"

let test_parse_ping_returns_empty () =
  let result = parse_message "ping" in
  match result with
  | [ Unknown _ ] -> ()
  | _ ->
      Alcotest.fail "Expected ping to produce Unknown (handled at client level)"

let test_parse_invalid_json () =
  match parse_message "not json at all" with
  | [ Unknown _ ] -> ()
  | _ -> Alcotest.fail "Expected Unknown for invalid JSON"

let test_sport_result_yojson_roundtrip () =
  let result =
    {
      slug = "epl-arsenal-vs-chelsea";
      live = Some true;
      ended = Some false;
      score = Some "2-1";
      period = Some "2H";
      elapsed = Some "67:00";
      last_update = Some "2026-03-08T15:00:00Z";
      finished_timestamp = None;
      turn = None;
    }
  in
  let json = yojson_of_sport_result result in
  let decoded = sport_result_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_sport_result result decoded)

let test_parse_extra_fields_ignored () =
  let json =
    {|{"slug":"test-match","extra_field":"should_be_ignored","another":42}|}
  in
  match parse_message json with
  | [ Update result ] -> Alcotest.(check string) "slug" "test-match" result.slug
  | _ -> Alcotest.fail "Expected single Update message"

(** {1 Test Suite} *)

let tests =
  [
    ( "sport_result parsing",
      [
        Alcotest.test_case "full sport_result" `Quick
          test_parse_full_sport_result;
        Alcotest.test_case "minimal sport_result (slug only)" `Quick
          test_parse_minimal_sport_result;
        Alcotest.test_case "ping returns Unknown" `Quick
          test_parse_ping_returns_empty;
        Alcotest.test_case "invalid JSON" `Quick test_parse_invalid_json;
        Alcotest.test_case "yojson roundtrip" `Quick
          test_sport_result_yojson_roundtrip;
        Alcotest.test_case "extra fields ignored" `Quick
          test_parse_extra_fields_ignored;
      ] );
  ]
