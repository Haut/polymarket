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

(** {1 Hex String Functor}

    Shared implementation for validated hex string types. *)

module type HEX_STRING_CONFIG = sig
  val name : string
  val validate : string -> (string, string) result
end

module Make_hex_string (C : HEX_STRING_CONFIG) = struct
  type t = string

  let make = C.validate
  let make_exn s = match make s with Ok v -> v | Error msg -> failwith msg
  let unsafe_of_string s = s
  let to_string t = t
  let pp fmt t = Format.fprintf fmt "%s" t
  let equal = String.equal

  let of_yojson json =
    match json with
    | `String s -> make s
    | _ -> Error (C.name ^ ".of_yojson: expected string")

  let of_yojson_exn json =
    match of_yojson json with Ok v -> v | Error msg -> failwith msg

  let to_yojson t = `String t
  let yojson_of_t = to_yojson
  let t_of_yojson = of_yojson_exn
end

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

(** {1 Non-negative Integers} *)

module Nonneg_int = Bounded.Nonneg_int

(** {1 Positive Integers} *)

module Pos_int = Bounded.Pos_int

(** {1 Non-negative Floats} *)

module Nonneg_float = Bounded.Nonneg_float

(** {1 Bounded Integer Types} *)

module Limit = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 500
  let default = 100
  let name = "limit"
end)

module Offset = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 10000
  let default = 0
  let name = "offset"
end)

module Holders_limit = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 20
  let default = 20
  let name = "holders limit"
end)

module Min_balance = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 999999
  let default = 1
  let name = "min_balance"
end)

module Closed_positions_limit = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 50
  let default = 10
  let name = "closed positions limit"
end)

module Extended_offset = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 100000
  let default = 0
  let name = "offset"
end)

module Leaderboard_limit = Bounded.Make_int (struct
  let min_value = 1
  let max_value = 50
  let default = 25
  let name = "leaderboard limit"
end)

module Leaderboard_offset = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 1000
  let default = 0
  let name = "leaderboard offset"
end)

module Builder_limit = Bounded.Make_int (struct
  let min_value = 0
  let max_value = 50
  let default = 25
  let name = "builder limit"
end)

(** {1 Bounded String} *)

module Bounded_string = struct
  type t = string

  let of_string ~max_length s =
    if String.length s <= max_length then Some s else None

  let of_string_exn ~max_length s =
    if String.length s <= max_length then s
    else
      invalid_arg (Printf.sprintf "string exceeds max length of %d" max_length)

  let to_string t = t
end

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

  let t_of_yojson = function
    | `String s -> of_string_exn s
    | _ -> failwith "Timestamp: expected string"

  let yojson_of_t t = `String (to_string t)
  let pp fmt t = Format.fprintf fmt "%s" (to_string t)
  let equal = Ptime.equal
end

(** {1 Side Enum}

    Trade side (Buy/Sell) shared across Data API and CLOB API. *)

module Side = struct
  type t = Buy | Sell [@@deriving enum]
end
