(** Fluent builder for rate limit configurations. *)

type t = {
  host : string option;
  method_ : string option;
  path_prefix : string option;
  limits : Types.limit_config list;
  behavior : Types.behavior option;
}

let route () =
  {
    host = None;
    method_ = None;
    path_prefix = None;
    limits = [];
    behavior = None;
  }

let host h t = { t with host = Some h }
let method_ m t = { t with method_ = Some m }
let path p t = { t with path_prefix = Some p }

let limit ~requests ~window_seconds t =
  let lim = Types.limit ~requests ~window_seconds in
  { t with limits = t.limits @ [ lim ] }

let on_limit b t = { t with behavior = Some b }

let build t : Types.route_config =
  if t.limits = [] then
    invalid_arg "Builder.build: at least one limit must be configured";
  let pattern : Types.route_pattern =
    { host = t.host; method_ = t.method_; path_prefix = t.path_prefix }
  in
  let behavior = Option.value ~default:Types.Delay t.behavior in
  { pattern; limits = t.limits; behavior }

let simple ?host:h ?method_:m ?path:p ~requests ~window_seconds ?behavior () =
  let b = route () in
  let b = match h with Some hv -> host hv b | None -> b in
  let b = match m with Some mv -> method_ mv b | None -> b in
  let b = match p with Some pv -> path pv b | None -> b in
  let b = limit ~requests ~window_seconds b in
  let b = match behavior with Some beh -> on_limit beh b | None -> b in
  build b

let global ~requests ~window_seconds ~behavior =
  simple ~requests ~window_seconds ~behavior ()

let per_host ~host ~requests ~window_seconds ~behavior =
  simple ~host ~requests ~window_seconds ~behavior ()

let per_endpoint ~host ~method_ ~path ~requests ~window_seconds ~behavior =
  simple ~host ~method_ ~path ~requests ~window_seconds ~behavior ()

(* Host-scoped builder *)
type host_builder = { hb_host : string; routes : t list }

let for_host h = { hb_host = h; routes = [] }

let add_route r hb =
  let r_with_host = { r with host = Some hb.hb_host } in
  { hb with routes = hb.routes @ [ r_with_host ] }

let build_host hb = List.map build hb.routes
