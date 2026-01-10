(** Unit tests for Bridge_api.Types module *)

open Polymarket.Bridge
module P = Polymarket.Primitives

(** {1 Helper Functions} *)

let make_address s =
  match P.Address.make s with Ok a -> Some a | Error _ -> None

let check_address_option =
  Alcotest.testable
    (fun fmt -> function
      | Some a -> Format.fprintf fmt "Some %s" (P.Address.to_string a)
      | None -> Format.fprintf fmt "None")
    (fun a b ->
      match (a, b) with
      | Some x, Some y -> P.Address.equal x y
      | None, None -> true
      | _ -> false)

(** {1 Token JSON Tests} *)

let test_token_json_roundtrip () =
  let t =
    {
      name = Some "USD Coin";
      symbol = Some "USDC";
      address = Some "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
      decimals = Some 6;
    }
  in
  let json = yojson_of_token t in
  let parsed = token_of_yojson json in
  Alcotest.(check bool) "token roundtrip" true (equal_token t parsed)

let test_token_json_with_defaults () =
  let json = `Assoc [] in
  let t = token_of_yojson json in
  Alcotest.(check (option string)) "name is None" None t.name;
  Alcotest.(check (option string)) "symbol is None" None t.symbol;
  Alcotest.(check (option string)) "address is None" None t.address;
  Alcotest.(check (option int)) "decimals is None" None t.decimals

(** {1 Supported Asset JSON Tests} *)

let test_supported_asset_json_roundtrip () =
  let token =
    {
      name = Some "USD Coin";
      symbol = Some "USDC";
      address = Some "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
      decimals = Some 6;
    }
  in
  let asset =
    {
      chain_id = Some "1";
      chain_name = Some "Ethereum";
      token = Some token;
      min_checkout_usd = Some 45.0;
    }
  in
  let json = yojson_of_supported_asset asset in
  let parsed = supported_asset_of_yojson json in
  Alcotest.(check bool)
    "supported_asset roundtrip" true
    (equal_supported_asset asset parsed)

let test_supported_asset_json_keys () =
  let json =
    `Assoc
      [
        ("chainId", `String "137");
        ("chainName", `String "Polygon");
        ("minCheckoutUsd", `Float 10.0);
      ]
  in
  let asset = supported_asset_of_yojson json in
  Alcotest.(check (option string)) "chain_id" (Some "137") asset.chain_id;
  Alcotest.(check (option string))
    "chain_name" (Some "Polygon") asset.chain_name;
  Alcotest.(check (option (float 0.001)))
    "min_checkout_usd" (Some 10.0) asset.min_checkout_usd

(** {1 Deposit Addresses JSON Tests} *)

let test_deposit_addresses_json_roundtrip () =
  let addrs =
    {
      evm = make_address "0x23566f8b2E82aDfCf01846E54899d110e97AC053";
      svm = Some "CrvTBvzryYxBHbWu2TiQpcqD5M7Le7iBKzVmEj3f36Jb";
      btc = Some "bc1q8eau83qffxcj8ht4hsjdza3lha9r3egfqysj3g";
    }
  in
  let json = yojson_of_deposit_addresses addrs in
  let parsed = deposit_addresses_of_yojson json in
  Alcotest.(check bool)
    "deposit_addresses roundtrip" true
    (equal_deposit_addresses addrs parsed)

let test_deposit_addresses_partial () =
  (* Use a valid 42-char address for parsing *)
  let valid_addr = "0x23566f8b2E82aDfCf01846E54899d110e97AC053" in
  let json = `Assoc [ ("evm", `String valid_addr) ] in
  let addrs = deposit_addresses_of_yojson json in
  Alcotest.(check check_address_option)
    "evm" (make_address valid_addr) addrs.evm;
  Alcotest.(check (option string)) "svm is None" None addrs.svm;
  Alcotest.(check (option string)) "btc is None" None addrs.btc

(** {1 Deposit Response JSON Tests} *)

let test_deposit_response_json_roundtrip () =
  let addrs =
    {
      evm = make_address "0x23566f8b2E82aDfCf01846E54899d110e97AC053";
      svm = Some "CrvTBvzryYxBHbWu2TiQpcqD5M7Le7iBKzVmEj3f36Jb";
      btc = Some "bc1q8eau83qffxcj8ht4hsjdza3lha9r3egfqysj3g";
    }
  in
  let resp =
    {
      address = Some addrs;
      note =
        Some
          "Only certain chains and tokens are supported. See /supported-assets \
           for details.";
    }
  in
  let json = yojson_of_deposit_response resp in
  let parsed = deposit_response_of_yojson json in
  Alcotest.(check bool)
    "deposit_response roundtrip" true
    (equal_deposit_response resp parsed)

let test_deposit_response_json_with_note () =
  let valid_addr = "0xa41249c581990c31fb2a0dfc4417ede58e0de774" in
  let json =
    `Assoc
      [
        ( "address",
          `Assoc
            [
              ("evm", `String valid_addr);
              ("svm", `String "solana123");
              ("btc", `String "bc1abc");
            ] );
        ("note", `String "Test note");
      ]
  in
  let resp = deposit_response_of_yojson json in
  Alcotest.(check (option string)) "note" (Some "Test note") resp.note;
  match resp.address with
  | Some addrs ->
      Alcotest.(check check_address_option)
        "evm" (make_address valid_addr) addrs.evm;
      Alcotest.(check (option string)) "svm" (Some "solana123") addrs.svm;
      Alcotest.(check (option string)) "btc" (Some "bc1abc") addrs.btc
  | None -> Alcotest.fail "Expected address to be Some"

(** {1 Deposit Response Edge Case Tests} *)

let test_deposit_response_null_address () =
  let json =
    `Assoc [ ("address", `Null); ("note", `String "Error occurred") ]
  in
  let resp = deposit_response_of_yojson json in
  Alcotest.(check (option string))
    "note present" (Some "Error occurred") resp.note;
  Alcotest.(check bool) "address is None" true (resp.address = None)

let test_deposit_response_missing_address () =
  let json = `Assoc [ ("note", `String "Only note") ] in
  let resp = deposit_response_of_yojson json in
  Alcotest.(check (option string)) "note present" (Some "Only note") resp.note;
  Alcotest.(check bool) "address is None" true (resp.address = None)

(** {1 Supported Assets Response JSON Tests} *)

let test_supported_assets_response_json () =
  let token =
    {
      name = Some "USDC";
      symbol = Some "USDC";
      address = None;
      decimals = Some 6;
    }
  in
  let asset =
    {
      chain_id = Some "1";
      chain_name = Some "Ethereum";
      token = Some token;
      min_checkout_usd = Some 45.0;
    }
  in
  let resp = { supported_assets = [ asset ]; note = Some "Test note" } in
  let json = yojson_of_supported_assets_response resp in
  let parsed = supported_assets_response_of_yojson json in
  Alcotest.(check int)
    "supported_assets count" 1
    (List.length parsed.supported_assets)

let test_supported_assets_response_empty () =
  let json = `Assoc [ ("supportedAssets", `List []) ] in
  let resp = supported_assets_response_of_yojson json in
  Alcotest.(check int) "empty list" 0 (List.length resp.supported_assets)

let test_supported_assets_response_missing_field () =
  let json = `Assoc [] in
  let resp = supported_assets_response_of_yojson json in
  Alcotest.(check int)
    "default empty list" 0
    (List.length resp.supported_assets)

(** {1 Test Suite} *)

let tests =
  [
    ( "token",
      [
        ("JSON roundtrip", `Quick, test_token_json_roundtrip);
        ("JSON with defaults", `Quick, test_token_json_with_defaults);
      ] );
    ( "supported_asset",
      [
        ("JSON roundtrip", `Quick, test_supported_asset_json_roundtrip);
        ("JSON keys", `Quick, test_supported_asset_json_keys);
      ] );
    ( "deposit_addresses",
      [
        ("JSON roundtrip", `Quick, test_deposit_addresses_json_roundtrip);
        ("partial", `Quick, test_deposit_addresses_partial);
      ] );
    ( "deposit_response",
      [
        ("JSON roundtrip", `Quick, test_deposit_response_json_roundtrip);
        ("JSON with note", `Quick, test_deposit_response_json_with_note);
        ("null address", `Quick, test_deposit_response_null_address);
        ("missing address", `Quick, test_deposit_response_missing_address);
      ] );
    ( "supported_assets_response",
      [
        ("JSON", `Quick, test_supported_assets_response_json);
        ("empty list", `Quick, test_supported_assets_response_empty);
        ("missing field", `Quick, test_supported_assets_response_missing_field);
      ] );
  ]
