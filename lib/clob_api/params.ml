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
  | MAX
[@@deriving show, eq]

let string_of_time_interval = function
  | MIN_1 -> "1m"
  | MIN_5 -> "5m"
  | MIN_15 -> "15m"
  | HOUR_1 -> "1h"
  | HOUR_6 -> "6h"
  | DAY_1 -> "1d"
  | WEEK_1 -> "1w"
  | MAX -> "max"

let time_interval_of_string = function
  | "1m" -> MIN_1
  | "5m" -> MIN_5
  | "15m" -> MIN_15
  | "1h" -> HOUR_1
  | "6h" -> HOUR_6
  | "1d" -> DAY_1
  | "1w" -> WEEK_1
  | "max" -> MAX
  | s -> failwith ("Unknown time_interval: " ^ s)
