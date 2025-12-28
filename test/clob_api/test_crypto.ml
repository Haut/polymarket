(** Tests for the Crypto module. *)

module Crypto = Polymarket_common.Crypto

(** {1 Test Helpers} *)

let check_string msg expected actual =
  Alcotest.(check string) msg expected actual

let check_starts_with msg prefix actual =
  Alcotest.(check bool)
    msg true
    (String.length actual >= String.length prefix
    && String.sub actual 0 (String.length prefix) = prefix)

(** {1 Keccak256 Tests} *)

let test_keccak256_empty () =
  (* keccak256("") = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 *)
  let hash = Crypto.keccak256 "" in
  check_string "empty string hash"
    "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470" hash

let test_keccak256_hello () =
  (* keccak256("hello") = 0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8 *)
  let hash = Crypto.keccak256 "hello" in
  check_string "hello hash"
    "0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8" hash

(** {1 HMAC-SHA256 Tests} *)

let test_hmac_sha256 () =
  (* Test vector from RFC 4231 *)
  let key = String.make 20 '\x0b' in
  let data = "Hi There" in
  let result = Crypto.hmac_sha256 ~key data in
  (* Expected: b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7 *)
  let expected_hex =
    "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"
  in
  let result_hex =
    let (`Hex h) = Hex.of_string result in
    h
  in
  check_string "HMAC-SHA256" expected_hex result_hex

(** {1 L2 Request Signing Tests} *)

let test_sign_l2_request () =
  let secret = Base64.encode_exn "test-secret-key!" in
  let timestamp = "1234567890000" in
  let method_ = "GET" in
  let path = "/orders" in
  let body = "" in
  let signature =
    Crypto.sign_l2_request ~secret ~timestamp ~method_ ~path ~body
  in
  (* Signature should be base64 encoded *)
  Alcotest.(check bool)
    "is valid base64" true
    (try
       ignore (Base64.decode_exn signature);
       true
     with _ -> false)

(** {1 Private Key to Address Tests} *)

let test_private_key_to_address () =
  (* Well-known test vector *)
  (* Private key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 *)
  (* Expected address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 *)
  let private_key =
    "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
  in
  let address = Crypto.private_key_to_address private_key in
  (* Address should be lowercase with 0x prefix *)
  check_starts_with "has 0x prefix" "0x" address;
  Alcotest.(check int) "address length" 42 (String.length address);
  (* Check the expected address (lowercase) *)
  check_string "address value" "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
    address

(** {1 EIP-712 Signing Tests} *)

let test_sign_clob_auth_message () =
  let private_key =
    "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
  in
  let address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" in
  let timestamp = "1234567890000" in
  let nonce = 0 in
  let signature =
    Crypto.sign_clob_auth_message ~private_key ~address ~timestamp ~nonce
  in
  (* Signature should be hex with 0x prefix and 65 bytes (130 hex chars + 2 for 0x) *)
  check_starts_with "has 0x prefix" "0x" signature;
  Alcotest.(check int) "signature length" 132 (String.length signature)

(** {1 Timestamp Tests} *)

let test_current_timestamp_ms () =
  let ts = Crypto.current_timestamp_ms () in
  (* Should be a numeric string *)
  Alcotest.(check bool)
    "is numeric" true
    (try
       ignore (float_of_string ts);
       true
     with _ -> false);
  (* Should be roughly current time in ms (13+ digits) *)
  Alcotest.(check bool) "reasonable length" true (String.length ts >= 13)

(** {1 Test Suite} *)

let keccak256_tests =
  [
    ("empty string", `Quick, test_keccak256_empty);
    ("hello", `Quick, test_keccak256_hello);
  ]

let hmac_tests = [ ("RFC 4231 test vector", `Quick, test_hmac_sha256) ]
let l2_signing_tests = [ ("sign request", `Quick, test_sign_l2_request) ]

let address_tests =
  [ ("derive from private key", `Quick, test_private_key_to_address) ]

let eip712_tests =
  [ ("sign auth message", `Quick, test_sign_clob_auth_message) ]

let timestamp_tests =
  [ ("current timestamp", `Quick, test_current_timestamp_ms) ]

let tests =
  [
    ("Clob_api.Crypto: keccak256", keccak256_tests);
    ("Clob_api.Crypto: HMAC-SHA256", hmac_tests);
    ("Clob_api.Crypto: L2 signing", l2_signing_tests);
    ("Clob_api.Crypto: address derivation", address_tests);
    ("Clob_api.Crypto: EIP-712 signing", eip712_tests);
    ("Clob_api.Crypto: timestamp", timestamp_tests);
  ]
