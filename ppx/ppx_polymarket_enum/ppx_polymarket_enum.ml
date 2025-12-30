(** PPX deriver for enum types with string conversion.

    Generates the full enum interface inline without any runtime dependencies.

    Usage:
    {[
      type t = Foo | Bar | Baz [@@deriving enum]
    ]}

    Generates UPPERCASE strings by default (Foo -> "FOO"). Case-insensitive
    parsing is enabled by default.

    For custom string mappings, use [@value]:
    {[
      type t = Min_1 [@value "1m"] | Hour_1 [@value "1h"] [@@deriving enum]
    ]}

    Generated functions:
    - to_string : t -> string
    - of_string : string -> t
    - of_string_opt : string -> t option
    - t_of_yojson : Yojson.Safe.t -> t
    - yojson_of_t : t -> Yojson.Safe.t
    - pp : Format.formatter -> t -> unit
    - show : t -> string
    - equal : t -> t -> bool *)

open Ppxlib

(** Extract custom value from [@value "..."] attribute on a constructor *)
let get_custom_value attrs =
  List.find_map
    (fun attr ->
      match attr.attr_name.txt with
      | "value" -> (
          match attr.attr_payload with
          | PStr
              [
                {
                  pstr_desc =
                    Pstr_eval
                      ( {
                          pexp_desc = Pexp_constant (Pconst_string (s, _, _));
                          _;
                        },
                        _ );
                  _;
                };
              ] ->
              Some s
          | _ -> None)
      | _ -> None)
    attrs

(** Convert constructor name to UPPERCASE string (default convention) *)
let constructor_to_uppercase name = String.uppercase_ascii name

(** Generate the to_string function as a pattern match *)
let generate_to_string ~loc constructors =
  let cases =
    List.map
      (fun (name, attrs, _args) ->
        let str_value =
          match get_custom_value attrs with
          | Some custom -> custom
          | None -> constructor_to_uppercase name
        in
        let lhs =
          Ast_builder.Default.ppat_construct ~loc
            (Ast_builder.Default.Located.lident ~loc name)
            None
        in
        let rhs = Ast_builder.Default.estring ~loc str_value in
        Ast_builder.Default.case ~lhs ~guard:None ~rhs)
      constructors
  in
  [%expr fun t -> [%e Ast_builder.Default.pexp_match ~loc [%expr t] cases]]

(** Generate the of_string_opt function with case-insensitive matching *)
let generate_of_string_opt ~loc constructors =
  (* For each constructor, generate pattern cases for all case variations *)
  let cases =
    List.concat_map
      (fun (name, attrs, _args) ->
        let str_value =
          match get_custom_value attrs with
          | Some custom -> custom
          | None -> constructor_to_uppercase name
        in
        (* Generate case variations: original, lowercase, uppercase *)
        let variants =
          [
            str_value;
            String.lowercase_ascii str_value;
            String.uppercase_ascii str_value;
          ]
          |> List.sort_uniq String.compare
        in
        let ctor_expr =
          [%expr
            Some
              [%e
                Ast_builder.Default.pexp_construct ~loc
                  (Ast_builder.Default.Located.lident ~loc name)
                  None]]
        in
        List.map
          (fun variant ->
            let lhs = Ast_builder.Default.pstring ~loc variant in
            Ast_builder.Default.case ~lhs ~guard:None ~rhs:ctor_expr)
          variants)
      constructors
  in
  (* Add the catch-all None case *)
  let default_case =
    Ast_builder.Default.case
      ~lhs:(Ast_builder.Default.ppat_any ~loc)
      ~guard:None ~rhs:[%expr None]
  in
  [%expr
    fun s ->
      [%e
        Ast_builder.Default.pexp_match ~loc [%expr s] (cases @ [ default_case ])]]

(** Main structure generator for the deriver *)
let generate_impl ~ctxt (_rec_flag, type_declarations) =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  List.concat_map
    (fun (td : type_declaration) ->
      match td.ptype_kind with
      | Ptype_variant constructors ->
          (* Extract constructor info: (name, attributes, args) *)
          let ctor_info =
            List.map
              (fun (cd : constructor_declaration) ->
                (cd.pcd_name.txt, cd.pcd_attributes, cd.pcd_args))
              constructors
          in
          (* Check that all constructors have no arguments *)
          List.iter
            (fun (name, _, args) ->
              match args with
              | Pcstr_tuple [] -> ()
              | _ ->
                  Location.raise_errorf ~loc:td.ptype_loc
                    "[@@deriving enum] only supports constructors without \
                     arguments, but %s has arguments"
                    name)
            ctor_info;
          (* Generate to_string and of_string_opt *)
          let to_string_expr = generate_to_string ~loc ctor_info in
          let of_string_opt_expr = generate_of_string_opt ~loc ctor_info in
          (* Generate all functions inline - no external dependencies *)
          [%str
            let to_string = [%e to_string_expr]
            let of_string_opt = [%e of_string_opt_expr]

            let of_string s =
              match of_string_opt s with
              | Some v -> v
              | None -> failwith ("Unknown enum value: " ^ s)

            let t_of_yojson = function
              | `String s -> of_string s
              | _ -> failwith "Expected string for enum"

            let yojson_of_t t = `String (to_string t)
            let pp fmt t = Format.fprintf fmt "%s" (to_string t)
            let show = to_string
            let equal a b = String.equal (to_string a) (to_string b)]
      | _ ->
          Location.raise_errorf ~loc:td.ptype_loc
            "[@@deriving enum] can only be applied to variant types")
    type_declarations

(** Register the deriver *)
let impl_generator = Deriving.Generator.V2.make_noarg generate_impl

let my_deriver = Deriving.add "enum" ~str_type_decl:impl_generator
