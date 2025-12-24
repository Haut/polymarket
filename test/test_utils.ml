(** Shared test utilities *)

(** Test roundtrip serialization for a list of values *)
let test_roundtrip ~to_json ~of_json ~equal ~to_string values =
  List.iter
    (fun v ->
      let json = to_json v in
      let result = of_json json in
      Alcotest.(check bool)
        (Printf.sprintf "%s roundtrip" (to_string v))
        true (equal v result))
    values

(** Test string conversion for a list of (value, expected_string) pairs *)
let test_string_conversions ~to_string pairs =
  List.iter
    (fun (value, expected) ->
      Alcotest.(check string) expected expected (to_string value))
    pairs

(** Check if a string contains a substring using Str library *)
let string_contains ~haystack ~needle =
  try
    let _ = Str.search_forward (Str.regexp_string needle) haystack 0 in
    true
  with Not_found -> false
