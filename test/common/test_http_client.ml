(** Unit tests for Common.Http_client module *)

open Polymarket.Http_client.Client

let params_testable =
  Alcotest.testable
    (fun fmt params ->
      Format.fprintf fmt "[%s]"
        (String.concat "; "
           (List.map
              (fun (k, vs) ->
                Printf.sprintf "(%s, [%s])" k (String.concat ", " vs))
              params)))
    ( = )

(** {1 Query Parameter Builder Tests} *)

let test_add_some () =
  let result = [] |> add "key" (Some "value") in
  Alcotest.(check params_testable)
    "adds key-value pair"
    [ ("key", [ "value" ]) ]
    result

let test_add_none () =
  let result = [] |> add "key" None in
  Alcotest.(check params_testable) "returns empty for None" [] result

let test_add_preserves_existing () =
  let result = [ ("existing", [ "val" ]) ] |> add "key" (Some "value") in
  Alcotest.(check params_testable)
    "preserves existing params"
    [ ("key", [ "value" ]); ("existing", [ "val" ]) ]
    result

let test_add_list_non_empty () =
  let result = [] |> add_list "ids" string_of_int (Some [ 1; 2; 3 ]) in
  Alcotest.(check params_testable)
    "joins with comma"
    [ ("ids", [ "1,2,3" ]) ]
    result

let test_add_list_empty () =
  let result = [] |> add_list "ids" string_of_int (Some []) in
  Alcotest.(check params_testable) "returns empty for empty list" [] result

let test_add_list_none () =
  let result = [] |> add_list "ids" string_of_int None in
  Alcotest.(check params_testable) "returns empty for None" [] result

let test_add_list_strings () =
  let result = [] |> add_list "tags" Fun.id (Some [ "a"; "b"; "c" ]) in
  Alcotest.(check params_testable)
    "joins strings"
    [ ("tags", [ "a,b,c" ]) ]
    result

let test_add_list_single () =
  let result = [] |> add_list "ids" string_of_int (Some [ 42 ]) in
  Alcotest.(check params_testable) "single item" [ ("ids", [ "42" ]) ] result

let test_add_list_with_commas () =
  (* Note: This tests current behavior - strings with commas are passed through *)
  let result = [] |> add_list "tags" Fun.id (Some [ "a,b"; "c" ]) in
  Alcotest.(check params_testable)
    "strings with commas"
    [ ("tags", [ "a,b,c" ]) ]
    result

let test_add_bool_true () =
  let result = [] |> add_bool "flag" (Some true) in
  Alcotest.(check params_testable) "adds true" [ ("flag", [ "true" ]) ] result

let test_add_bool_false () =
  let result = [] |> add_bool "flag" (Some false) in
  Alcotest.(check params_testable) "adds false" [ ("flag", [ "false" ]) ] result

let test_add_bool_none () =
  let result = [] |> add_bool "flag" None in
  Alcotest.(check params_testable) "returns empty for None" [] result

let test_add_int_some () =
  let result = [] |> add_int "count" (Some 42) in
  Alcotest.(check params_testable) "adds int" [ ("count", [ "42" ]) ] result

let test_add_int_none () =
  let result = [] |> add_int "count" None in
  Alcotest.(check params_testable) "returns empty for None" [] result

let test_add_int_negative () =
  let result = [] |> add_int "offset" (Some (-10)) in
  Alcotest.(check params_testable)
    "handles negative"
    [ ("offset", [ "-10" ]) ]
    result

let test_add_int_zero () =
  let result = [] |> add_int "count" (Some 0) in
  Alcotest.(check params_testable) "handles zero" [ ("count", [ "0" ]) ] result

let test_add_float_some () =
  let result = [] |> add_float "price" (Some 3.14) in
  Alcotest.(check params_testable) "adds float" [ ("price", [ "3.14" ]) ] result

let test_add_float_none () =
  let result = [] |> add_float "price" None in
  Alcotest.(check params_testable) "returns empty for None" [] result

let test_add_float_integer () =
  let result = [] |> add_float "amount" (Some 100.0) in
  Alcotest.(check params_testable)
    "handles integer float"
    [ ("amount", [ "100." ]) ]
    result

let test_add_float_negative () =
  let result = [] |> add_float "price" (Some (-5.5)) in
  Alcotest.(check params_testable)
    "handles negative"
    [ ("price", [ "-5.5" ]) ]
    result

(** {1 URI Building Tests} *)

let test_build_uri_no_params () =
  let uri = build_uri "https://api.example.com" "/endpoint" [] in
  Alcotest.(check string)
    "builds basic URI" "https://api.example.com/endpoint" (Uri.to_string uri)

let test_build_uri_with_params () =
  let uri =
    build_uri "https://api.example.com" "/search"
      [ ("q", [ "test" ]); ("limit", [ "10" ]) ]
  in
  let uri_str = Uri.to_string uri in
  (* Verify the URI contains the expected parts *)
  Alcotest.(check bool)
    "starts with base" true
    (Test_utils.string_contains ~haystack:uri_str
       ~needle:"https://api.example.com/search");
  Alcotest.(check bool)
    "has query separator" true
    (Test_utils.string_contains ~haystack:uri_str ~needle:"?");
  Alcotest.(check bool)
    "contains q param" true
    (Test_utils.string_contains ~haystack:uri_str ~needle:"q=test");
  Alcotest.(check bool)
    "contains limit param" true
    (Test_utils.string_contains ~haystack:uri_str ~needle:"limit=10")

let test_build_uri_trailing_slash () =
  (* Note: This tests current behavior where trailing slash causes double slash *)
  let uri = build_uri "https://api.example.com/" "/endpoint" [] in
  Alcotest.(check string)
    "handles trailing slash" "https://api.example.com//endpoint"
    (Uri.to_string uri)

let test_build_uri_empty_path () =
  let uri = build_uri "https://api.example.com" "" [] in
  Alcotest.(check string)
    "empty path" "https://api.example.com" (Uri.to_string uri)

(** {1 JSON Parsing Tests} *)

type test_record = { name : string; value : int }

let test_record_of_yojson json =
  let open Yojson.Safe.Util in
  {
    name = json |> member "name" |> to_string;
    value = json |> member "value" |> to_int;
  }

let test_parse_json_success () =
  let json_str = {|{"name": "test", "value": 42}|} in
  let result = parse_json test_record_of_yojson json_str in
  match result with
  | Ok record ->
      Alcotest.(check string) "parses name" "test" record.name;
      Alcotest.(check int) "parses value" 42 record.value
  | Error _ -> Alcotest.fail "expected success"

let test_parse_json_invalid () =
  (* Test with a parser that raises Ppx_yojson_conv exception *)
  let parser json =
    match json with
    | `Assoc _ ->
        raise
          (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
             (Failure "missing required field", json))
    | _ -> failwith "unexpected"
  in
  let json_str = {|{"name": "test"}|} in
  let result = parse_json parser json_str in
  match result with
  | Ok _ -> Alcotest.fail "expected error"
  | Error msg ->
      Alcotest.(check bool) "has error message" true (String.length msg > 0)

let test_parse_json_malformed () =
  let json_str = {|not json|} in
  let result = parse_json test_record_of_yojson json_str in
  match result with
  | Ok _ -> Alcotest.fail "expected error"
  | Error msg ->
      Alcotest.(check bool) "has error message" true (String.length msg > 0)

let test_parse_json_list_success () =
  let json_str = {|[{"name": "a", "value": 1}, {"name": "b", "value": 2}]|} in
  let result = parse_json_list test_record_of_yojson json_str in
  match result with
  | Ok records ->
      Alcotest.(check int) "parses two records" 2 (List.length records);
      Alcotest.(check string) "first name" "a" (List.nth records 0).name;
      Alcotest.(check string) "second name" "b" (List.nth records 1).name
  | Error _ -> Alcotest.fail "expected success"

let test_parse_json_list_empty () =
  let json_str = {|[]|} in
  let result = parse_json_list test_record_of_yojson json_str in
  match result with
  | Ok records ->
      Alcotest.(check int) "parses empty list" 0 (List.length records)
  | Error _ -> Alcotest.fail "expected success"

let test_parse_json_list_not_array () =
  let json_str = {|{"name": "test", "value": 42}|} in
  let result = parse_json_list test_record_of_yojson json_str in
  match result with
  | Ok _ -> Alcotest.fail "expected error"
  | Error msg ->
      Alcotest.(check string) "expects array error" "Expected JSON array" msg

(** {1 Error Handling Tests} *)

let test_parse_error_valid () =
  let body = {|{"error": "something went wrong"}|} in
  let err = parse_error body in
  Alcotest.(check string) "parses error" "something went wrong" err.error

let test_parse_error_fallback () =
  let body = "plain text error" in
  let err = parse_error body in
  Alcotest.(check string) "uses body as error" "plain text error" err.error

let test_parse_error_empty () =
  let body = "" in
  let err = parse_error body in
  Alcotest.(check string) "empty body" "" err.error

let test_to_error () =
  let err = to_error "test message" in
  Alcotest.(check string) "creates error record" "test message" err.error

(** {1 Test Suite} *)

let tests =
  [
    ( "add",
      [
        ("Some value", `Quick, test_add_some);
        ("None", `Quick, test_add_none);
        ("preserves existing", `Quick, test_add_preserves_existing);
      ] );
    ( "add_list",
      [
        ("non-empty", `Quick, test_add_list_non_empty);
        ("empty list", `Quick, test_add_list_empty);
        ("None", `Quick, test_add_list_none);
        ("strings", `Quick, test_add_list_strings);
        ("single item", `Quick, test_add_list_single);
        ("strings with commas", `Quick, test_add_list_with_commas);
      ] );
    ( "add_bool",
      [
        ("true", `Quick, test_add_bool_true);
        ("false", `Quick, test_add_bool_false);
        ("None", `Quick, test_add_bool_none);
      ] );
    ( "add_int",
      [
        ("Some", `Quick, test_add_int_some);
        ("None", `Quick, test_add_int_none);
        ("negative", `Quick, test_add_int_negative);
        ("zero", `Quick, test_add_int_zero);
      ] );
    ( "add_float",
      [
        ("Some", `Quick, test_add_float_some);
        ("None", `Quick, test_add_float_none);
        ("integer value", `Quick, test_add_float_integer);
        ("negative", `Quick, test_add_float_negative);
      ] );
    ( "build_uri",
      [
        ("no params", `Quick, test_build_uri_no_params);
        ("with params", `Quick, test_build_uri_with_params);
        ("trailing slash", `Quick, test_build_uri_trailing_slash);
        ("empty path", `Quick, test_build_uri_empty_path);
      ] );
    ( "parse_json",
      [
        ("success", `Quick, test_parse_json_success);
        ("invalid", `Quick, test_parse_json_invalid);
        ("malformed", `Quick, test_parse_json_malformed);
      ] );
    ( "parse_json_list",
      [
        ("success", `Quick, test_parse_json_list_success);
        ("empty", `Quick, test_parse_json_list_empty);
        ("not array", `Quick, test_parse_json_list_not_array);
      ] );
    ( "error handling",
      [
        ("parse_error valid", `Quick, test_parse_error_valid);
        ("parse_error fallback", `Quick, test_parse_error_fallback);
        ("parse_error empty", `Quick, test_parse_error_empty);
        ("to_error", `Quick, test_to_error);
      ] );
  ]
