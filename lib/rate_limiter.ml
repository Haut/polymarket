(** Route-based rate limiting for HTTP clients. *)

let src = Logs.Src.create "polymarket.rate_limiter" ~doc:"Rate limiter"

module Log = (val Logs.src_log src : Logs.LOG)

(* Re-export core types *)
type behavior = Rl_types.behavior = Delay | Error

type route_pattern = Rl_types.route_pattern = {
  host : string option;
  method_ : string option;
  path_prefix : string option;
}

type limit_config = Rl_types.limit_config = {
  requests : int;
  window_seconds : float;
}

type route_config = Rl_types.route_config = {
  pattern : route_pattern;
  limits : limit_config list;
  behavior : behavior;
}

type error = Rl_types.error =
  | Rate_limited of { retry_after : float; route_key : string }

(* Rate limiter state *)
type t = {
  mutable routes : route_config list;
  routes_mutex : Eio.Mutex.t;
  state : Rl_state.t;
  sleep : float -> unit;
}

let create ~routes ~clock ?max_idle_time () =
  let state = Rl_state.create ~clock ?max_idle_time () in
  let sleep duration = Eio.Time.sleep clock duration in
  let routes_mutex = Eio.Mutex.create () in
  { routes; routes_mutex; state; sleep }

let update_routes t routes =
  Eio.Mutex.use_rw ~protect:true t.routes_mutex (fun () -> t.routes <- routes)

(* Wait for rate limit slot with Delay behavior, retrying until successful *)
let rec wait_for_slot t ~route_key ~limits =
  match Rl_state.check_limits t.state ~route_key ~limits with
  | Ok () -> ()
  | Error retry ->
      Log.debug (fun m ->
          m "Rate limited (delay): %s, waiting %.2fs" route_key retry);
      t.sleep retry;
      wait_for_slot t ~route_key ~limits

(* Check rate limits, returns None if allowed or Some error *)
let check t ~method_ ~uri =
  let matching =
    Eio.Mutex.use_ro t.routes_mutex (fun () ->
        Rl_matcher.find_matching_routes ~method_ ~uri t.routes)
  in
  let rec check_routes routes max_error =
    match routes with
    | [] -> max_error
    | (route : route_config) :: rest ->
        let route_key = Rl_matcher.make_route_key ~method_ ~uri route.pattern in
        let result =
          Rl_state.check_limits t.state ~route_key ~limits:route.limits
        in
        let new_max_error =
          match (result, route.behavior, max_error) with
          | Ok (), _, max_err -> max_err
          | Error retry, Error, None ->
              Log.debug (fun m ->
                  m "Rate limited (error): %s, retry after %.2fs" route_key
                    retry);
              Some (Rate_limited { retry_after = retry; route_key })
          | Error retry, Error, Some (Rate_limited prev) ->
              Some
                (Rate_limited
                   {
                     retry_after = Float.max retry prev.retry_after;
                     route_key = prev.route_key;
                   })
          | Error _, Delay, _ ->
              wait_for_slot t ~route_key ~limits:route.limits;
              max_error
        in
        check_routes rest new_max_error
  in
  check_routes matching None

exception Rate_limit_exceeded of error

let before_request t ~method_ ~uri =
  match check t ~method_ ~uri with
  | None -> ()
  | Some err -> raise (Rate_limit_exceeded err)

let before_request_result t ~method_ ~uri =
  match check t ~method_ ~uri with None -> Ok () | Some err -> Error err

(* State management *)
let cleanup t = Rl_state.cleanup t.state
let state_count t = Rl_state.state_count t.state
let reset t = Rl_state.reset t.state

(* Sub-modules *)
module Types = Rl_types
module Builder = Rl_builder
module Gcra = Rl_gcra
module State = Rl_state
module Matcher = Rl_matcher
