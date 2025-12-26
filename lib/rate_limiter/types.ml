(** Core types for rate limiting. *)

type route_pattern = {
  host : string option;
  method_ : string option;
  path_prefix : string option;
}
[@@deriving show, eq]

let any_route = { host = None; method_ = None; path_prefix = None }

type limit_config = { requests : int; window_seconds : float }
[@@deriving show, eq]

let limit ~requests ~window_seconds = { requests; window_seconds }

type behavior = Delay | Error [@@deriving show, eq]

type route_config = {
  pattern : route_pattern;
  limits : limit_config list;
  behavior : behavior;
}
[@@deriving show, eq]

type error = Rate_limited of { retry_after : float; route_key : string }
[@@deriving show, eq]
