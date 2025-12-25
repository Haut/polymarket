(** Unit tests for Clob_api.Types module *)

open Polymarket.Clob_api.Types

(** {1 Address Validation Tests} *)

let test_address_valid () =
  let valid_addresses =
    [
      "0x1234567890abcdef1234567890abcdef12345678";
      "0x1234567890ABCDEF1234567890ABCDEF12345678";
      "0x1234567890AbCdEf1234567890aBcDeF12345678";
      "0x0000000000000000000000000000000000000000";
      "0xffffffffffffffffffffffffffffffffffffffff";
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

(** {1 Signature Validation Tests} *)

let test_signature_valid () =
  let valid_signatures =
    [ "0x1234567890abcdef"; "0xabcdef"; "0x" ^ String.make 130 'a' ]
  in
  List.iter
    (fun sig_ -> Alcotest.(check bool) sig_ true (is_valid_signature sig_))
    valid_signatures

let test_signature_invalid () =
  let invalid_cases =
    [
      ("", "empty string");
      ("0x", "just prefix");
      ("1234567890abcdef", "no 0x prefix");
      ("0X1234567890abcdef", "wrong case 0X prefix");
      ("0xGGGG", "non-hex characters");
    ]
  in
  List.iter
    (fun (sig_, desc) ->
      Alcotest.(check bool) desc false (is_valid_signature sig_))
    invalid_cases

(** {1 Order Side Tests} *)

let test_order_side_string_roundtrip () =
  let sides = [ BUY; SELL ] in
  List.iter
    (fun side ->
      let str = string_of_order_side side in
      let result = order_side_of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "order_side %s roundtrip" str)
        true
        (equal_order_side side result))
    sides

let test_order_side_string_values () =
  Alcotest.(check string) "BUY" "BUY" (string_of_order_side BUY);
  Alcotest.(check string) "SELL" "SELL" (string_of_order_side SELL)

let test_order_side_json_roundtrip () =
  let sides = [ BUY; SELL ] in
  List.iter
    (fun side ->
      let json = yojson_of_order_side side in
      let result = order_side_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "order_side JSON roundtrip %s" (show_order_side side))
        true
        (equal_order_side side result))
    sides

(** {1 Order Type Tests} *)

let test_order_type_string_roundtrip () =
  let types = [ GTC; GTD; FOK; FAK ] in
  List.iter
    (fun ot ->
      let str = string_of_order_type ot in
      let result = order_type_of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "order_type %s roundtrip" str)
        true
        (equal_order_type ot result))
    types

let test_order_type_string_values () =
  Alcotest.(check string) "GTC" "GTC" (string_of_order_type GTC);
  Alcotest.(check string) "GTD" "GTD" (string_of_order_type GTD);
  Alcotest.(check string) "FOK" "FOK" (string_of_order_type FOK);
  Alcotest.(check string) "FAK" "FAK" (string_of_order_type FAK)

let test_order_type_json_roundtrip () =
  let types = [ GTC; GTD; FOK; FAK ] in
  List.iter
    (fun ot ->
      let json = yojson_of_order_type ot in
      let result = order_type_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "order_type JSON roundtrip %s" (show_order_type ot))
        true
        (equal_order_type ot result))
    types

(** {1 Signature Type Tests} *)

let test_signature_type_int_roundtrip () =
  let types = [ EOA; POLY_PROXY; POLY_GNOSIS_SAFE ] in
  List.iter
    (fun st ->
      let i = int_of_signature_type st in
      let result = signature_type_of_int i in
      Alcotest.(check bool)
        (Printf.sprintf "signature_type %d roundtrip" i)
        true
        (equal_signature_type st result))
    types

let test_signature_type_int_values () =
  Alcotest.(check int) "EOA" 0 (int_of_signature_type EOA);
  Alcotest.(check int) "POLY_PROXY" 1 (int_of_signature_type POLY_PROXY);
  Alcotest.(check int)
    "POLY_GNOSIS_SAFE" 2
    (int_of_signature_type POLY_GNOSIS_SAFE)

let test_signature_type_json_roundtrip () =
  let types = [ EOA; POLY_PROXY; POLY_GNOSIS_SAFE ] in
  List.iter
    (fun st ->
      let json = yojson_of_signature_type st in
      let result = signature_type_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "signature_type JSON roundtrip %s"
           (show_signature_type st))
        true
        (equal_signature_type st result))
    types

(** {1 Order Status Tests} *)

let test_order_status_string_roundtrip () =
  let statuses = [ LIVE; MATCHED; DELAYED; UNMATCHED; CANCELLED; EXPIRED ] in
  List.iter
    (fun st ->
      let str = string_of_order_status st in
      let result = order_status_of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "order_status %s roundtrip" str)
        true
        (equal_order_status st result))
    statuses

let test_order_status_string_values () =
  Alcotest.(check string) "live" "live" (string_of_order_status LIVE);
  Alcotest.(check string) "matched" "matched" (string_of_order_status MATCHED);
  Alcotest.(check string) "delayed" "delayed" (string_of_order_status DELAYED);
  Alcotest.(check string)
    "unmatched" "unmatched"
    (string_of_order_status UNMATCHED);
  Alcotest.(check string)
    "cancelled" "cancelled"
    (string_of_order_status CANCELLED);
  Alcotest.(check string) "expired" "expired" (string_of_order_status EXPIRED)

let test_order_status_json_roundtrip () =
  let statuses = [ LIVE; MATCHED; DELAYED; UNMATCHED; CANCELLED; EXPIRED ] in
  List.iter
    (fun st ->
      let json = yojson_of_order_status st in
      let result = order_status_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "order_status JSON roundtrip %s" (show_order_status st))
        true
        (equal_order_status st result))
    statuses

(** {1 Trade Type Tests} *)

let test_trade_type_string_roundtrip () =
  let types = [ TAKER; MAKER ] in
  List.iter
    (fun tt ->
      let str = string_of_trade_type tt in
      let result = trade_type_of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "trade_type %s roundtrip" str)
        true
        (equal_trade_type tt result))
    types

let test_trade_type_string_values () =
  Alcotest.(check string) "TAKER" "TAKER" (string_of_trade_type TAKER);
  Alcotest.(check string) "MAKER" "MAKER" (string_of_trade_type MAKER)

let test_trade_type_json_roundtrip () =
  let types = [ TAKER; MAKER ] in
  List.iter
    (fun tt ->
      let json = yojson_of_trade_type tt in
      let result = trade_type_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "trade_type JSON roundtrip %s" (show_trade_type tt))
        true
        (equal_trade_type tt result))
    types

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

let test_signature_of_yojson_exn_valid () =
  let json = `String "0x1234567890abcdef1234567890abcdef" in
  let result = signature_of_yojson_exn json in
  Alcotest.(check string)
    "parses valid" "0x1234567890abcdef1234567890abcdef" result

let test_signature_of_yojson_exn_invalid () =
  let json = `String "invalid" in
  try
    let _ = signature_of_yojson_exn json in
    Alcotest.fail "expected exception"
  with Invalid_signature sig_ ->
    Alcotest.(check string) "raises with signature" "invalid" sig_

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

let test_signature_of_yojson_result_valid () =
  let json = `String "0x1234567890abcdef1234567890abcdef" in
  match signature_of_yojson_result json with
  | Ok sig_ ->
      Alcotest.(check string)
        "returns Ok" "0x1234567890abcdef1234567890abcdef" sig_
  | Error _ -> Alcotest.fail "expected Ok"

let test_signature_of_yojson_result_invalid () =
  let json = `String "invalid" in
  match signature_of_yojson_result json with
  | Ok _ -> Alcotest.fail "expected Error"
  | Error msg ->
      Alcotest.(check bool) "returns Error" true (String.length msg > 0)

(** {1 Empty Constructor Tests} *)

let test_empty_constructors () =
  let _ = empty_order_book_level in
  let _ = empty_order_book_summary in
  let _ = empty_signed_order in
  let _ = empty_order_request in
  let _ = empty_create_order_response in
  let _ = empty_open_order in
  let _ = empty_cancel_response in
  let _ = empty_maker_order_fill in
  let _ = empty_clob_trade in
  let _ = empty_price_response in
  let _ = empty_midpoint_response in
  let _ = empty_token_price in
  let _ = empty_price_point in
  let _ = empty_price_history in
  Alcotest.(check pass) "all empty constructors exist" () ()

(** {1 Test Suite} *)

let tests =
  [
    ( "address validation",
      [
        ("valid addresses", `Quick, test_address_valid);
        ("invalid addresses", `Quick, test_address_invalid);
      ] );
    ( "signature validation",
      [
        ("valid signatures", `Quick, test_signature_valid);
        ("invalid signatures", `Quick, test_signature_invalid);
      ] );
    ( "order_side",
      [
        ("string roundtrip", `Quick, test_order_side_string_roundtrip);
        ("string values", `Quick, test_order_side_string_values);
        ("JSON roundtrip", `Quick, test_order_side_json_roundtrip);
      ] );
    ( "order_type",
      [
        ("string roundtrip", `Quick, test_order_type_string_roundtrip);
        ("string values", `Quick, test_order_type_string_values);
        ("JSON roundtrip", `Quick, test_order_type_json_roundtrip);
      ] );
    ( "signature_type",
      [
        ("int roundtrip", `Quick, test_signature_type_int_roundtrip);
        ("int values", `Quick, test_signature_type_int_values);
        ("JSON roundtrip", `Quick, test_signature_type_json_roundtrip);
      ] );
    ( "order_status",
      [
        ("string roundtrip", `Quick, test_order_status_string_roundtrip);
        ("string values", `Quick, test_order_status_string_values);
        ("JSON roundtrip", `Quick, test_order_status_json_roundtrip);
      ] );
    ( "trade_type",
      [
        ("string roundtrip", `Quick, test_trade_type_string_roundtrip);
        ("string values", `Quick, test_trade_type_string_values);
        ("JSON roundtrip", `Quick, test_trade_type_json_roundtrip);
      ] );
    ( "validating deserializers",
      [
        ("address_of_yojson_exn valid", `Quick, test_address_of_yojson_exn_valid);
        ( "address_of_yojson_exn invalid",
          `Quick,
          test_address_of_yojson_exn_invalid );
        ( "signature_of_yojson_exn valid",
          `Quick,
          test_signature_of_yojson_exn_valid );
        ( "signature_of_yojson_exn invalid",
          `Quick,
          test_signature_of_yojson_exn_invalid );
        ( "address_of_yojson_result valid",
          `Quick,
          test_address_of_yojson_result_valid );
        ( "address_of_yojson_result invalid",
          `Quick,
          test_address_of_yojson_result_invalid );
        ( "signature_of_yojson_result valid",
          `Quick,
          test_signature_of_yojson_result_valid );
        ( "signature_of_yojson_result invalid",
          `Quick,
          test_signature_of_yojson_result_invalid );
      ] );
    ("empty constructors", [ ("all exist", `Quick, test_empty_constructors) ]);
  ]
