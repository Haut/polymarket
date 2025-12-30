(** JSON parsing and body building utilities. *)

let section = "JSON"

(** {1 JSON Parsing} *)

let parse (parse_fn : Yojson.Safe.t -> 'a) (body : string) : ('a, string) result
    =
  try
    let json = Yojson.Safe.from_string body in
    Ok (parse_fn json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      let msg =
        Printf.sprintf
          "JSON parse error: %s\nProblematic value: %s\nFull response:\n%s"
          (Printexc.to_string exn)
          (Yojson.Safe.to_string json)
          body
      in
      Logger.log_err ~section ~event:"PARSE_ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg
  | Yojson.Json_error msg ->
      let err = "JSON error: " ^ msg ^ "\nBody:\n" ^ body in
      Logger.log_err ~section ~event:"JSON_ERROR" [ ("error", msg) ];
      Error err
  | exn ->
      let msg =
        Printf.sprintf "Parse error: %s\nFull response:\n%s"
          (Printexc.to_string exn) body
      in
      Logger.log_err ~section ~event:"ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg

let parse_list (parse_item_fn : Yojson.Safe.t -> 'a) (body : string) :
    ('a list, string) result =
  try
    let json = Yojson.Safe.from_string body in
    match json with
    | `List items -> Ok (List.map parse_item_fn items)
    | _ ->
        let err = "Expected JSON array\nBody:\n" ^ body in
        Logger.log_err ~section ~event:"NOT_ARRAY"
          [ ("error", "Expected JSON array") ];
        Error err
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
      let msg =
        Printf.sprintf
          "JSON parse error: %s\nProblematic value: %s\nFull response:\n%s"
          (Printexc.to_string exn)
          (Yojson.Safe.to_string json)
          body
      in
      Logger.log_err ~section ~event:"PARSE_ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg
  | Yojson.Json_error msg ->
      let err = "JSON error: " ^ msg ^ "\nBody:\n" ^ body in
      Logger.log_err ~section ~event:"JSON_ERROR" [ ("error", msg) ];
      Error err
  | exn ->
      let msg =
        Printf.sprintf "Parse error: %s\nFull response:\n%s"
          (Printexc.to_string exn) body
      in
      Logger.log_err ~section ~event:"ERROR"
        [ ("error", Printexc.to_string exn) ];
      Error msg

(** {1 JSON Body Builders} *)

let body (json : Yojson.Safe.t) : string = Yojson.Safe.to_string json
let obj (fields : (string * Yojson.Safe.t) list) : Yojson.Safe.t = `Assoc fields
let string (s : string) : Yojson.Safe.t = `String s

let list (f : 'a -> Yojson.Safe.t) (items : 'a list) : string =
  `List (List.map f items) |> body

let list_single_field (key : string) (items : string list) : string =
  list (fun v -> obj [ (key, string v) ]) items
