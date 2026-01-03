(** WebSocket handshake implementation (RFC 6455 Section 4).

    Performs HTTP/1.1 Upgrade handshake directly over a TLS flow. *)

let src = Logs.Src.create "polymarket.wss.handshake" ~doc:"WebSocket handshake"

module Log = (val Logs.src_log src : Logs.LOG)

(** WebSocket GUID for Sec-WebSocket-Accept calculation *)
let websocket_guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

(** Generate a random 16-byte nonce and base64 encode it *)
let generate_key () =
  let bytes = Bytes.create 16 in
  for i = 0 to 15 do
    Bytes.set bytes i (Char.chr (Random.int 256))
  done;
  Base64.encode_string (Bytes.to_string bytes)

(** Calculate expected Sec-WebSocket-Accept value *)
let expected_accept key =
  let concat = key ^ websocket_guid in
  let hash = Digestif.SHA1.(digest_string concat |> to_raw_string) in
  Base64.encode_string hash

(** Read a line from flow (up to \r\n) *)
let read_line flow =
  let buf = Buffer.create 128 in
  let rec loop prev_cr =
    let byte_buf = Cstruct.create 1 in
    let _ = Eio.Flow.single_read flow byte_buf in
    let c = Cstruct.get_char byte_buf 0 in
    if prev_cr && c = '\n' then
      (* Remove trailing \r and return *)
      let s = Buffer.contents buf in
      if String.length s > 0 && s.[String.length s - 1] = '\r' then
        String.sub s 0 (String.length s - 1)
      else s
    else begin
      Buffer.add_char buf c;
      loop (c = '\r')
    end
  in
  loop false

(** Parse HTTP response status line *)
let parse_status_line line =
  (* HTTP/1.1 101 Switching Protocols *)
  match String.split_on_char ' ' line with
  | version :: code :: _ ->
      let code = int_of_string code in
      (version, code)
  | _ -> failwith ("Invalid HTTP status line: " ^ line)

(** Parse HTTP headers until empty line *)
let parse_headers flow =
  let headers = Hashtbl.create 16 in
  let rec loop () =
    let line = read_line flow in
    if String.length line = 0 then headers
    else
      match String.index_opt line ':' with
      | Some i ->
          let name =
            String.lowercase_ascii (String.trim (String.sub line 0 i))
          in
          let value =
            String.trim (String.sub line (i + 1) (String.length line - i - 1))
          in
          Hashtbl.add headers name value;
          loop ()
      | None ->
          (* Malformed header, skip *)
          loop ()
  in
  loop ()

(** Handshake result *)
type result = Success | Failed of string

(** Perform WebSocket handshake over a TLS flow *)
let perform ~flow ~host ~port ~resource =
  Log.debug (fun m -> m "Starting handshake to %s:%d%s" host port resource);

  (* Generate key for Sec-WebSocket-Key *)
  let key = generate_key () in
  let expected = expected_accept key in

  (* Build HTTP request *)
  let request =
    Printf.sprintf
      "GET %s HTTP/1.1\r\n\
       Host: %s:%d\r\n\
       Upgrade: websocket\r\n\
       Connection: Upgrade\r\n\
       Sec-WebSocket-Key: %s\r\n\
       Sec-WebSocket-Version: 13\r\n\
       Origin: https://polymarket.com\r\n\
       User-Agent: polymarket-ocaml/1.0\r\n\
       \r\n"
      resource host port key
  in

  Log.debug (fun m -> m "Sending request with key %s" key);

  (* Send request *)
  Eio.Flow.copy_string request flow;

  (* Read status line *)
  let status_line = read_line flow in
  Log.debug (fun m -> m "Status: %s" status_line);

  let _version, status_code = parse_status_line status_line in

  if status_code <> 101 then begin
    let msg = Printf.sprintf "Expected 101, got %d" status_code in
    Log.err (fun m -> m "Handshake failed: %s" msg);
    Failed msg
  end
  else begin
    (* Parse headers *)
    let headers = parse_headers flow in

    (* Verify Sec-WebSocket-Accept *)
    let accept =
      match Hashtbl.find_opt headers "sec-websocket-accept" with
      | Some v -> v
      | None -> ""
    in

    if accept <> expected then begin
      let msg =
        Printf.sprintf "Invalid Sec-WebSocket-Accept: expected %s, got %s"
          expected accept
      in
      Log.err (fun m -> m "Handshake failed: %s" msg);
      Failed msg
    end
    else begin
      Log.debug (fun m -> m "Handshake successful");
      Success
    end
  end
