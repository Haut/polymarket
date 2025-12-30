(** WebSocket frame encoding and decoding (RFC 6455).

    This module implements the binary frame format for WebSocket messages.
    Client frames must be masked; server frames are unmasked. *)

(** Frame opcodes *)
module Opcode = struct
  type t = Continuation | Text | Binary | Close | Ping | Pong | Other of int

  let to_int = function
    | Continuation -> 0
    | Text -> 1
    | Binary -> 2
    | Close -> 8
    | Ping -> 9
    | Pong -> 10
    | Other n -> n

  let of_int = function
    | 0 -> Continuation
    | 1 -> Text
    | 2 -> Binary
    | 8 -> Close
    | 9 -> Ping
    | 10 -> Pong
    | n -> Other n

  let is_control = function Close | Ping | Pong -> true | _ -> false
end

(** Close status codes *)
module Close_code = struct
  type t =
    | Normal
    | Going_away
    | Protocol_error
    | Unsupported_data
    | No_status
    | Abnormal
    | Invalid_payload
    | Policy_violation
    | Message_too_big
    | Missing_extension
    | Internal_error
    | Other of int

  let to_int = function
    | Normal -> 1000
    | Going_away -> 1001
    | Protocol_error -> 1002
    | Unsupported_data -> 1003
    | No_status -> 1005
    | Abnormal -> 1006
    | Invalid_payload -> 1007
    | Policy_violation -> 1008
    | Message_too_big -> 1009
    | Missing_extension -> 1010
    | Internal_error -> 1011
    | Other n -> n

  let of_int = function
    | 1000 -> Normal
    | 1001 -> Going_away
    | 1002 -> Protocol_error
    | 1003 -> Unsupported_data
    | 1005 -> No_status
    | 1006 -> Abnormal
    | 1007 -> Invalid_payload
    | 1008 -> Policy_violation
    | 1009 -> Message_too_big
    | 1010 -> Missing_extension
    | 1011 -> Internal_error
    | n -> Other n
end

type t = { fin : bool; opcode : Opcode.t; payload : string }
(** A WebSocket frame *)

(** Generate a random 4-byte masking key *)
let generate_mask () =
  let key = Bytes.create 4 in
  for i = 0 to 3 do
    Bytes.set key i (Char.chr (Random.int 256))
  done;
  Bytes.to_string key

(** Apply XOR mask to payload *)
let apply_mask ~key payload =
  let len = String.length payload in
  let result = Bytes.create len in
  for i = 0 to len - 1 do
    let masked = Char.code payload.[i] lxor Char.code key.[i mod 4] in
    Bytes.set result i (Char.chr masked)
  done;
  Bytes.to_string result

(** Encode a frame for sending (client must mask) *)
let encode ~mask frame =
  let payload_len = String.length frame.payload in
  let buf = Buffer.create (14 + payload_len) in

  (* First byte: FIN + opcode *)
  let byte0 =
    (if frame.fin then 0x80 else 0x00) lor Opcode.to_int frame.opcode
  in
  Buffer.add_char buf (Char.chr byte0);

  (* Second byte: MASK + payload length *)
  let mask_bit = if mask then 0x80 else 0x00 in
  if payload_len < 126 then
    Buffer.add_char buf (Char.chr (mask_bit lor payload_len))
  else if payload_len < 65536 then begin
    Buffer.add_char buf (Char.chr (mask_bit lor 126));
    Buffer.add_char buf (Char.chr (payload_len lsr 8));
    Buffer.add_char buf (Char.chr (payload_len land 0xFF))
  end
  else begin
    Buffer.add_char buf (Char.chr (mask_bit lor 127));
    (* 64-bit length - for simplicity, assume payload < 2^31 *)
    for i = 7 downto 0 do
      let shift = i * 8 in
      if shift >= 32 then Buffer.add_char buf (Char.chr 0)
      else Buffer.add_char buf (Char.chr ((payload_len lsr shift) land 0xFF))
    done
  end;

  (* Masking key and masked payload (if mask) *)
  if mask then begin
    let key = generate_mask () in
    Buffer.add_string buf key;
    Buffer.add_string buf (apply_mask ~key frame.payload)
  end
  else Buffer.add_string buf frame.payload;

  Buffer.contents buf

(** Read exactly n bytes from a flow *)
let read_exactly flow n =
  let buf = Cstruct.create n in
  let rec loop off remaining =
    if remaining = 0 then ()
    else begin
      let got = Eio.Flow.single_read flow (Cstruct.sub buf off remaining) in
      loop (off + got) (remaining - got)
    end
  in
  loop 0 n;
  Cstruct.to_string buf

(** Decode a frame from a flow *)
let decode flow =
  (* Read first two bytes *)
  let header = read_exactly flow 2 in
  let byte0 = Char.code header.[0] in
  let byte1 = Char.code header.[1] in

  let fin = byte0 land 0x80 <> 0 in
  let opcode = Opcode.of_int (byte0 land 0x0F) in
  let masked = byte1 land 0x80 <> 0 in
  let len0 = byte1 land 0x7F in

  (* Extended payload length *)
  let payload_len =
    if len0 < 126 then len0
    else if len0 = 126 then begin
      let ext = read_exactly flow 2 in
      (Char.code ext.[0] lsl 8) lor Char.code ext.[1]
    end
    else begin
      let ext = read_exactly flow 8 in
      (* Assume payload < 2^31 for simplicity *)
      let len = ref 0 in
      for i = 0 to 7 do
        len := (!len lsl 8) lor Char.code ext.[i]
      done;
      !len
    end
  in

  (* Masking key (if present) *)
  let mask_key = if masked then Some (read_exactly flow 4) else None in

  (* Payload *)
  let payload = read_exactly flow payload_len in
  let payload =
    match mask_key with Some key -> apply_mask ~key payload | None -> payload
  in

  { fin; opcode; payload }

(** Create a text frame *)
let text ?(fin = true) payload = { fin; opcode = Text; payload }

(** Create a binary frame *)
let binary ?(fin = true) payload = { fin; opcode = Binary; payload }

(** Create a ping frame *)
let ping ?(payload = "") () = { fin = true; opcode = Ping; payload }

(** Create a pong frame *)
let pong ?(payload = "") () = { fin = true; opcode = Pong; payload }

(** Create a close frame *)
let close ?(code = Close_code.Normal) ?(reason = "") () =
  let code_int = Close_code.to_int code in
  let payload =
    if code = Close_code.No_status then ""
    else
      let buf = Buffer.create (2 + String.length reason) in
      Buffer.add_char buf (Char.chr (code_int lsr 8));
      Buffer.add_char buf (Char.chr (code_int land 0xFF));
      Buffer.add_string buf reason;
      Buffer.contents buf
  in
  { fin = true; opcode = Close; payload }
