(** Unit tests for Data_api.Types module - Domain types only.

    Validation logic tests are in test/common/test_primitives.ml since
    validation is handled by Common.Primitives. *)

(** {1 Side Enum Tests} *)

let test_side_roundtrip () =
  let open Polymarket.Data_api.Types in
  let sides = [ BUY; SELL ] in
  List.iter
    (fun side ->
      let json = yojson_of_side side in
      let parsed = side_of_yojson json in
      Alcotest.(check bool) (show_side side) true (equal_side side parsed))
    sides

let test_side_string_conversion () =
  let open Polymarket.Data_api.Types in
  Alcotest.(check string) "BUY -> string" "BUY" (string_of_side BUY);
  Alcotest.(check string) "SELL -> string" "SELL" (string_of_side SELL)

(** {1 Activity Type Enum Tests} *)

let test_activity_type_roundtrip () =
  let open Polymarket.Data_api.Types in
  let types = [ TRADE; SPLIT; MERGE; REDEEM; REWARD; CONVERSION ] in
  List.iter
    (fun t ->
      let json = yojson_of_activity_type t in
      let parsed = activity_type_of_yojson json in
      Alcotest.(check bool)
        (show_activity_type t) true
        (equal_activity_type t parsed))
    types

(** {1 Test Suite} *)

let tests =
  [
    ( "side enum",
      [
        ("roundtrip", `Quick, test_side_roundtrip);
        ("string conversion", `Quick, test_side_string_conversion);
      ] );
    ( "activity_type enum",
      [ ("roundtrip", `Quick, test_activity_type_roundtrip) ] );
  ]
