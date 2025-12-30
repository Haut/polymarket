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
module Make_int (_ : INT_BOUNDS) : BOUNDED_INT

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

module Nonneg_int : NONNEG_INT
(** Non-negative integer implementation. *)

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

module Pos_int : POS_INT
(** Positive integer implementation. *)

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
module Make_float (_ : FLOAT_BOUNDS) : BOUNDED_FLOAT

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

module Nonneg_float : NONNEG_FLOAT
(** Non-negative float implementation. *)
