(** Sports WebSocket message types for Polymarket.

    This module defines types for the Sports WebSocket streaming service, which
    broadcasts live sports match results. *)

(** {1 Sport Result} *)

type sport_result = {
  slug : string;
  live : bool option;
  ended : bool option;
  score : string option;
  period : string option;
  elapsed : string option;
  last_update : string option;
  finished_timestamp : string option;
  turn : string option;
}
[@@deriving yojson, show, eq]
(** A live sports match result update. Only [slug] is required. *)

(** {1 Message Type} *)

(** Parsed sports WebSocket message. *)
type message = Update of sport_result | Unknown of string
[@@deriving show, eq]

(** {1 Message Parsing} *)

val parse_message : string -> message list
(** Parse a raw WebSocket message into typed messages. Does not handle "ping" —
    that is handled at the client level. *)
