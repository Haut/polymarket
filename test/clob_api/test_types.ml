(** Unit tests for Clob_api.Types module *)

open Polymarket_clob.Types

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

(** {1 Side Tests} *)

let test_side_string_roundtrip () =
  let sides = [ Side.Buy; Side.Sell ] in
  List.iter
    (fun side ->
      let str = Side.to_string side in
      let result = Side.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Side %s roundtrip" str)
        true (Side.equal side result))
    sides

let test_side_string_values () =
  Alcotest.(check string) "BUY" "BUY" (Side.to_string Side.Buy);
  Alcotest.(check string) "SELL" "SELL" (Side.to_string Side.Sell)

let test_side_json_roundtrip () =
  let sides = [ Side.Buy; Side.Sell ] in
  List.iter
    (fun side ->
      let json = Side.yojson_of_t side in
      let result = Side.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Side JSON roundtrip %s" (Side.show side))
        true (Side.equal side result))
    sides

(** {1 Order Type Tests} *)

let test_order_type_string_roundtrip () =
  let types =
    [ Order_type.Gtc; Order_type.Gtd; Order_type.Fok; Order_type.Fak ]
  in
  List.iter
    (fun ot ->
      let str = Order_type.to_string ot in
      let result = Order_type.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Order_type %s roundtrip" str)
        true
        (Order_type.equal ot result))
    types

let test_order_type_string_values () =
  Alcotest.(check string) "GTC" "GTC" (Order_type.to_string Order_type.Gtc);
  Alcotest.(check string) "GTD" "GTD" (Order_type.to_string Order_type.Gtd);
  Alcotest.(check string) "FOK" "FOK" (Order_type.to_string Order_type.Fok);
  Alcotest.(check string) "FAK" "FAK" (Order_type.to_string Order_type.Fak)

let test_order_type_json_roundtrip () =
  let types =
    [ Order_type.Gtc; Order_type.Gtd; Order_type.Fok; Order_type.Fak ]
  in
  List.iter
    (fun ot ->
      let json = Order_type.yojson_of_t ot in
      let result = Order_type.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Order_type JSON roundtrip %s" (Order_type.show ot))
        true
        (Order_type.equal ot result))
    types

(** {1 Signature Type Tests} *)

let test_signature_type_int_roundtrip () =
  let types =
    [
      Signature_type.Eoa;
      Signature_type.Poly_proxy;
      Signature_type.Poly_gnosis_safe;
    ]
  in
  List.iter
    (fun st ->
      let i = Signature_type.to_int st in
      let result = Signature_type.of_int i in
      Alcotest.(check bool)
        (Printf.sprintf "Signature_type %d roundtrip" i)
        true
        (Signature_type.equal st result))
    types

let test_signature_type_int_values () =
  Alcotest.(check int) "Eoa" 0 (Signature_type.to_int Signature_type.Eoa);
  Alcotest.(check int)
    "Poly_proxy" 1
    (Signature_type.to_int Signature_type.Poly_proxy);
  Alcotest.(check int)
    "Poly_gnosis_safe" 2
    (Signature_type.to_int Signature_type.Poly_gnosis_safe)

let test_signature_type_json_roundtrip () =
  let types =
    [
      Signature_type.Eoa;
      Signature_type.Poly_proxy;
      Signature_type.Poly_gnosis_safe;
    ]
  in
  List.iter
    (fun st ->
      let json = Signature_type.yojson_of_t st in
      let result = Signature_type.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Signature_type JSON roundtrip %s"
           (Signature_type.show st))
        true
        (Signature_type.equal st result))
    types

(** {1 Status Tests} *)

let test_status_string_roundtrip () =
  let statuses =
    [
      Status.Live;
      Status.Matched;
      Status.Delayed;
      Status.Unmatched;
      Status.Cancelled;
      Status.Expired;
    ]
  in
  List.iter
    (fun st ->
      let str = Status.to_string st in
      let result = Status.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Status %s roundtrip" str)
        true (Status.equal st result))
    statuses

let test_status_string_values () =
  Alcotest.(check string) "LIVE" "LIVE" (Status.to_string Status.Live);
  Alcotest.(check string) "MATCHED" "MATCHED" (Status.to_string Status.Matched);
  Alcotest.(check string) "DELAYED" "DELAYED" (Status.to_string Status.Delayed);
  Alcotest.(check string)
    "UNMATCHED" "UNMATCHED"
    (Status.to_string Status.Unmatched);
  Alcotest.(check string)
    "CANCELLED" "CANCELLED"
    (Status.to_string Status.Cancelled);
  Alcotest.(check string) "EXPIRED" "EXPIRED" (Status.to_string Status.Expired)

let test_status_json_roundtrip () =
  let statuses =
    [
      Status.Live;
      Status.Matched;
      Status.Delayed;
      Status.Unmatched;
      Status.Cancelled;
      Status.Expired;
    ]
  in
  List.iter
    (fun st ->
      let json = Status.yojson_of_t st in
      let result = Status.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Status JSON roundtrip %s" (Status.show st))
        true (Status.equal st result))
    statuses

(** {1 Trade Type Tests} *)

let test_trade_type_string_roundtrip () =
  let types = [ Trade_type.Taker; Trade_type.Maker ] in
  List.iter
    (fun tt ->
      let str = Trade_type.to_string tt in
      let result = Trade_type.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Trade_type %s roundtrip" str)
        true
        (Trade_type.equal tt result))
    types

let test_trade_type_string_values () =
  Alcotest.(check string)
    "TAKER" "TAKER"
    (Trade_type.to_string Trade_type.Taker);
  Alcotest.(check string)
    "MAKER" "MAKER"
    (Trade_type.to_string Trade_type.Maker)

let test_trade_type_json_roundtrip () =
  let types = [ Trade_type.Taker; Trade_type.Maker ] in
  List.iter
    (fun tt ->
      let json = Trade_type.yojson_of_t tt in
      let result = Trade_type.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Trade_type JSON roundtrip %s" (Trade_type.show tt))
        true
        (Trade_type.equal tt result))
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
    ( "Side",
      [
        ("string roundtrip", `Quick, test_side_string_roundtrip);
        ("string values", `Quick, test_side_string_values);
        ("JSON roundtrip", `Quick, test_side_json_roundtrip);
      ] );
    ( "Order_type",
      [
        ("string roundtrip", `Quick, test_order_type_string_roundtrip);
        ("string values", `Quick, test_order_type_string_values);
        ("JSON roundtrip", `Quick, test_order_type_json_roundtrip);
      ] );
    ( "Signature_type",
      [
        ("int roundtrip", `Quick, test_signature_type_int_roundtrip);
        ("int values", `Quick, test_signature_type_int_values);
        ("JSON roundtrip", `Quick, test_signature_type_json_roundtrip);
      ] );
    ( "Status",
      [
        ("string roundtrip", `Quick, test_status_string_roundtrip);
        ("string values", `Quick, test_status_string_values);
        ("JSON roundtrip", `Quick, test_status_json_roundtrip);
      ] );
    ( "Trade_type",
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
  ]
