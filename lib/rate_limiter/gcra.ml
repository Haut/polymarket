(** Generic Cell Rate Algorithm (GCRA) for rate limiting. *)

type t = {
  mutable tat : float;  (** Theoretical Arrival Time *)
  emission_interval : float;  (** Time between requests at sustained rate *)
  burst_allowance : float;  (** Maximum burst allowance in seconds *)
}

let create (config : Types.limit_config) =
  let emission_interval =
    config.window_seconds /. float_of_int config.requests
  in
  let burst_allowance = config.window_seconds in
  { tat = 0.0; emission_interval; burst_allowance }

let check t ~now =
  let allow_at = t.tat -. t.burst_allowance in
  if now >= allow_at then Ok ()
  else
    let retry_after = allow_at -. now in
    Error retry_after

let update t ~now =
  let new_tat = Float.max now t.tat +. t.emission_interval in
  t.tat <- new_tat

let check_and_update t ~now =
  match check t ~now with
  | Error _ as e -> e
  | Ok () ->
      update t ~now;
      Ok ()

let reset t = t.tat <- 0.0

let time_until_ready t ~now =
  let allow_at = t.tat -. t.burst_allowance in
  Float.max 0.0 (allow_at -. now)

let emission_interval t = t.emission_interval
let burst_allowance t = t.burst_allowance
