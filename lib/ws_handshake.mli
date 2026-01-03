(** WebSocket handshake implementation (RFC 6455 Section 4).

    Performs HTTP/1.1 Upgrade handshake directly over a TLS flow. *)

(** {1 Types} *)

type result = Success | Failed of string  (** Handshake result *)

(** {1 Handshake} *)

val perform :
  flow:Tls_eio.t -> host:string -> port:int -> resource:string -> result
(** Perform WebSocket handshake over a TLS flow.

    Sends the HTTP Upgrade request and validates the server's response,
    including verification of the Sec-WebSocket-Accept header. *)
