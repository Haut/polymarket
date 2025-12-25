(** Tests for Common.Primitives module *)

open Alcotest
open Polymarket_common.Primitives

(** {1 Address Module Tests} *)

let valid_addresses =
  [
    "0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d59";
    "0x0000000000000000000000000000000000000000";
    "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
    "0xAbCdEf0123456789AbCdEf0123456789AbCdEf01";
  ]

let invalid_addresses =
  [
    ("", "empty string");
    ("0x", "only prefix");
    ("0x123", "too short");
    ("0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d5", "one char short");
    ("0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d599", "one char long");
    ("1a9a6f917a87a4f02c33f8530c6a8998f1bc8d59", "missing prefix");
    ("0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8dgg", "invalid hex");
    ("0x1a9a6f917a87a4f02c33f8530c6a8998f1bc8d5 ", "trailing space");
  ]

let test_address_make_valid () =
  List.iter
    (fun addr ->
      match Address.make addr with
      | Ok t -> check string "round-trip" addr (Address.to_string t)
      | Error msg -> fail ("Expected Ok, got Error: " ^ msg))
    valid_addresses

let test_address_make_invalid () =
  List.iter
    (fun (addr, desc) ->
      match Address.make addr with
      | Ok _ -> fail ("Expected Error for " ^ desc ^ ", got Ok")
      | Error _ -> ())
    invalid_addresses

let test_address_json_roundtrip () =
  List.iter
    (fun addr ->
      let t = Address.make_exn addr in
      let json = Address.to_yojson t in
      let t' = Address.of_yojson_exn json in
      check string "json round-trip" addr (Address.to_string t'))
    valid_addresses

(** {1 Hash64 Module Tests} *)

let valid_hash64s =
  [
    "0x1234567890123456789012345678901234567890123456789012345678901234";
    "0x0000000000000000000000000000000000000000000000000000000000000000";
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  ]

let invalid_hash64s =
  [
    ("", "empty string");
    ("0x", "only prefix");
    ("0x1234", "too short");
    ( "0x123456789012345678901234567890123456789012345678901234567890123",
      "one char short" );
    ( "0x12345678901234567890123456789012345678901234567890123456789012345",
      "one char long" );
  ]

let test_hash64_make_valid () =
  List.iter
    (fun hash ->
      match Hash64.make hash with
      | Ok t -> check string "round-trip" hash (Hash64.to_string t)
      | Error msg -> fail ("Expected Ok, got Error: " ^ msg))
    valid_hash64s

let test_hash64_make_invalid () =
  List.iter
    (fun (hash, desc) ->
      match Hash64.make hash with
      | Ok _ -> fail ("Expected Error for " ^ desc ^ ", got Ok")
      | Error _ -> ())
    invalid_hash64s

(** {1 Hash Module Tests} *)

let valid_hashes =
  [
    "0x12";
    "0x1234567890";
    "0x1234567890123456789012345678901234567890123456789012345678901234567890";
  ]

let invalid_hashes =
  [ ("", "empty string"); ("0x", "only prefix"); ("12", "missing prefix") ]

let test_hash_make_valid () =
  List.iter
    (fun hash ->
      match Hash.make hash with
      | Ok t -> check string "round-trip" hash (Hash.to_string t)
      | Error msg -> fail ("Expected Ok, got Error: " ^ msg))
    valid_hashes

let test_hash_make_invalid () =
  List.iter
    (fun (hash, desc) ->
      match Hash.make hash with
      | Ok _ -> fail ("Expected Error for " ^ desc ^ ", got Ok")
      | Error _ -> ())
    invalid_hashes

(** {1 Test Suite} *)

let tests =
  [
    ( "Address",
      [
        test_case "make valid" `Quick test_address_make_valid;
        test_case "make invalid" `Quick test_address_make_invalid;
        test_case "JSON roundtrip" `Quick test_address_json_roundtrip;
      ] );
    ( "Hash64",
      [
        test_case "make valid" `Quick test_hash64_make_valid;
        test_case "make invalid" `Quick test_hash64_make_invalid;
      ] );
    ( "Hash",
      [
        test_case "make valid" `Quick test_hash_make_valid;
        test_case "make invalid" `Quick test_hash_make_invalid;
      ] );
  ]
