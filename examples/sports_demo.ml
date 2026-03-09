(** Live demo of the Polymarket Sports WebSocket client.

    This example connects to the sports channel and streams live match results.
    Run with: dune exec examples/sports_demo.exe

    Note: This connects to sports-api.polymarket.com/ws for streaming data. *)

open Polymarket

let handle_message (msg : Sports.Types.message) =
  match msg with
  | Update result ->
      let parts =
        [ Printf.sprintf "slug=%s" result.slug ]
        @ (match result.score with
          | Some s -> [ Printf.sprintf "score=%s" s ]
          | None -> [])
        @ (match result.period with
          | Some p -> [ Printf.sprintf "period=%s" p ]
          | None -> [])
        @ (match result.elapsed with
          | Some e -> [ Printf.sprintf "elapsed=%s" e ]
          | None -> [])
        @ (match result.live with
          | Some true -> [ "LIVE" ]
          | Some false -> [ "not live" ]
          | None -> [])
        @ match result.ended with Some true -> [ "ENDED" ] | _ -> []
      in
      Logger.ok "SPORT" (String.concat " " parts)
  | Unknown raw ->
      if String.length raw > 80 then
        Logger.skip "MSG" (String.sub raw 0 80 ^ "...")
      else Logger.skip "MSG" raw

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  Logger.info "Connecting to Sports channel (sports-api.polymarket.com/ws)";

  let client = Sports.connect ~sw ~net ~clock () in
  let stream = Sports.stream client in

  Logger.ok "CONNECTED" "Waiting for sport results...";

  let message_count = ref 0 in
  let max_messages = 20 in

  (try
     while !message_count < max_messages do
       match
         Eio.Time.with_timeout clock 30.0 (fun () ->
             Ok (Eio.Stream.take stream))
       with
       | Ok msg ->
           incr message_count;
           handle_message msg
       | Error `Timeout ->
           Logger.skip "TIMEOUT" "No message in 30s";
           message_count := max_messages
     done
   with
  | Eio.Cancel.Cancelled _ -> Logger.info "Cancelled"
  | exn -> Logger.error "EXCEPTION" (Printexc.to_string exn));

  Sports.close client;
  Logger.ok "CLOSED" "Sports stream closed";
  Logger.info (Printf.sprintf "Received %d messages" !message_count)

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
