(** Unit tests for WebSocket frame encoding/decoding *)

open Websocket.Frame

(** {1 Opcode Tests} *)

let test_opcode_roundtrip () =
  let opcodes =
    [
      Opcode.Continuation;
      Opcode.Text;
      Opcode.Binary;
      Opcode.Close;
      Opcode.Ping;
      Opcode.Pong;
    ]
  in
  List.iter
    (fun opcode ->
      let i = Opcode.to_int opcode in
      let result = Opcode.of_int i in
      Alcotest.(check bool)
        (Printf.sprintf "Opcode %d roundtrip" i)
        true (opcode = result))
    opcodes

let test_opcode_values () =
  Alcotest.(check int) "Continuation" 0 (Opcode.to_int Opcode.Continuation);
  Alcotest.(check int) "Text" 1 (Opcode.to_int Opcode.Text);
  Alcotest.(check int) "Binary" 2 (Opcode.to_int Opcode.Binary);
  Alcotest.(check int) "Close" 8 (Opcode.to_int Opcode.Close);
  Alcotest.(check int) "Ping" 9 (Opcode.to_int Opcode.Ping);
  Alcotest.(check int) "Pong" 10 (Opcode.to_int Opcode.Pong)

let test_opcode_is_control () =
  Alcotest.(check bool) "Text not control" false (Opcode.is_control Opcode.Text);
  Alcotest.(check bool)
    "Binary not control" false
    (Opcode.is_control Opcode.Binary);
  Alcotest.(check bool) "Close is control" true (Opcode.is_control Opcode.Close);
  Alcotest.(check bool) "Ping is control" true (Opcode.is_control Opcode.Ping);
  Alcotest.(check bool) "Pong is control" true (Opcode.is_control Opcode.Pong)

(** {1 Close Code Tests} *)

let test_close_code_roundtrip () =
  let codes =
    [
      Close_code.Normal;
      Close_code.Going_away;
      Close_code.Protocol_error;
      Close_code.Unsupported_data;
      Close_code.No_status;
      Close_code.Abnormal;
      Close_code.Invalid_payload;
      Close_code.Policy_violation;
      Close_code.Message_too_big;
      Close_code.Missing_extension;
      Close_code.Internal_error;
    ]
  in
  List.iter
    (fun code ->
      let i = Close_code.to_int code in
      let result = Close_code.of_int i in
      Alcotest.(check bool)
        (Printf.sprintf "Close_code %d roundtrip" i)
        true (code = result))
    codes

let test_close_code_values () =
  Alcotest.(check int) "Normal" 1000 (Close_code.to_int Close_code.Normal);
  Alcotest.(check int)
    "Going_away" 1001
    (Close_code.to_int Close_code.Going_away);
  Alcotest.(check int)
    "Protocol_error" 1002
    (Close_code.to_int Close_code.Protocol_error);
  Alcotest.(check int)
    "Internal_error" 1011
    (Close_code.to_int Close_code.Internal_error)

(** {1 Mask Tests} *)

let test_apply_mask_identity () =
  (* Applying mask twice should return original *)
  let key = "abcd" in
  let payload = "Hello, WebSocket!" in
  let masked = apply_mask ~key payload in
  let unmasked = apply_mask ~key masked in
  Alcotest.(check string) "double mask is identity" payload unmasked

let test_apply_mask_xor () =
  (* XOR with all zeros should be identity *)
  let key = "\x00\x00\x00\x00" in
  let payload = "test" in
  let result = apply_mask ~key payload in
  Alcotest.(check string) "zero key is identity" payload result

(** {1 Frame Creation Tests} *)

let test_text_frame () =
  let frame = text "hello" in
  Alcotest.(check bool) "fin" true frame.fin;
  Alcotest.(check int) "opcode" 1 (Opcode.to_int frame.opcode);
  Alcotest.(check string) "payload" "hello" frame.payload

let test_ping_frame () =
  let frame = ping () in
  Alcotest.(check bool) "fin" true frame.fin;
  Alcotest.(check int) "opcode" 9 (Opcode.to_int frame.opcode);
  Alcotest.(check string) "payload" "" frame.payload

let test_pong_frame () =
  let frame = pong ~payload:"data" () in
  Alcotest.(check bool) "fin" true frame.fin;
  Alcotest.(check int) "opcode" 10 (Opcode.to_int frame.opcode);
  Alcotest.(check string) "payload" "data" frame.payload

let test_close_frame () =
  let frame = close () in
  Alcotest.(check bool) "fin" true frame.fin;
  Alcotest.(check int) "opcode" 8 (Opcode.to_int frame.opcode);
  (* Payload should have 2-byte status code *)
  Alcotest.(check bool) "has status" true (String.length frame.payload >= 2)

(** {1 Encode Tests} *)

let test_encode_small_payload () =
  let frame = text "hi" in
  let encoded = encode ~mask:false frame in
  (* First byte: FIN + TEXT opcode = 0x81 *)
  Alcotest.(check int) "byte0" 0x81 (Char.code encoded.[0]);
  (* Second byte: no mask + length 2 = 0x02 *)
  Alcotest.(check int) "byte1" 0x02 (Char.code encoded.[1]);
  (* Payload follows directly *)
  Alcotest.(check string) "payload" "hi" (String.sub encoded 2 2)

let test_encode_with_mask () =
  let frame = text "test" in
  let encoded = encode ~mask:true frame in
  (* First byte: FIN + TEXT opcode = 0x81 *)
  Alcotest.(check int) "byte0" 0x81 (Char.code encoded.[0]);
  (* Second byte: mask bit + length 4 = 0x84 *)
  Alcotest.(check int) "byte1" 0x84 (Char.code encoded.[1]);
  (* Total length: 2 header + 4 mask key + 4 payload = 10 *)
  Alcotest.(check int) "total length" 10 (String.length encoded)

(** {1 Test Suite} *)

let tests =
  [
    ( "Opcode",
      [
        ("roundtrip", `Quick, test_opcode_roundtrip);
        ("values", `Quick, test_opcode_values);
        ("is_control", `Quick, test_opcode_is_control);
      ] );
    ( "Close_code",
      [
        ("roundtrip", `Quick, test_close_code_roundtrip);
        ("values", `Quick, test_close_code_values);
      ] );
    ( "apply_mask",
      [
        ("identity", `Quick, test_apply_mask_identity);
        ("xor with zero", `Quick, test_apply_mask_xor);
      ] );
    ( "frame creation",
      [
        ("text", `Quick, test_text_frame);
        ("ping", `Quick, test_ping_frame);
        ("pong", `Quick, test_pong_frame);
        ("close", `Quick, test_close_frame);
      ] );
    ( "encode",
      [
        ("small payload", `Quick, test_encode_small_payload);
        ("with mask", `Quick, test_encode_with_mask);
      ] );
  ]
