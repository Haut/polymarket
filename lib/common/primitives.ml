(** Abstract primitive types with built-in validation.

    This module provides type-safe wrappers for Ethereum addresses and hashes.
    Values can only be created through smart constructors that validate the
    input, making it impossible to have invalid addresses or hashes in the
    system. *)

(** {1 Internal Validation Helpers} *)

let is_hex_char = function
  | '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true
  | _ -> false

let is_hex_string s = String.for_all is_hex_char s

let validate_hex_prefixed ~name ~expected_length s =
  let len = String.length s in
  if len <> expected_length then
    Error
      (Printf.sprintf "%s: expected %d chars, got %d" name expected_length len)
  else if len < 2 || s.[0] <> '0' || s.[1] <> 'x' then
    Error (Printf.sprintf "%s: must start with 0x" name)
  else if not (is_hex_string (String.sub s 2 (len - 2))) then
    Error (Printf.sprintf "%s: contains invalid hex characters" name)
  else Ok s

(** {1 Address Module} *)

module Address = struct
  type t = string

  let make s = validate_hex_prefixed ~name:"Address" ~expected_length:42 s

  let make_exn s =
    match make s with Ok addr -> addr | Error msg -> failwith msg

  let unsafe_of_string s = s
  let to_string t = t
  let pp fmt t = Format.fprintf fmt "%s" t
  let show = to_string
  let equal = String.equal

  let of_yojson json =
    match json with
    | `String s -> make s
    | _ -> Error "Address.of_yojson: expected string"

  let of_yojson_exn json =
    match of_yojson json with Ok v -> v | Error msg -> failwith msg

  let to_yojson t = `String t
  let yojson_of t = to_yojson t
  let t_of_yojson = of_yojson_exn
end

(** {1 Hash64 Module} *)

module Hash64 = struct
  type t = string

  let make s = validate_hex_prefixed ~name:"Hash64" ~expected_length:66 s

  let make_exn s =
    match make s with Ok hash -> hash | Error msg -> failwith msg

  let unsafe_of_string s = s
  let to_string t = t
  let pp fmt t = Format.fprintf fmt "%s" t
  let show = to_string
  let equal = String.equal

  let of_yojson json =
    match json with
    | `String s -> make s
    | _ -> Error "Hash64.of_yojson: expected string"

  let of_yojson_exn json =
    match of_yojson json with Ok v -> v | Error msg -> failwith msg

  let to_yojson t = `String t
  let yojson_of t = to_yojson t
  let t_of_yojson = of_yojson_exn
end

(** {1 Hash Module (variable length)} *)

module Hash = struct
  type t = string

  let make s =
    let len = String.length s in
    if len < 3 then Error "Hash: too short"
    else if s.[0] <> '0' || s.[1] <> 'x' then Error "Hash: must start with 0x"
    else if not (is_hex_string (String.sub s 2 (len - 2))) then
      Error "Hash: contains invalid hex characters"
    else Ok s

  let make_exn s =
    match make s with Ok hash -> hash | Error msg -> failwith msg

  let unsafe_of_string s = s
  let to_string t = t
  let pp fmt t = Format.fprintf fmt "%s" t
  let show = to_string
  let equal = String.equal

  let of_yojson json =
    match json with
    | `String s -> make s
    | _ -> Error "Hash.of_yojson: expected string"

  let of_yojson_exn json =
    match of_yojson json with Ok v -> v | Error msg -> failwith msg

  let to_yojson t = `String t
  let yojson_of t = to_yojson t
  let t_of_yojson = of_yojson_exn
end
