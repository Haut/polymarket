(** Abstract primitive types with built-in validation.

    This module provides type-safe wrappers for Ethereum addresses and hashes.
    Values can only be created through smart constructors that validate the
    input, making it impossible to have invalid addresses or hashes in the
    system. *)

(** {1 Validation Errors} *)

type validation_error =
  | Invalid_length of { type_name : string; expected : int; actual : int }
  | Missing_prefix of { type_name : string; expected : string }
  | Invalid_hex of { type_name : string }
  | Empty_value of { type_name : string }
  | Invalid_format of { type_name : string; reason : string }

let string_of_validation_error = function
  | Invalid_length { type_name; expected; actual } ->
      Printf.sprintf "%s: expected %d chars, got %d" type_name expected actual
  | Missing_prefix { type_name; expected } ->
      Printf.sprintf "%s: must start with %s" type_name expected
  | Invalid_hex { type_name } ->
      Printf.sprintf "%s: contains invalid hex characters" type_name
  | Empty_value { type_name } ->
      Printf.sprintf "%s: must be non-empty" type_name
  | Invalid_format { type_name; reason } ->
      Printf.sprintf "%s: %s" type_name reason

let pp_validation_error fmt e =
  Format.fprintf fmt "%s" (string_of_validation_error e)

(** {1 Internal Validation Helpers} *)

let is_hex_char = function
  | '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true
  | _ -> false

let is_hex_string s = String.for_all is_hex_char s

let validate_hex_prefixed ~name ~expected_length s =
  let len = String.length s in
  if len <> expected_length then
    Error
      (Invalid_length
         { type_name = name; expected = expected_length; actual = len })
  else if len < 2 || s.[0] <> '0' || s.[1] <> 'x' then
    Error (Missing_prefix { type_name = name; expected = "0x" })
  else if not (is_hex_string (String.sub s 2 (len - 2))) then
    Error (Invalid_hex { type_name = name })
  else Ok s

(** {1 String Type Functors}

    Shared implementations for validated string types. *)

module type STRING_CONFIG = sig
  val name : string
  val validate : string -> (string, validation_error) result
end

module Make_string_type (C : STRING_CONFIG) = struct
  type t = string

  let make = C.validate
  let unsafe_of_string s = s
  let to_string t = t
  let pp fmt t = Format.fprintf fmt "%s" t
  let equal = String.equal

  let of_yojson json =
    match json with
    | `String s -> make s
    | _ ->
        Error
          (Invalid_format
             { type_name = C.name; reason = "expected JSON string" })

  let of_yojson_exn json =
    match of_yojson json with
    | Ok v -> v
    | Error e ->
        raise
          (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
             (Failure (string_of_validation_error e), json))

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
    if len < 3 then
      Error (Invalid_format { type_name = name; reason = "too short" })
    else if s.[0] <> '0' || s.[1] <> 'x' then
      Error (Missing_prefix { type_name = name; expected = "0x" })
    else if not (is_hex_string (String.sub s 2 (len - 2))) then
      Error (Invalid_hex { type_name = name })
    else Ok s
end)

(** {1 Signature Module}

    Hex-encoded cryptographic signature (0x-prefixed, variable length). *)

module Signature = Make_string_type (struct
  let name = "Signature"

  let validate s =
    let len = String.length s in
    if len < 3 then
      Error (Invalid_format { type_name = name; reason = "too short" })
    else if s.[0] <> '0' || s.[1] <> 'x' then
      Error (Missing_prefix { type_name = name; expected = "0x" })
    else if not (is_hex_string (String.sub s 2 (len - 2))) then
      Error (Invalid_hex { type_name = name })
    else Ok s
end)

(** {1 UUID-based ID Types}

    These types wrap UUID strings with non-empty validation. They are distinct
    types to prevent mixing different ID kinds. *)

let validate_non_empty ~name s =
  if String.length s > 0 then Ok s else Error (Empty_value { type_name = name })

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

(** {1 Decimal Module}

    Arbitrary-precision decimal numbers using Zarith rationals. Used for
    financial values where floating-point approximation is unacceptable. *)

(** {1 U256 Module}

    256-bit unsigned integer using Zarith. Used for token amounts, raw prices,
    and other values that require exact uint256 representation. *)

module U256 = struct
  type t = Z.t

  let max_value = Z.(shift_left one 256 - one)
  let min_value = Z.zero
  let is_valid z = Z.(geq z zero && leq z max_value)

  let make z =
    if is_valid z then Ok z
    else
      Error
        (Invalid_format
           { type_name = "U256"; reason = "value out of uint256 range" })

  let of_z = make
  let unsafe_of_z z = z
  let to_z t = t

  let of_string s =
    if String.length s = 0 then Error (Empty_value { type_name = "U256" })
    else
      try
        let z = Z.of_string s in
        make z
      with _ ->
        Error (Invalid_format { type_name = "U256"; reason = "invalid number" })

  let unsafe_of_string s = Z.of_string s
  let to_string t = Z.to_string t

  let to_hex t =
    let hex = Z.format "%x" t in
    "0x" ^ hex

  let pp fmt t = Format.fprintf fmt "%s" (Z.to_string t)
  let equal = Z.equal
  let compare = Z.compare

  (* Constants *)
  let zero = Z.zero
  let one = Z.one

  (* Arithmetic - all operations check bounds *)
  let add a b =
    let r = Z.add a b in
    if Z.leq r max_value then Some r else None

  let sub a b =
    let r = Z.sub a b in
    if Z.geq r zero then Some r else None

  let mul a b =
    let r = Z.mul a b in
    if Z.leq r max_value then Some r else None

  let div a b = if Z.equal b zero then None else Some (Z.div a b)

  (* Unsafe arithmetic - for trusted inputs *)
  let unsafe_add = Z.add
  let unsafe_sub = Z.sub
  let unsafe_mul = Z.mul
  let unsafe_div = Z.div

  (* Comparisons *)
  let ( = ) = Z.equal
  let ( < ) = Z.lt
  let ( > ) = Z.gt
  let ( <= ) = Z.leq
  let ( >= ) = Z.geq

  let t_of_yojson json =
    match json with
    | `String s -> (
        match of_string s with
        | Ok v -> v
        | Error e ->
            raise
              (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
                 (Failure (string_of_validation_error e), json)))
    | `Int i ->
        if Stdlib.(i >= 0) then Z.of_int i
        else
          raise
            (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
               (Failure "U256: negative value not allowed", json))
    | `Intlit s -> (
        match of_string s with
        | Ok v -> v
        | Error e ->
            raise
              (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
                 (Failure (string_of_validation_error e), json)))
    | _ ->
        raise
          (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
             (Failure "U256: expected string or int", json))

  let yojson_of_t t = `String (Z.to_string t)
end

module Decimal = struct
  type t = Q.t

  let of_string s = Q.of_string s
  let of_float f = Q.of_float f
  let of_int i = Q.of_int i
  let to_string t = Q.to_string t
  let to_float t = Q.to_float t
  let pp fmt t = Format.fprintf fmt "%s" (Q.to_string t)
  let equal = Q.equal
  let compare = Q.compare
  let zero = Q.zero
  let one = Q.one
  let ( + ) = Q.add
  let ( - ) = Q.sub
  let ( * ) = Q.mul
  let ( / ) = Q.div
  let ( ~- ) = Q.neg
  let abs = Q.abs
  let neg = Q.neg
  let min = Q.min
  let max = Q.max
  let ( = ) = Q.equal
  let ( < ) = Q.lt
  let ( > ) = Q.gt
  let ( <= ) = Q.leq
  let ( >= ) = Q.geq

  let t_of_yojson json =
    match json with
    | `String s -> (
        try Q.of_string s
        with _ ->
          raise
            (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
               (Failure ("Decimal: invalid string: " ^ s), json)))
    | `Float f -> Q.of_float f
    | `Int i -> Q.of_int i
    | `Intlit s -> (
        try Q.of_string s
        with _ ->
          raise
            (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
               (Failure ("Decimal: invalid intlit: " ^ s), json)))
    | _ ->
        raise
          (Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error
             (Failure "Decimal: expected string or number", json))

  let yojson_of_t t = `String (Q.to_string t)
end
