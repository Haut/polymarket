(** Generic functors for bounded numeric types.

    This module provides functors to eliminate boilerplate for bounded integer
    and float types with validation. *)

(** {1 Bounded Integer Functors} *)

(** Configuration for a bounded integer type. *)
module type INT_BOUNDS = sig
  val min_value : int
  (** Minimum allowed value (inclusive). *)

  val max_value : int
  (** Maximum allowed value (inclusive). *)

  val default : int
  (** Default value (must be within bounds). *)

  val name : string
  (** Name for error messages (e.g., "limit", "offset"). *)
end

(** Interface for a bounded integer type. *)
module type BOUNDED_INT = sig
  type t = private int

  val min_value : int
  val max_value : int
  val default : t
  val of_int : int -> t option
  val of_int_exn : int -> t
  val to_int : t -> int
  val to_string : t -> string
end

(** Create a bounded integer module from bounds configuration. *)
module Make_int (Bounds : INT_BOUNDS) : BOUNDED_INT = struct
  type t = int

  let min_value = Bounds.min_value
  let max_value = Bounds.max_value
  let default = Bounds.default
  let of_int n = if n >= min_value && n <= max_value then Some n else None

  let of_int_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "%s must be between %d and %d, got %d" Bounds.name
           min_value max_value n)

  let to_int n = n
  let to_string n = string_of_int n
end

(** {1 Non-negative Integer} *)

(** Interface for non-negative integers (no upper bound). *)
module type NONNEG_INT = sig
  type t = private int

  val of_int : int -> t option
  val of_int_exn : int -> t
  val to_int : t -> int
  val to_string : t -> string
  val zero : t
  val one : t
end

(** Non-negative integer implementation. *)
module Nonneg_int : NONNEG_INT = struct
  type t = int

  let of_int n = if n >= 0 then Some n else None
  let of_int_exn n = if n >= 0 then n else invalid_arg "must be non-negative"
  let to_int n = n
  let to_string n = string_of_int n
  let zero = 0
  let one = 1
end

(** {1 Positive Integer} *)

(** Interface for positive integers (>= 1, no upper bound). *)
module type POS_INT = sig
  type t = private int

  val of_int : int -> t option
  val of_int_exn : int -> t
  val to_int : t -> int
  val to_string : t -> string
  val one : t
end

(** Positive integer implementation. *)
module Pos_int : POS_INT = struct
  type t = int

  let of_int n = if n >= 1 then Some n else None
  let of_int_exn n = if n >= 1 then n else invalid_arg "must be positive (>= 1)"
  let to_int n = n
  let to_string n = string_of_int n
  let one = 1
end

(** {1 Bounded Float Functors} *)

(** Configuration for a bounded float type. *)
module type FLOAT_BOUNDS = sig
  val min_value : float
  (** Minimum allowed value (inclusive). *)

  val max_value : float
  (** Maximum allowed value (inclusive). *)

  val name : string
  (** Name for error messages. *)
end

(** Interface for a bounded float type. *)
module type BOUNDED_FLOAT = sig
  type t = private float

  val min_value : float
  val max_value : float
  val of_float : float -> t option
  val of_float_exn : float -> t
  val to_float : t -> float
  val to_string : t -> string
end

(** Create a bounded float module from bounds configuration. *)
module Make_float (Bounds : FLOAT_BOUNDS) : BOUNDED_FLOAT = struct
  type t = float

  let min_value = Bounds.min_value
  let max_value = Bounds.max_value
  let of_float n = if n >= min_value && n <= max_value then Some n else None

  let of_float_exn n =
    if n >= min_value && n <= max_value then n
    else
      invalid_arg
        (Printf.sprintf "%s must be between %g and %g, got %g" Bounds.name
           min_value max_value n)

  let to_float n = n
  let to_string n = string_of_float n
end

(** {1 Non-negative Float} *)

(** Interface for non-negative floats (no upper bound). *)
module type NONNEG_FLOAT = sig
  type t = private float

  val of_float : float -> t option
  val of_float_exn : float -> t
  val to_float : t -> float
  val to_string : t -> string
  val zero : t
end

(** Non-negative float implementation. *)
module Nonneg_float : NONNEG_FLOAT = struct
  type t = float

  let of_float n = if n >= 0.0 then Some n else None

  let of_float_exn n =
    if n >= 0.0 then n else invalid_arg "must be non-negative"

  let to_float n = n
  let to_string n = string_of_float n
  let zero = 0.0
end
