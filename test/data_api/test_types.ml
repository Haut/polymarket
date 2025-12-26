(** Unit tests for Data_api.Types module - Domain types only.

    Validation logic tests are in test/common/test_primitives.ml since
    validation is handled by Common.Primitives. *)

(** {1 Side Enum Tests} *)

let test_side_roundtrip () =
  let open Polymarket_data.Types.Side in
  let sides = [ Buy; Sell ] in
  List.iter
    (fun side ->
      let json = yojson_of_t side in
      let parsed = t_of_yojson json in
      Alcotest.(check bool) (show side) true (equal side parsed))
    sides

let test_side_string_conversion () =
  let open Polymarket_data.Types.Side in
  Alcotest.(check string) "Buy -> string" "BUY" (to_string Buy);
  Alcotest.(check string) "Sell -> string" "SELL" (to_string Sell)

(** {1 Activity Type Enum Tests} *)

let test_activity_type_roundtrip () =
  let open Polymarket_data.Types.Activity_type in
  let types = [ Trade; Split; Merge; Redeem; Reward; Conversion ] in
  List.iter
    (fun t ->
      let json = yojson_of_t t in
      let parsed = t_of_yojson json in
      Alcotest.(check bool) (show t) true (equal t parsed))
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
