(** Unit tests for Gamma_api.Params module *)

open Polymarket.Gamma_api.Params

(** {1 Status Tests} *)

let test_status_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_status
    [ (Active, "active"); (Closed, "closed"); (All, "all") ]

let test_status_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_status ~of_json:status_of_yojson
    ~equal:equal_status ~to_string:string_of_status [ Active; Closed; All ]

(** {1 Parent Entity Type Tests} *)

let test_parent_entity_type_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_parent_entity_type
    [ (Event, "Event"); (Series, "Series"); (Market, "market") ]

let test_parent_entity_type_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_parent_entity_type
    ~of_json:parent_entity_type_of_yojson ~equal:equal_parent_entity_type
    ~to_string:string_of_parent_entity_type [ Event; Series; Market ]

(** {1 Slug Size Tests} *)

let test_slug_size_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_slug_size
    [ (Sm, "sm"); (Md, "md"); (Lg, "lg") ]

let test_slug_size_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_slug_size
    ~of_json:slug_size_of_yojson ~equal:equal_slug_size
    ~to_string:string_of_slug_size [ Sm; Md; Lg ]

(** {1 Test Suite} *)

let tests =
  [
    ( "status",
      [
        ("to_string", `Quick, test_status_to_string);
        ("roundtrip", `Quick, test_status_roundtrip);
      ] );
    ( "parent_entity_type",
      [
        ("to_string", `Quick, test_parent_entity_type_to_string);
        ("roundtrip", `Quick, test_parent_entity_type_roundtrip);
      ] );
    ( "slug_size",
      [
        ("to_string", `Quick, test_slug_size_to_string);
        ("roundtrip", `Quick, test_slug_size_roundtrip);
      ] );
  ]
