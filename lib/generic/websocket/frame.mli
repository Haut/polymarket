(** WebSocket frame encoding and decoding (RFC 6455).

    This module implements the binary frame format for WebSocket messages.
    Client frames must be masked; server frames are unmasked. *)

(** {1 Frame Opcodes} *)

module Opcode : sig
  type t = Continuation | Text | Binary | Close | Ping | Pong | Other of int

  val to_int : t -> int
  val of_int : int -> t
  val is_control : t -> bool
end

(** {1 Close Status Codes} *)

module Close_code : sig
  type t =
    | Normal
    | Going_away
    | Protocol_error
    | Unsupported_data
    | No_status
    | Abnormal
    | Invalid_payload
    | Policy_violation
    | Message_too_big
    | Missing_extension
    | Internal_error
    | Other of int

  val to_int : t -> int
  val of_int : int -> t
end

(** {1 Frame Type} *)

type t = { fin : bool; opcode : Opcode.t; payload : string }
(** A WebSocket frame *)

(** {1 Encoding/Decoding} *)

val encode : mask:bool -> t -> string
(** Encode a frame for sending. Client frames should use [mask:true]. *)

val decode : _ Eio.Flow.source -> t
(** Decode a frame from a flow. Blocks until a complete frame is received. *)

(** {1 Frame Constructors} *)

val text : ?fin:bool -> string -> t
(** Create a text frame. *)

val binary : ?fin:bool -> string -> t
(** Create a binary frame. *)

val ping : ?payload:string -> unit -> t
(** Create a ping frame. *)

val pong : ?payload:string -> unit -> t
(** Create a pong frame. *)

val close : ?code:Close_code.t -> ?reason:string -> unit -> t
(** Create a close frame. *)

(** {1 Masking} *)

val apply_mask : key:string -> string -> string
(** Apply XOR mask to a payload. Used for client-to-server message masking. *)
