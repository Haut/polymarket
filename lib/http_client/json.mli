(** JSON parsing and body building utilities. *)

(** {1 JSON Parsing} *)

val parse : (Yojson.Safe.t -> 'a) -> string -> ('a, string) result
(** Parse a JSON response using the provided parser function.
    @return [Ok value] on success, [Error msg] on parse failure *)

val parse_list : (Yojson.Safe.t -> 'a) -> string -> ('a list, string) result
(** Parse a JSON array response, applying parser to each element.
    @return [Ok list] on success, [Error msg] on parse failure *)

(** {1 JSON Body Builders} *)

val body : Yojson.Safe.t -> string
(** Convert JSON to string body *)

val obj : (string * Yojson.Safe.t) list -> Yojson.Safe.t
(** Build JSON object from field list *)

val string : string -> Yojson.Safe.t
(** Wrap string as JSON string *)

val list : ('a -> Yojson.Safe.t) -> 'a list -> string
(** Map items to JSON and serialize as array *)

val list_single_field : string -> string list -> string
(** Build JSON array of single-field objects. [list_single_field "token_id" ids]
    produces [[{"token_id": "id1"}, {"token_id": "id2"}, ...]] *)
