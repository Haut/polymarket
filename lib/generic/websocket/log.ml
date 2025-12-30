(** Structured logging for websocket library. *)

include Logger.Make (struct
  let name = "websocket"
  let doc = "WebSocket library"
end)
