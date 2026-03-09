(** Sports WebSocket message types for Polymarket.

    This module defines types for the Sports WebSocket streaming service, which
    broadcasts live sports match results. *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Sport Result} *)

type sport_result = {
  slug : string;
  live : bool option; [@default None]
  ended : bool option; [@default None]
  score : string option; [@default None]
  period : string option; [@default None]
  elapsed : string option; [@default None]
  last_update : string option; [@key "last_update"] [@default None]
  finished_timestamp : string option;
      [@key "finished_timestamp"] [@default None]
  turn : string option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** A live sports match result update. Only [slug] is required. *)

(** {1 Message Type} *)

(** Parsed sports WebSocket message. *)
type message = Update of sport_result | Unknown of string
[@@deriving show, eq]

(** {1 Message Parsing} *)

let parse_message (raw : string) : message list =
  try
    let json = Yojson.Safe.from_string raw in
    [ Update (sport_result_of_yojson json) ]
  with exn ->
    [ Unknown (Printf.sprintf "Parse error: %s" (Printexc.to_string exn)) ]
