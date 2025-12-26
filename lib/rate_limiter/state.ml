(** State management for rate limiting. *)

type route_key = string
type state_entry = { gcras : Gcra.t list; mutable last_used : float }

type t = {
  now : unit -> float;
  table : (route_key, state_entry) Hashtbl.t;
  mutex : Eio.Mutex.t;
  max_idle_time : float;
}

let create ~clock ?(max_idle_time = 300.0) () =
  let table = Hashtbl.create 64 in
  let mutex = Eio.Mutex.create () in
  let now () = Eio.Time.now clock in
  { now; table; mutex; max_idle_time }

let get_or_create_entry t ~route_key ~limits =
  let now_time = t.now () in
  match Hashtbl.find_opt t.table route_key with
  | Some entry ->
      entry.last_used <- now_time;
      entry
  | None ->
      let gcras = List.map Gcra.create limits in
      let entry = { gcras; last_used = now_time } in
      Hashtbl.add t.table route_key entry;
      entry

let check_limits t ~route_key ~limits =
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
      let now_time = t.now () in
      let entry = get_or_create_entry t ~route_key ~limits in
      (* Check all limits, collect maximum retry_after if any fail *)
      let rec check_all gcras max_retry =
        match gcras with
        | [] -> (
            match max_retry with
            | None ->
                (* All passed, update all states *)
                List.iter
                  (fun gcra -> Gcra.update gcra ~now:now_time)
                  entry.gcras;
                Ok ()
            | Some retry -> Error retry)
        | gcra :: rest -> (
            match Gcra.check gcra ~now:now_time with
            | Ok () -> check_all rest max_retry
            | Error retry ->
                let new_max =
                  match max_retry with
                  | None -> Some retry
                  | Some prev -> Some (Float.max prev retry)
                in
                check_all rest new_max)
      in
      check_all entry.gcras None)

let cleanup t =
  let now_time = t.now () in
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
      Hashtbl.filter_map_inplace
        (fun _key entry ->
          if now_time -. entry.last_used > t.max_idle_time then None
          else Some entry)
        t.table)

let state_count t = Eio.Mutex.use_ro t.mutex (fun () -> Hashtbl.length t.table)

let reset t =
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () -> Hashtbl.clear t.table)
