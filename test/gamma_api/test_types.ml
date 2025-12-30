(** Unit tests for Gamma_api.Types module *)

open Polymarket_gamma.Types

(** {1 Status Enum Tests} *)

let test_status_string_roundtrip () =
  let statuses = [ Status.Active; Status.Closed; Status.All ] in
  List.iter
    (fun status ->
      let str = Status.to_string status in
      let result = Status.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Status %s roundtrip" str)
        true (status = result))
    statuses

let test_status_string_values () =
  Alcotest.(check string) "Active" "active" (Status.to_string Status.Active);
  Alcotest.(check string) "Closed" "closed" (Status.to_string Status.Closed);
  Alcotest.(check string) "All" "all" (Status.to_string Status.All)

let test_status_of_string_opt_invalid () =
  Alcotest.(check (option reject))
    "of_string_opt returns None for invalid" None
    (Status.of_string_opt "invalid")

(** {1 Parent_entity_type Enum Tests} *)

let test_parent_entity_type_string_roundtrip () =
  let types =
    [
      Parent_entity_type.Event;
      Parent_entity_type.Series;
      Parent_entity_type.Market;
    ]
  in
  List.iter
    (fun pet ->
      let str = Parent_entity_type.to_string pet in
      let result = Parent_entity_type.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Parent_entity_type %s roundtrip" str)
        true (pet = result))
    types

let test_parent_entity_type_string_values () =
  Alcotest.(check string)
    "Event" "Event"
    (Parent_entity_type.to_string Parent_entity_type.Event);
  Alcotest.(check string)
    "Series" "Series"
    (Parent_entity_type.to_string Parent_entity_type.Series);
  Alcotest.(check string)
    "Market" "market"
    (Parent_entity_type.to_string Parent_entity_type.Market)

let test_parent_entity_type_of_string_opt_invalid () =
  Alcotest.(check (option reject))
    "of_string_opt returns None for invalid" None
    (Parent_entity_type.of_string_opt "invalid")

(** {1 Slug_size Enum Tests} *)

let test_slug_size_string_roundtrip () =
  let sizes = [ Slug_size.Sm; Slug_size.Md; Slug_size.Lg ] in
  List.iter
    (fun size ->
      let str = Slug_size.to_string size in
      let result = Slug_size.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Slug_size %s roundtrip" str)
        true (size = result))
    sizes

let test_slug_size_string_values () =
  Alcotest.(check string) "Sm" "sm" (Slug_size.to_string Slug_size.Sm);
  Alcotest.(check string) "Md" "md" (Slug_size.to_string Slug_size.Md);
  Alcotest.(check string) "Lg" "lg" (Slug_size.to_string Slug_size.Lg)

let test_slug_size_of_string_opt_invalid () =
  Alcotest.(check (option reject))
    "of_string_opt returns None for invalid" None
    (Slug_size.of_string_opt "invalid")

(** {1 Pagination JSON Tests} *)

let test_pagination_json_roundtrip () =
  let p = { has_more = true; total_results = 42 } in
  let json = yojson_of_pagination p in
  let parsed = pagination_of_yojson json in
  Alcotest.(check bool) "pagination roundtrip" true (equal_pagination p parsed)

let test_pagination_json_keys () =
  let json = `Assoc [ ("hasMore", `Bool true); ("totalResults", `Int 100) ] in
  let p = pagination_of_yojson json in
  Alcotest.(check bool) "has_more" true p.has_more;
  Alcotest.(check int) "total_results" 100 p.total_results

(** {1 Test Suite} *)

let tests =
  [
    ( "Status",
      [
        ("string roundtrip", `Quick, test_status_string_roundtrip);
        ("string values", `Quick, test_status_string_values);
        ("of_string_opt invalid", `Quick, test_status_of_string_opt_invalid);
      ] );
    ( "Parent_entity_type",
      [
        ("string roundtrip", `Quick, test_parent_entity_type_string_roundtrip);
        ("string values", `Quick, test_parent_entity_type_string_values);
        ( "of_string_opt invalid",
          `Quick,
          test_parent_entity_type_of_string_opt_invalid );
      ] );
    ( "Slug_size",
      [
        ("string roundtrip", `Quick, test_slug_size_string_roundtrip);
        ("string values", `Quick, test_slug_size_string_values);
        ("of_string_opt invalid", `Quick, test_slug_size_of_string_opt_invalid);
      ] );
    ( "pagination",
      [
        ("JSON roundtrip", `Quick, test_pagination_json_roundtrip);
        ("JSON keys", `Quick, test_pagination_json_keys);
      ] );
  ]
