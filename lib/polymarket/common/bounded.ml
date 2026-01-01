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

(** {1 Lower-bounded Integer (internal)} *)

module type LOWER_INT_BOUND = sig
  val min_value : int
  val error_msg : string
end

module Make_lower_bounded_int (B : LOWER_INT_BOUND) = struct
  type t = int

  let of_int n = if n >= B.min_value then Some n else None
  let of_int_exn n = if n >= B.min_value then n else invalid_arg B.error_msg
  let to_int n = n
  let to_string = string_of_int
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
  include Make_lower_bounded_int (struct
    let min_value = 0
    let error_msg = "must be non-negative"
  end)

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
  include Make_lower_bounded_int (struct
    let min_value = 1
    let error_msg = "must be positive (>= 1)"
  end)

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

(** {1 Lower-bounded Float (internal)} *)

module type LOWER_FLOAT_BOUND = sig
  val min_value : float
  val error_msg : string
end

module Make_lower_bounded_float (B : LOWER_FLOAT_BOUND) = struct
  type t = float

  let of_float n = if n >= B.min_value then Some n else None
  let of_float_exn n = if n >= B.min_value then n else invalid_arg B.error_msg
  let to_float n = n
  let to_string = string_of_float
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
  include Make_lower_bounded_float (struct
    let min_value = 0.0
    let error_msg = "must be non-negative"
  end)

  let zero = 0.0
end
