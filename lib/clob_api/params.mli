(** CLOB API query parameters for Polymarket. *)

(** {1 Time Interval} *)

type time_interval =
  | MIN_1
  | MIN_5
  | MIN_15
  | HOUR_1
  | HOUR_6
  | DAY_1
  | WEEK_1
  | MAX  (** Time interval for price history queries *)

val string_of_time_interval : time_interval -> string
(** Convert time interval to API string representation *)

val time_interval_of_string : string -> time_interval
(** Parse time interval from API string representation *)

val pp_time_interval : Format.formatter -> time_interval -> unit
val show_time_interval : time_interval -> string
val equal_time_interval : time_interval -> time_interval -> bool
