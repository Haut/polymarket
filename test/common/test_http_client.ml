(** Unit tests for Http_client modules *)

open Polymarket_http.Client
module Json = Polymarket_http.Json
module Builder = Polymarket_http.Builder

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
  let result = Json.parse test_record_of_yojson json_str in
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
  let result = Json.parse parser json_str in
  match result with
  | Ok _ -> Alcotest.fail "expected error"
  | Error msg ->
      Alcotest.(check bool) "has error message" true (String.length msg > 0)

let test_parse_json_malformed () =
  let json_str = {|not json|} in
  let result = Json.parse test_record_of_yojson json_str in
  match result with
  | Ok _ -> Alcotest.fail "expected error"
  | Error msg ->
      Alcotest.(check bool) "has error message" true (String.length msg > 0)

let test_parse_json_list_success () =
  let json_str = {|[{"name": "a", "value": 1}, {"name": "b", "value": 2}]|} in
  let result = Json.parse_list test_record_of_yojson json_str in
  match result with
  | Ok records ->
      Alcotest.(check int) "parses two records" 2 (List.length records);
      Alcotest.(check string) "first name" "a" (List.nth records 0).name;
      Alcotest.(check string) "second name" "b" (List.nth records 1).name
  | Error _ -> Alcotest.fail "expected success"

let test_parse_json_list_empty () =
  let json_str = {|[]|} in
  let result = Json.parse_list test_record_of_yojson json_str in
  match result with
  | Ok records ->
      Alcotest.(check int) "parses empty list" 0 (List.length records)
  | Error _ -> Alcotest.fail "expected success"

let test_parse_json_list_not_array () =
  let json_str = {|{"name": "test", "value": 42}|} in
  let result = Json.parse_list test_record_of_yojson json_str in
  match result with
  | Ok _ -> Alcotest.fail "expected error"
  | Error msg ->
      Alcotest.(check bool)
        "expects array error" true
        (String.starts_with ~prefix:"Expected JSON array" msg)

(** {1 Error Handling Tests} *)

let test_parse_error_valid () =
  let body = {|{"error": "something went wrong"}|} in
  let err = parse_error ~status:400 body in
  match err with
  | Http_error { message; status; _ } ->
      Alcotest.(check string) "parses error" "something went wrong" message;
      Alcotest.(check int) "has status" 400 status
  | _ -> Alcotest.fail "expected Http_error"

let test_parse_error_fallback () =
  let body = "plain text error" in
  let err = parse_error ~status:500 body in
  match err with
  | Http_error { message; _ } ->
      Alcotest.(check string) "uses body as error" "plain text error" message
  | _ -> Alcotest.fail "expected Http_error"

let test_parse_error_empty () =
  let body = "" in
  let err = parse_error ~status:404 body in
  match err with
  | Http_error { message; _ } -> Alcotest.(check string) "empty body" "" message
  | _ -> Alcotest.fail "expected Http_error"

let test_to_error () =
  let err = to_error "test message" in
  match err with
  | Parse_error { message; _ } ->
      Alcotest.(check string) "creates parse error" "test message" message
  | _ -> Alcotest.fail "expected Parse_error"

(** {1 Test Suite} *)

let tests =
  [
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
