(** Unit tests for Data_api.Types module *)

open Polymarket.Data_api.Types

let float_testable = Alcotest.float 0.0001
let option_float = Alcotest.option float_testable

(** {1 Address Validation Tests} *)

let test_address_valid () =
  let valid_addresses = [
    "0x1234567890abcdef1234567890abcdef12345678";  (* lowercase *)
    "0x1234567890ABCDEF1234567890ABCDEF12345678";  (* uppercase *)
    "0x1234567890AbCdEf1234567890aBcDeF12345678";  (* mixed case *)
    "0x0000000000000000000000000000000000000000";  (* all zeros *)
    "0xffffffffffffffffffffffffffffffffffffffff";  (* all f's *)
  ] in
  List.iter
    (fun addr -> Alcotest.(check bool) addr true (is_valid_address addr))
    valid_addresses

let test_address_invalid () =
  let invalid_cases = [
    ("", "empty string");
    ("0x123456789", "too short");
    ("0x1234567890abcdef1234567890abcdef1234567890", "too long");
    ("1234567890abcdef1234567890abcdef12345678", "no 0x prefix");
    ("1x1234567890abcdef1234567890abcdef12345678", "wrong prefix 1x");
    ("0X1234567890abcdef1234567890abcdef12345678", "wrong case 0X prefix");
    ("0xGGGGGGGGGGabcdef1234567890abcdef12345678", "non-hex characters");
    ("0x1234567890abcdef1234567890abcdef1234567 ", "trailing space");
    (" 0x1234567890abcdef1234567890abcdef12345678", "leading space");
  ] in
  List.iter
    (fun (addr, desc) ->
      Alcotest.(check bool) desc false (is_valid_address addr))
    invalid_cases

(** {1 Hash64 Validation Tests} *)

let test_hash64_valid () =
  let valid_hashes = [
    "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";  (* lowercase *)
    "0x1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF";  (* uppercase *)
    "0x0000000000000000000000000000000000000000000000000000000000000000";  (* all zeros *)
  ] in
  List.iter
    (fun hash -> Alcotest.(check bool) hash true (is_valid_hash64 hash))
    valid_hashes

let test_hash64_invalid () =
  let invalid_cases = [
    ("", "empty string");
    ("0x1234567890abcdef", "too short");
    ("1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef", "no prefix");
    ("0X1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef", "wrong case 0X");
    ("0xGGGGGGGGGGabcdef1234567890abcdef1234567890abcdef1234567890abcdef", "non-hex");
  ] in
  List.iter
    (fun (hash, desc) ->
      Alcotest.(check bool) desc false (is_valid_hash64 hash))
    invalid_cases

(** {1 Side Enum Tests} *)

let test_side_to_string () =
  Test_utils.test_string_conversions
    ~to_string:string_of_side
    [(BUY, "BUY"); (SELL, "SELL")]

let test_side_roundtrip () =
  Test_utils.test_roundtrip
    ~to_json:yojson_of_side
    ~of_json:side_of_yojson
    ~equal:equal_side
    ~to_string:string_of_side
    [BUY; SELL]

(** {1 Activity Type Enum Tests} *)

let test_activity_type_to_string () =
  Test_utils.test_string_conversions
    ~to_string:string_of_activity_type
    [
      (TRADE, "TRADE");
      (SPLIT, "SPLIT");
      (MERGE, "MERGE");
      (REDEEM, "REDEEM");
      (REWARD, "REWARD");
      (CONVERSION, "CONVERSION");
    ]

let test_activity_type_roundtrip () =
  Test_utils.test_roundtrip
    ~to_json:yojson_of_activity_type
    ~of_json:activity_type_of_yojson
    ~equal:equal_activity_type
    ~to_string:string_of_activity_type
    [TRADE; SPLIT; MERGE; REDEEM; REWARD; CONVERSION]

(** {1 Validating Deserializer Tests} *)

let test_address_of_yojson_exn_valid () =
  let json = `String "0x1234567890abcdef1234567890abcdef12345678" in
  let result = address_of_yojson_exn json in
  Alcotest.(check string) "parses valid" "0x1234567890abcdef1234567890abcdef12345678" result

let test_address_of_yojson_exn_invalid () =
  let json = `String "invalid" in
  try
    let _ = address_of_yojson_exn json in
    Alcotest.fail "expected exception"
  with Invalid_address addr ->
    Alcotest.(check string) "raises with address" "invalid" addr

let test_hash64_of_yojson_exn_valid () =
  let json = `String "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" in
  let result = hash64_of_yojson_exn json in
  Alcotest.(check string) "parses valid" "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" result

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
  | Ok addr -> Alcotest.(check string) "returns Ok" "0x1234567890abcdef1234567890abcdef12345678" addr
  | Error _ -> Alcotest.fail "expected Ok"

let test_address_of_yojson_result_invalid () =
  let json = `String "invalid" in
  match address_of_yojson_result json with
  | Ok _ -> Alcotest.fail "expected Error"
  | Error msg -> Alcotest.(check bool) "returns Error" true (String.length msg > 0)

let test_hash64_of_yojson_result_valid () =
  let json = `String "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" in
  match hash64_of_yojson_result json with
  | Ok hash -> Alcotest.(check string) "returns Ok" "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" hash
  | Error _ -> Alcotest.fail "expected Ok"

let test_hash64_of_yojson_result_invalid () =
  let json = `String "invalid" in
  match hash64_of_yojson_result json with
  | Ok _ -> Alcotest.fail "expected Error"
  | Error msg -> Alcotest.(check bool) "returns Error" true (String.length msg > 0)

(** {1 Health Response Tests} *)

let test_health_response_with_data () =
  let json = Yojson.Safe.from_string {|{"data": "ok"}|} in
  let result = health_response_of_yojson json in
  Alcotest.(check (option string)) "has data" (Some "ok") result.data

let test_health_response_without_data () =
  let json = Yojson.Safe.from_string {|{}|} in
  let result = health_response_of_yojson json in
  Alcotest.(check (option string)) "no data" None result.data

let test_health_response_roundtrip () =
  let original = { data = Some "healthy" } in
  let json = yojson_of_health_response original in
  let result = health_response_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_health_response original result)

(** {1 Position Record Tests} *)

let test_position_empty () =
  let pos = empty_position in
  Alcotest.(check (option string)) "proxy_wallet is None" None pos.proxy_wallet;
  Alcotest.(check (option string)) "asset is None" None pos.asset;
  Alcotest.(check (option bool)) "redeemable is None" None pos.redeemable

let test_position_roundtrip () =
  let pos = { empty_position with
    proxy_wallet = Some "0x1234567890abcdef1234567890abcdef12345678";
    size = Some 100.5;
    redeemable = Some true;
    title = Some "Test Market";
  } in
  let json = yojson_of_position pos in
  let result = position_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_position pos result)

let test_position_partial_json () =
  let json = Yojson.Safe.from_string {|{"size": 50.0, "title": "Partial"}|} in
  let result = position_of_yojson json in
  Alcotest.(check option_float) "has size" (Some 50.0) result.size;
  Alcotest.(check (option string)) "has title" (Some "Partial") result.title;
  Alcotest.(check (option string)) "no asset" None result.asset

(** {1 Trade Record Tests} *)

let test_trade_empty () =
  let trade = empty_trade in
  Alcotest.(check (option string)) "proxy_wallet is None" None trade.proxy_wallet;
  Alcotest.(check bool) "side is None" true (Option.is_none trade.side)

let test_trade_roundtrip () =
  let trade = { empty_trade with
    side = Some BUY;
    size = Some 10.0;
    price = Some 0.75;
    timestamp = Some 1700000000L;
  } in
  let json = yojson_of_trade trade in
  let result = trade_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_trade trade result)

(** {1 Activity Record Tests} *)

let test_activity_empty () =
  let activity = empty_activity in
  Alcotest.(check bool) "activity_type is None" true (Option.is_none activity.activity_type)

let test_activity_roundtrip () =
  let activity = { empty_activity with
    activity_type = Some TRADE;
    side = Some SELL;
    size = Some 5.0;
    usdc_size = Some 3.75;
  } in
  let json = yojson_of_activity activity in
  let result = activity_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_activity activity result)

(** {1 Holder Record Tests} *)

let test_holder_empty () =
  let holder = empty_holder in
  Alcotest.(check (option string)) "proxy_wallet is None" None holder.proxy_wallet

let test_holder_roundtrip () =
  let holder = { empty_holder with
    pseudonym = Some "trader123";
    amount = Some 1000.0;
    display_username_public = Some true;
  } in
  let json = yojson_of_holder holder in
  let result = holder_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_holder holder result)

(** {1 Other Record Tests} *)

let test_value_roundtrip () =
  let v = { user = Some "0x1234567890abcdef1234567890abcdef12345678"; value = Some 5000.0 } in
  let json = yojson_of_value v in
  let result = value_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_value v result)

let test_open_interest_roundtrip () =
  let oi : open_interest = {
    market = Some "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
    value = Some 10000.0
  } in
  let json = yojson_of_open_interest oi in
  let result = open_interest_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_open_interest oi result)

let test_leaderboard_entry_roundtrip () =
  let entry = {
    rank = Some "1";
    builder = Some "ExampleBuilder";
    volume = Some 1000000.0;
    active_users = Some 500;
    verified = Some true;
    builder_logo = Some "https://example.com/logo.png";
  } in
  let json = yojson_of_leaderboard_entry entry in
  let result = leaderboard_entry_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_leaderboard_entry entry result)

let test_trader_leaderboard_entry_roundtrip () =
  let entry = { empty_trader_leaderboard_entry with
    rank = Some "1";
    user_name = Some "TopTrader";
    vol = Some 500000.0;
    pnl = Some 50000.0;
    verified_badge = Some true;
  } in
  let json = yojson_of_trader_leaderboard_entry entry in
  let result = trader_leaderboard_entry_of_yojson json in
  Alcotest.(check bool) "roundtrip" true (equal_trader_leaderboard_entry entry result)

(** {1 Test Suite} *)

let tests =
  [
    ("address validation", [
      ("valid addresses", `Quick, test_address_valid);
      ("invalid addresses", `Quick, test_address_invalid);
    ]);
    ("hash64 validation", [
      ("valid hashes", `Quick, test_hash64_valid);
      ("invalid hashes", `Quick, test_hash64_invalid);
    ]);
    ("side enum", [
      ("to_string", `Quick, test_side_to_string);
      ("roundtrip", `Quick, test_side_roundtrip);
    ]);
    ("activity_type enum", [
      ("to_string", `Quick, test_activity_type_to_string);
      ("roundtrip", `Quick, test_activity_type_roundtrip);
    ]);
    ("validating deserializers", [
      ("address_of_yojson_exn valid", `Quick, test_address_of_yojson_exn_valid);
      ("address_of_yojson_exn invalid", `Quick, test_address_of_yojson_exn_invalid);
      ("hash64_of_yojson_exn valid", `Quick, test_hash64_of_yojson_exn_valid);
      ("hash64_of_yojson_exn invalid", `Quick, test_hash64_of_yojson_exn_invalid);
      ("address_of_yojson_result valid", `Quick, test_address_of_yojson_result_valid);
      ("address_of_yojson_result invalid", `Quick, test_address_of_yojson_result_invalid);
      ("hash64_of_yojson_result valid", `Quick, test_hash64_of_yojson_result_valid);
      ("hash64_of_yojson_result invalid", `Quick, test_hash64_of_yojson_result_invalid);
    ]);
    ("health_response", [
      ("with data", `Quick, test_health_response_with_data);
      ("without data", `Quick, test_health_response_without_data);
      ("roundtrip", `Quick, test_health_response_roundtrip);
    ]);
    ("position", [
      ("empty", `Quick, test_position_empty);
      ("roundtrip", `Quick, test_position_roundtrip);
      ("partial json", `Quick, test_position_partial_json);
    ]);
    ("trade", [
      ("empty", `Quick, test_trade_empty);
      ("roundtrip", `Quick, test_trade_roundtrip);
    ]);
    ("activity", [
      ("empty", `Quick, test_activity_empty);
      ("roundtrip", `Quick, test_activity_roundtrip);
    ]);
    ("holder", [
      ("empty", `Quick, test_holder_empty);
      ("roundtrip", `Quick, test_holder_roundtrip);
    ]);
    ("other types", [
      ("value roundtrip", `Quick, test_value_roundtrip);
      ("open_interest roundtrip", `Quick, test_open_interest_roundtrip);
      ("leaderboard_entry roundtrip", `Quick, test_leaderboard_entry_roundtrip);
      ("trader_leaderboard_entry roundtrip", `Quick, test_trader_leaderboard_entry_roundtrip);
    ]);
  ]
