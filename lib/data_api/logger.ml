(** Data API logging. *)

let src = Logs.Src.create "polymarket.data" ~doc:"Polymarket Data API"

module Log = (val Logs.src_log src : Logs.LOG)

let info msg = Log.info (fun m -> m "%s" msg)
let debug msg = Log.debug (fun m -> m "%s" msg)
let warn msg = Log.warn (fun m -> m "%s" msg)
let err msg = Log.err (fun m -> m "%s" msg)
