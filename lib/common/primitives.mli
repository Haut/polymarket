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

  val t_of_yojson : Yojson.Safe.t -> t
  (** Alias for of_yojson_exn (ppx_yojson_conv compatibility). *)
end
