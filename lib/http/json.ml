(** JSON parsing and body building utilities. *)

let src = Logs.Src.create "http.json" ~doc:"JSON parsing"

module Log = (val Logs.src_log src : Logs.LOG)

(** Find the path to a specific JSON value within a larger JSON structure *)
let rec find_path_to_value ~target ~path json =
  if json == target then Some (List.rev path)
  else
    match json with
    | `Assoc fields ->
        List.find_map
          (fun (key, value) ->
            find_path_to_value ~target ~path:(key :: path) value)
          fields
    | `List items ->
        List.find_mapi
          (fun i item ->
            find_path_to_value ~target
              ~path:(Printf.sprintf "[%d]" i :: path)
              item)
          items
    | _ -> None

let format_path = function [] -> "<root>" | parts -> String.concat "." parts

(** {1 JSON Parsing} *)

let parse (parse_fn : Yojson.Safe.t -> 'a) (body : string) : ('a, string) result
    =
  let root_json = ref `Null in
  try
    let json = Yojson.Safe.from_string body in
    root_json := json;
    Ok (parse_fn json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, bad_json) ->
      let path =
        match find_path_to_value ~target:bad_json ~path:[] !root_json with
        | Some p -> format_path p
        | None -> "<unknown>"
      in
      let msg =
        Printf.sprintf "JSON parse error at field '%s': %s\nValue: %s" path
          (Printexc.to_string exn)
          (Yojson.Safe.to_string bad_json)
      in
      Log.err (fun m -> m "Parse error at %s: %s" path (Printexc.to_string exn));
      Error msg
  | Yojson.Json_error msg ->
      let err = "JSON error: " ^ msg ^ "\nBody:\n" ^ body in
      Log.err (fun m -> m "JSON error: %s" msg);
      Error err
  | exn ->
      let msg =
        Printf.sprintf "Parse error: %s\nFull response:\n%s"
          (Printexc.to_string exn) body
      in
      Log.err (fun m -> m "Error: %s" (Printexc.to_string exn));
      Error msg

let parse_list (parse_item_fn : Yojson.Safe.t -> 'a) (body : string) :
    ('a list, string) result =
  let root_json = ref `Null in
  try
    let json = Yojson.Safe.from_string body in
    root_json := json;
    match json with
    | `List items -> Ok (List.map parse_item_fn items)
    | _ ->
        let err = "Expected JSON array\nBody:\n" ^ body in
        Log.err (fun m -> m "Expected JSON array");
        Error err
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, bad_json) ->
      let path =
        match find_path_to_value ~target:bad_json ~path:[] !root_json with
        | Some p -> format_path p
        | None -> "<unknown>"
      in
      let msg =
        Printf.sprintf "JSON parse error at field '%s': %s\nValue: %s" path
          (Printexc.to_string exn)
          (Yojson.Safe.to_string bad_json)
      in
      Log.err (fun m -> m "Parse error at %s: %s" path (Printexc.to_string exn));
      Error msg
  | Yojson.Json_error msg ->
      let err = "JSON error: " ^ msg ^ "\nBody:\n" ^ body in
      Log.err (fun m -> m "JSON error: %s" msg);
      Error err
  | exn ->
      let msg =
        Printf.sprintf "Parse error: %s\nFull response:\n%s"
          (Printexc.to_string exn) body
      in
      Log.err (fun m -> m "Error: %s" (Printexc.to_string exn));
      Error msg

(** {1 JSON Body Builders} *)

let body (json : Yojson.Safe.t) : string = Yojson.Safe.to_string json
let obj (fields : (string * Yojson.Safe.t) list) : Yojson.Safe.t = `Assoc fields
let string (s : string) : Yojson.Safe.t = `String s

let list (f : 'a -> Yojson.Safe.t) (items : 'a list) : string =
  `List (List.map f items) |> body

let list_single_field (key : string) (items : string list) : string =
  list (fun v -> obj [ (key, string v) ]) items
