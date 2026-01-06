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
let is_digit_char = function '0' .. '9' -> true | _ -> false
let is_numeric_string s = String.length s > 0 && String.for_all is_digit_char s

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

(** {1 String Type Functors}

    Shared implementations for validated string types. *)

module type STRING_CONFIG = sig
  val name : string
  val validate : string -> (string, string) result
end

module Make_string_type (C : STRING_CONFIG) = struct
  type t = string

  let make = C.validate
  let make_exn s = match make s with Ok v -> v | Error msg -> invalid_arg msg
  let unsafe_of_string s = s
  let to_string t = t
  let pp fmt t = Format.fprintf fmt "%s" t
  let equal = String.equal

  let of_yojson json =
    match json with
    | `String s -> make s
    | _ -> Error (C.name ^ ".of_yojson: expected string")

  let of_yojson_exn json =
    match of_yojson json with
    | Ok v -> v
    | Error msg ->
        raise
          (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (Failure msg, json))

  let to_yojson t = `String t
  let yojson_of_t = to_yojson
  let t_of_yojson = of_yojson_exn
end

module type HEX_STRING_CONFIG = STRING_CONFIG
(** Alias for backwards compatibility *)

module Make_hex_string = Make_string_type

(** {1 Address Module} *)

module Address = Make_hex_string (struct
  let name = "Address"
  let validate = validate_hex_prefixed ~name ~expected_length:42
end)

(** {1 Hash64 Module} *)

module Hash64 = Make_hex_string (struct
  let name = "Hash64"
  let validate = validate_hex_prefixed ~name ~expected_length:66
end)

(** {1 Hash Module (variable length)} *)

module Hash = Make_hex_string (struct
  let name = "Hash"

  let validate s =
    let len = String.length s in
    if len < 3 then Error "Hash: too short"
    else if s.[0] <> '0' || s.[1] <> 'x' then Error "Hash: must start with 0x"
    else if not (is_hex_string (String.sub s 2 (len - 2))) then
      Error "Hash: contains invalid hex characters"
    else Ok s
end)

(** {1 Token_id Module}

    ERC1155 token ID (numeric string representing uint256). *)

module Token_id = Make_string_type (struct
  let name = "Token_id"

  let validate s =
    if is_numeric_string s then Ok s
    else Error "Token_id: must be a non-empty numeric string"
end)

(** {1 Signature Module}

    Hex-encoded cryptographic signature (0x-prefixed, variable length). *)

module Signature = Make_string_type (struct
  let name = "Signature"

  let validate s =
    let len = String.length s in
    if len < 3 then Error "Signature: too short"
    else if s.[0] <> '0' || s.[1] <> 'x' then
      Error "Signature: must start with 0x"
    else if not (is_hex_string (String.sub s 2 (len - 2))) then
      Error "Signature: contains invalid hex characters"
    else Ok s
end)

(** {1 UUID-based ID Types}

    These types wrap UUID strings with non-empty validation. They are distinct
    types to prevent mixing different ID kinds. *)

let validate_non_empty ~name s =
  if String.length s > 0 then Ok s else Error (name ^ ": must be non-empty")

module Request_id = Make_string_type (struct
  let name = "Request_id"
  let validate = validate_non_empty ~name
end)

module Quote_id = Make_string_type (struct
  let name = "Quote_id"
  let validate = validate_non_empty ~name
end)

module Trade_id = Make_string_type (struct
  let name = "Trade_id"
  let validate = validate_non_empty ~name
end)

(** {1 Timestamps} *)

module Timestamp = struct
  type t = Ptime.t

  let of_string s =
    match Ptime.of_rfc3339 s with Ok (t, _, _) -> Some t | Error _ -> None

  let of_string_exn s =
    match of_string s with
    | Some t -> t
    | None -> invalid_arg ("invalid ISO 8601 timestamp: " ^ s)

  let to_string t = Ptime.to_rfc3339 ~tz_offset_s:0 t
  let to_ptime t = t
  let of_ptime t = t

  let t_of_yojson json =
    match json with
    | `String s -> of_string_exn s
    | _ ->
        raise
          (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
             (Failure "Timestamp: expected string", json))

  let yojson_of_t t = `String (to_string t)
  let pp fmt t = Format.fprintf fmt "%s" (to_string t)
  let equal = Ptime.equal
end

(** {1 Side Enum}

    Trade side (Buy/Sell) shared across Data API and CLOB API. *)

module Side = struct
  type t = Buy | Sell [@@deriving enum]
end

(** {1 Sort Direction Enum}

    Sort direction (Asc/Desc) shared across Data API and RFQ API. *)

module Sort_dir = struct
  type t = Asc | Desc [@@deriving enum]
end
