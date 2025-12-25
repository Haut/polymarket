(** Abstract primitive types with built-in validation.

    This module provides type-safe wrappers for Ethereum addresses and hashes.
    Values can only be created through smart constructors that validate the
    input, making it impossible to have invalid addresses or hashes in the
    system. *)

(** {1 Address Module}

    Ethereum address type (0x-prefixed, 40 hex chars, total 42 chars).
    Pattern: ^0x[a-fA-F0-9]{40}$ *)
module Address : sig
  type t

  val make : string -> (t, string) result
  (** Create an address with validation. Returns Error if invalid. *)

  val make_exn : string -> t
  (** Create an address with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val show : t -> string
  (** Show as string (alias for to_string). *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of : t -> Yojson.Safe.t
  (** Alias for to_yojson (ppx_yojson_conv compatibility). *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** Alias for to_yojson (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** Alias for of_yojson_exn (ppx_yojson_conv compatibility). *)
end

(** {1 Hash64 Module}

    64-character hex hash type (0x-prefixed, 64 hex chars, total 66 chars).
    Pattern: ^0x[a-fA-F0-9]{64}$ *)
module Hash64 : sig
  type t

  val make : string -> (t, string) result
  (** Create a hash64 with validation. Returns Error if invalid. *)

  val make_exn : string -> t
  (** Create a hash64 with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val show : t -> string
  (** Show as string (alias for to_string). *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of : t -> Yojson.Safe.t
  (** Alias for to_yojson (ppx_yojson_conv compatibility). *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** Alias for to_yojson (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** Alias for of_yojson_exn (ppx_yojson_conv compatibility). *)
end

(** {1 Hash Module}

    Variable-length hex hash type (0x-prefixed, any number of hex chars). Used
    for signatures and other variable-length hex data. *)
module Hash : sig
  type t

  val make : string -> (t, string) result
  (** Create a hash with validation. Returns Error if invalid. *)

  val make_exn : string -> t
  (** Create a hash with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val show : t -> string
  (** Show as string (alias for to_string). *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of : t -> Yojson.Safe.t
  (** Alias for to_yojson (ppx_yojson_conv compatibility). *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** Alias for to_yojson (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** Alias for of_yojson_exn (ppx_yojson_conv compatibility). *)
end

(** {1 Non-negative Integers}

    A non-negative integer type (>= 0). Used for pagination parameters like
    limit and offset. *)
module Nonneg_int : sig
  type t
  (** A non-negative integer (>= 0) *)

  val of_int : int -> t option
  (** Create from int, returns None if negative *)

  val of_int_exn : int -> t
  (** Create from int, raises if negative *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val zero : t
  val one : t
end

(** {1 Positive Integers}

    A positive integer type (>= 1). Used for event IDs and other identifiers
    that must be at least 1. *)
module Pos_int : sig
  type t
  (** A positive integer (>= 1) *)

  val of_int : int -> t option
  (** Create from int, returns None if less than 1 *)

  val of_int_exn : int -> t
  (** Create from int, raises if less than 1 *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val one : t
end

(** {1 Non-negative Floats}

    A non-negative float type (>= 0). Used for thresholds and other numeric
    parameters that must not be negative. *)
module Nonneg_float : sig
  type t
  (** A non-negative float (>= 0) *)

  val of_float : float -> t option
  (** Create from float, returns None if negative *)

  val of_float_exn : float -> t
  (** Create from float, raises if negative *)

  val to_float : t -> float
  (** Extract the underlying float *)

  val zero : t
end

(** {1 Limit}

    A bounded integer type for pagination limit (0-500). *)
module Limit : sig
  type t
  (** A limit value (0 <= x <= 500) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (100) *)
end

(** {1 Offset}

    A bounded integer type for pagination offset (0-10000). *)
module Offset : sig
  type t
  (** An offset value (0 <= x <= 10000) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (0) *)
end

(** {1 Holders Limit}

    A bounded integer type for holders limit (0-20). *)
module Holders_limit : sig
  type t
  (** A holders limit value (0 <= x <= 20) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (20) *)
end

(** {1 Min Balance}

    A bounded integer type for minimum balance filter (0-999999). *)
module Min_balance : sig
  type t
  (** A min balance value (0 <= x <= 999999) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (1) *)
end

(** {1 Closed Positions Limit}

    A bounded integer type for closed positions limit (0-50). *)
module Closed_positions_limit : sig
  type t
  (** A closed positions limit value (0 <= x <= 50) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (10) *)
end

(** {1 Extended Offset}

    A bounded integer type for extended offset (0-100000). *)
module Extended_offset : sig
  type t
  (** An extended offset value (0 <= x <= 100000) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (0) *)
end

(** {1 Leaderboard Limit}

    A bounded integer type for leaderboard limit (1-50). *)
module Leaderboard_limit : sig
  type t
  (** A leaderboard limit value (1 <= x <= 50) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (25) *)
end

(** {1 Leaderboard Offset}

    A bounded integer type for leaderboard offset (0-1000). *)
module Leaderboard_offset : sig
  type t
  (** A leaderboard offset value (0 <= x <= 1000) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (0) *)
end

(** {1 Builder Limit}

    A bounded integer type for builder leaderboard limit (0-50). *)
module Builder_limit : sig
  type t
  (** A builder limit value (0 <= x <= 50) *)

  val min_value : int
  val max_value : int

  val of_int : int -> t option
  (** Create from int, returns None if out of range *)

  val of_int_exn : int -> t
  (** Create from int, raises if out of range *)

  val to_int : t -> int
  (** Extract the underlying int *)

  val default : t
  (** Default value (25) *)
end

(** {1 Bounded String}

    A string type with maximum length validation. *)
module Bounded_string : sig
  type t
  (** A length-bounded string *)

  val of_string : max_length:int -> string -> t option
  (** Create from string, returns None if exceeds max_length *)

  val of_string_exn : max_length:int -> string -> t
  (** Create from string, raises if exceeds max_length *)

  val to_string : t -> string
  (** Extract the underlying string *)
end

(** {1 Timestamps}

    ISO 8601 timestamp type (e.g., "2023-11-07T05:31:56Z"). Used for date/time
    parameters in API requests. *)
module Timestamp : sig
  type t
  (** An ISO 8601 timestamp (e.g., "2023-11-07T05:31:56Z") *)

  val of_string : string -> t option
  (** Parse from ISO 8601 string *)

  val of_string_exn : string -> t
  (** Parse from ISO 8601 string, raises on invalid format *)

  val to_string : t -> string
  (** Convert to ISO 8601 string *)

  val to_ptime : t -> Ptime.t
  (** Get the underlying Ptime.t *)

  val of_ptime : Ptime.t -> t
  (** Create from Ptime.t *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** Parse from JSON string *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** Convert to JSON string *)

  val pp : Format.formatter -> t -> unit
  val show : t -> string
  val equal : t -> t -> bool
end
