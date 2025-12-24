(** Unit tests for Data_api.Types module - Custom validation logic only *)

open Polymarket.Data_api.Types

(** {1 Address Validation Tests} *)

let test_address_valid () =
  let valid_addresses =
    [
      "0x1234567890abcdef1234567890abcdef12345678";
      (* lowercase *)
      "0x1234567890ABCDEF1234567890ABCDEF12345678";
      (* uppercase *)
      "0x1234567890AbCdEf1234567890aBcDeF12345678";
      (* mixed case *)
      "0x0000000000000000000000000000000000000000";
      (* all zeros *)
      "0xffffffffffffffffffffffffffffffffffffffff";
      (* all f's *)
    ]
  in
  List.iter
    (fun addr -> Alcotest.(check bool) addr true (is_valid_address addr))
    valid_addresses

let test_address_invalid () =
  let invalid_cases =
    [
      ("", "empty string");
      ("0x123456789", "too short");
      ("0x1234567890abcdef1234567890abcdef1234567890", "too long");
      ("1234567890abcdef1234567890abcdef12345678", "no 0x prefix");
      ("1x1234567890abcdef1234567890abcdef12345678", "wrong prefix 1x");
      ("0X1234567890abcdef1234567890abcdef12345678", "wrong case 0X prefix");
      ("0xGGGGGGGGGGabcdef1234567890abcdef12345678", "non-hex characters");
      ("0x1234567890abcdef1234567890abcdef1234567 ", "trailing space");
      (" 0x1234567890abcdef1234567890abcdef12345678", "leading space");
    ]
  in
  List.iter
    (fun (addr, desc) ->
      Alcotest.(check bool) desc false (is_valid_address addr))
    invalid_cases

(** {1 Hash64 Validation Tests} *)

let test_hash64_valid () =
  let valid_hashes =
    [
      "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
      (* lowercase *)
      "0x1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF";
      (* uppercase *)
      "0x0000000000000000000000000000000000000000000000000000000000000000";
      (* all zeros *)
    ]
  in
  List.iter
    (fun hash -> Alcotest.(check bool) hash true (is_valid_hash64 hash))
    valid_hashes

let test_hash64_invalid () =
  let invalid_cases =
    [
      ("", "empty string");
      ("0x1234567890abcdef", "too short");
      ( "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "no prefix" );
      ( "0X1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "wrong case 0X" );
      ( "0xGGGGGGGGGGabcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "non-hex" );
    ]
  in
  List.iter
    (fun (hash, desc) ->
      Alcotest.(check bool) desc false (is_valid_hash64 hash))
    invalid_cases

(** {1 Validating Deserializer Tests} *)

let test_address_of_yojson_exn_valid () =
  let json = `String "0x1234567890abcdef1234567890abcdef12345678" in
  let result = address_of_yojson_exn json in
  Alcotest.(check string)
    "parses valid" "0x1234567890abcdef1234567890abcdef12345678" result

let test_address_of_yojson_exn_invalid () =
  let json = `String "invalid" in
  try
    let _ = address_of_yojson_exn json in
    Alcotest.fail "expected exception"
  with Invalid_address addr ->
    Alcotest.(check string) "raises with address" "invalid" addr

let test_hash64_of_yojson_exn_valid () =
  let json =
    `String "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  in
  let result = hash64_of_yojson_exn json in
  Alcotest.(check string)
    "parses valid"
    "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" result

let test_hash64_of_yojson_exn_invalid () =
  let json = `String "invalid" in
  try
    let _ = hash64_of_yojson_exn json in
    Alcotest.fail "expected exception"
  with Invalid_hash64 hash ->
    Alcotest.(check string) "raises with hash" "invalid" hash

let test_address_of_yojson_result_valid () =
  let json = `String "0x1234567890abcdef1234567890abcdef12345678" in
  match address_of_yojson_result json with
  | Ok addr ->
      Alcotest.(check string)
        "returns Ok" "0x1234567890abcdef1234567890abcdef12345678" addr
  | Error _ -> Alcotest.fail "expected Ok"

let test_address_of_yojson_result_invalid () =
  let json = `String "invalid" in
  match address_of_yojson_result json with
  | Ok _ -> Alcotest.fail "expected Error"
  | Error msg ->
      Alcotest.(check bool) "returns Error" true (String.length msg > 0)

let test_hash64_of_yojson_result_valid () =
  let json =
    `String "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  in
  match hash64_of_yojson_result json with
  | Ok hash ->
      Alcotest.(check string)
        "returns Ok"
        "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        hash
  | Error _ -> Alcotest.fail "expected Ok"

let test_hash64_of_yojson_result_invalid () =
  let json = `String "invalid" in
  match hash64_of_yojson_result json with
  | Ok _ -> Alcotest.fail "expected Error"
  | Error msg ->
      Alcotest.(check bool) "returns Error" true (String.length msg > 0)

(** {1 Test Suite} *)

let tests =
  [
    ( "address validation",
      [
        ("valid addresses", `Quick, test_address_valid);
        ("invalid addresses", `Quick, test_address_invalid);
      ] );
    ( "hash64 validation",
      [
        ("valid hashes", `Quick, test_hash64_valid);
        ("invalid hashes", `Quick, test_hash64_invalid);
      ] );
    ( "validating deserializers",
      [
        ("address_of_yojson_exn valid", `Quick, test_address_of_yojson_exn_valid);
        ( "address_of_yojson_exn invalid",
          `Quick,
          test_address_of_yojson_exn_invalid );
        ("hash64_of_yojson_exn valid", `Quick, test_hash64_of_yojson_exn_valid);
        ( "hash64_of_yojson_exn invalid",
          `Quick,
          test_hash64_of_yojson_exn_invalid );
        ( "address_of_yojson_result valid",
          `Quick,
          test_address_of_yojson_result_valid );
        ( "address_of_yojson_result invalid",
          `Quick,
          test_address_of_yojson_result_invalid );
        ( "hash64_of_yojson_result valid",
          `Quick,
          test_hash64_of_yojson_result_valid );
        ( "hash64_of_yojson_result invalid",
          `Quick,
          test_hash64_of_yojson_result_invalid );
      ] );
  ]
