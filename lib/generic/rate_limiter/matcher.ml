(** Route matching for rate limiting. *)

let path_matches_prefix ~path ~prefix =
  if String.length prefix = 0 || prefix = "/" then true
  else
    (* Normalize: remove trailing slash from prefix for comparison *)
    let normalized_prefix =
      if String.ends_with ~suffix:"/" prefix then
        String.sub prefix 0 (String.length prefix - 1)
      else prefix
    in
    let prefix_len = String.length normalized_prefix in
    let path_len = String.length path in
    if String.starts_with ~prefix:normalized_prefix path then
      (* Exact match or followed by '/' or end of path *)
      prefix_len = path_len || (prefix_len < path_len && path.[prefix_len] = '/')
    else false

let matches_pattern ~method_ ~uri (pattern : Types.route_pattern) =
  let host_matches =
    match pattern.host with None -> true | Some h -> Uri.host uri = Some h
  in
  let method_matches =
    match pattern.method_ with
    | None -> true
    | Some m -> String.uppercase_ascii m = String.uppercase_ascii method_
  in
  let path_matches =
    match pattern.path_prefix with
    | None -> true
    | Some prefix ->
        let path = Uri.path uri in
        path_matches_prefix ~path ~prefix
  in
  host_matches && method_matches && path_matches

let find_matching_routes ~method_ ~uri routes =
  List.filter
    (fun (rc : Types.route_config) -> matches_pattern ~method_ ~uri rc.pattern)
    routes

let make_route_key ~method_ ~uri (pattern : Types.route_pattern) =
  let host = Option.value ~default:"*" (Uri.host uri) in
  let path = Option.value ~default:"/" pattern.path_prefix in
  (* Use pattern.method_ if specified, otherwise use actual request method *)
  let method_str = Option.value ~default:method_ pattern.method_ in
  Printf.sprintf "%s:%s:%s" host method_str path
