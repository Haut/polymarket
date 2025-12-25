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
  let yojson_of_t = yojson_of
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
  let yojson_of_t = yojson_of
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
  let yojson_of_t = yojson_of
  let t_of_yojson = of_yojson_exn
end

(** {1 Non-negative Integers} *)

module Nonneg_int = struct
  type t = int

  let of_int n = if n >= 0 then Some n else None
  let of_int_exn n = if n >= 0 then n else invalid_arg "must be non-negative"
  let to_int n = n
  let zero = 0
  let one = 1
end

(** {1 Positive Integers} *)

module Pos_int = struct
  type t = int

  let of_int n = if n >= 1 then Some n else None
  let of_int_exn n = if n >= 1 then n else invalid_arg "must be positive (>= 1)"
  let to_int n = n
  let one = 1
end

(** {1 Non-negative Floats} *)

module Nonneg_float = struct
  type t = float

  let of_float n = if n >= 0.0 then Some n else None

  let of_float_exn n =
    if n >= 0.0 then n else invalid_arg "must be non-negative"

  let to_float n = n
  let zero = 0.0
end

(** {1 Limit} *)

module Limit = struct
  type t = int

  let min_value = 0
  let max_value = 500
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "limit must be between %d and %d" min_value max_value)

  let to_int n = n
  let default = 100
end

(** {1 Offset} *)

module Offset = struct
  type t = int

  let min_value = 0
  let max_value = 10000
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "offset must be between %d and %d" min_value max_value)

  let to_int n = n
  let default = 0
end

(** {1 Holders Limit} *)

module Holders_limit = struct
  type t = int

  let min_value = 0
  let max_value = 20
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "holders limit must be between %d and %d" min_value
           max_value)

  let to_int n = n
  let default = 20
end

(** {1 Min Balance} *)

module Min_balance = struct
  type t = int

  let min_value = 0
  let max_value = 999999
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "min_balance must be between %d and %d" min_value
           max_value)

  let to_int n = n
  let default = 1
end

(** {1 Closed Positions Limit} *)

module Closed_positions_limit = struct
  type t = int

  let min_value = 0
  let max_value = 50
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "closed positions limit must be between %d and %d"
           min_value max_value)

  let to_int n = n
  let default = 10
end

(** {1 Extended Offset} *)

module Extended_offset = struct
  type t = int

  let min_value = 0
  let max_value = 100000
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "offset must be between %d and %d" min_value max_value)

  let to_int n = n
  let default = 0
end

(** {1 Leaderboard Limit} *)

module Leaderboard_limit = struct
  type t = int

  let min_value = 1
  let max_value = 50
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "leaderboard limit must be between %d and %d" min_value
           max_value)

  let to_int n = n
  let default = 25
end

(** {1 Leaderboard Offset} *)

module Leaderboard_offset = struct
  type t = int

  let min_value = 0
  let max_value = 1000
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "leaderboard offset must be between %d and %d" min_value
           max_value)

  let to_int n = n
  let default = 0
end

(** {1 Builder Limit} *)

module Builder_limit = struct
  type t = int

  let min_value = 0
  let max_value = 50
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "builder limit must be between %d and %d" min_value
           max_value)

  let to_int n = n
  let default = 25
end

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
  let show t = to_string t
  let equal = Ptime.equal
end
