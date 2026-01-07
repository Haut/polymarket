(** Terminal live orderbook demo.

    This example builds a terminal-based live orderbook display for 15m BTC
    markets. Run with: dune exec examples/test_demo.exe *)

open Polymarket

(** {1 Orderbook State} *)

type orderbook = {
  bids : (string, string) Hashtbl.t;
  asks : (string, string) Hashtbl.t;
}

let create_orderbook () = { bids = Hashtbl.create 64; asks = Hashtbl.create 64 }

(** Parse token IDs from clob_token_ids JSON string *)
let parse_token_ids s =
  try
    match Yojson.Safe.from_string s with
    | `List items ->
        List.filter_map (function `String id -> Some id | _ -> None) items
    | _ -> []
  with Yojson.Json_error msg ->
    Logger.warn "PARSE" ("Failed to parse token IDs: " ^ msg);
    []

(** Compare prices as floats. Returns None if either price is invalid. *)
let compare_prices_opt p1 p2 =
  match (float_of_string_opt p1, float_of_string_opt p2) with
  | Some f1, Some f2 -> Some (Float.compare f1 f2)
  | _ -> None

(** Compare prices as floats, treating invalid prices as less than valid ones *)
let compare_prices p1 p2 =
  match compare_prices_opt p1 p2 with
  | Some cmp -> cmp
  | None ->
      (* Invalid prices sort to the bottom *)
      let valid1 = Option.is_some (float_of_string_opt p1) in
      let valid2 = Option.is_some (float_of_string_opt p2) in
      Bool.compare valid1 valid2

(** Get best bid (highest) from orderbook *)
let get_best_bid book =
  Hashtbl.to_seq book.bids
  |> Seq.fold_left
       (fun best (price, _) ->
         match best with
         | None -> Some price
         | Some b -> if compare_prices price b > 0 then Some price else best)
       None

(** Get best ask (lowest) from orderbook *)
let get_best_ask book =
  Hashtbl.to_seq book.asks
  |> Seq.fold_left
       (fun best (price, _) ->
         match best with
         | None -> Some price
         | Some a -> if compare_prices price a < 0 then Some price else best)
       None

(** Format orderbook display - compact single line *)
let format_orderbook book =
  let best_bid = get_best_bid book in
  let best_ask = get_best_ask book in
  let bid_str = Option.value ~default:"-" best_bid in
  let ask_str = Option.value ~default:"-" best_ask in
  let spread =
    match (best_bid, best_ask) with
    | Some b, Some a -> (
        match (float_of_string_opt b, float_of_string_opt a) with
        | Some bf, Some af -> Printf.sprintf "%.2f" ((af -. bf) *. 100.0)
        | _ -> "-")
    | _ -> "-"
  in
  let bid_depth = Hashtbl.length book.bids in
  let ask_depth = Hashtbl.length book.asks in
  Printf.sprintf "bid=%s ask=%s spread=%s¢ depth=%d/%d" bid_str ask_str spread
    bid_depth ask_depth

(** Apply a book snapshot to the orderbook, only if asset_id matches *)
let apply_book_snapshot ~token_id book (msg : Wss.Types.book_message) =
  if msg.asset_id = token_id then begin
    Hashtbl.clear book.bids;
    Hashtbl.clear book.asks;
    List.iter
      (fun (o : Wss.Types.order_summary) ->
        Hashtbl.replace book.bids o.price o.size)
      msg.bids;
    List.iter
      (fun (o : Wss.Types.order_summary) ->
        Hashtbl.replace book.asks o.price o.size)
      msg.asks
  end

(** Apply price changes to the orderbook, filtering by asset_id. *)
let apply_price_changes ~token_id book (msg : Wss.Types.price_change_message) =
  List.iter
    (fun (pc : Wss.Types.price_change_entry) ->
      if pc.asset_id = token_id then
        let tbl_opt =
          if pc.side = "BUY" then Some book.bids
          else if pc.side = "SELL" then Some book.asks
          else (
            Logger.warn "SIDE" ("Unknown side: " ^ pc.side);
            None)
        in
        Option.iter
          (fun tbl ->
            if pc.size = "0" then Hashtbl.remove tbl pc.price
            else Hashtbl.replace tbl pc.price pc.size)
          tbl_opt)
    msg.price_changes

(** Apply REST orderbook snapshot to the book *)
let apply_rest_snapshot book (initial : Clob.Types.order_book_summary) =
  List.iter
    (fun (lvl : Clob.Types.order_book_level) ->
      match (lvl.price, lvl.size) with
      | Some p, Some s -> Hashtbl.replace book.bids p s
      | _ -> ())
    initial.bids;
  List.iter
    (fun (lvl : Clob.Types.order_book_level) ->
      match (lvl.price, lvl.size) with
      | Some p, Some s -> Hashtbl.replace book.asks p s
      | _ -> ())
    initial.asks

(** {1 Main} *)

let run env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let clock = Eio.Stdenv.clock env in

  (* Create rate limiter *)
  let routes =
    match Rate_limit_presets.all ~behavior:Rate_limiter.Delay with
    | Ok r -> r
    | Error msg -> failwith ("Rate limit preset error: " ^ msg)
  in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in

  (* Create Gamma client *)
  let gamma_client =
    match Gamma.create ~sw ~net ~rate_limiter () with
    | Ok c -> c
    | Error e -> failwith ("Gamma client error: " ^ Gamma.string_of_init_error e)
  in

  (* Find current 15m BTC market *)
  let now = Ptime_clock.now () in
  let now_ts = Primitives.Timestamp.of_ptime now in
  Logger.info "Finding current 15m BTC market...";

  match
    Gamma.get_events gamma_client ~limit:200 ~active:true ~end_date_min:now_ts
      ~order:[ "endDate" ] ~ascending:true ()
  with
  | Error err -> Logger.error "GAMMA" (Gamma.error_to_string err)
  | Ok all_events -> (
      let events =
        List.filter
          (fun (e : Gamma.event) ->
            match (e.slug, e.end_date) with
            | Some s, Some end_ts ->
                String.starts_with ~prefix:"btc-updown-15m" s
                && Ptime.compare (Primitives.Timestamp.to_ptime end_ts) now > 0
            | _ -> false)
          all_events
      in

      match events with
      | [] -> Logger.error "MARKET" "No active 15m BTC markets found"
      | event :: _ -> (
          let title = Option.value ~default:"BTC 15m" event.title in
          Logger.ok "MARKET" title;

          match event.markets with
          | [] -> Logger.error "MARKET" "No markets in event"
          | market :: _ -> (
              match market.clob_token_ids with
              | None -> Logger.error "MARKET" "No token IDs in market"
              | Some token_ids_json -> (
                  match parse_token_ids token_ids_json with
                  | [] -> Logger.error "MARKET" "Could not parse token IDs"
                  | yes_token :: _ ->
                      let token_preview =
                        if String.length yes_token > 24 then
                          String.sub yes_token 0 24 ^ "..."
                        else yes_token
                      in
                      Logger.ok "TOKEN" token_preview;

                      (* Create CLOB client *)
                      let clob_client =
                        match
                          Clob.Unauthed.create ~sw ~net ~rate_limiter ()
                        with
                        | Ok c -> c
                        | Error e ->
                            failwith
                              ("CLOB client error: "
                              ^ Clob.init_error_to_string e)
                      in

                      let book = create_orderbook () in

                      (* Connect to WebSocket first to minimize race window *)
                      Logger.info "Connecting to WebSocket...";
                      let wss_client =
                        Wss.Market.connect ~sw ~net ~clock
                          ~asset_ids:[ yes_token ] ()
                      in
                      let stream = Wss.Market.stream wss_client in
                      Logger.ok "WSS" "Connected";

                      (* Buffer early messages while fetching REST snapshot *)
                      let early_messages = ref [] in
                      let drain_available () =
                        let rec drain () =
                          match Eio.Stream.take_nonblocking stream with
                          | None -> ()
                          | Some msg ->
                              early_messages := msg :: !early_messages;
                              drain ()
                        in
                        drain ()
                      in

                      (* Fetch REST snapshot (WebSocket may receive updates meanwhile) *)
                      (match
                         Clob.Unauthed.get_order_book clob_client
                           ~token_id:yes_token ()
                       with
                      | Error err ->
                          Logger.warn "INIT_BOOK" (Clob.error_to_string err)
                      | Ok initial ->
                          apply_rest_snapshot book initial;
                          Logger.ok "INIT_BOOK"
                            (Printf.sprintf "%d bids, %d asks"
                               (Hashtbl.length book.bids)
                               (Hashtbl.length book.asks)));

                      (* Drain any messages that arrived during REST fetch *)
                      drain_available ();
                      let buffered_count = List.length !early_messages in
                      if buffered_count > 0 then
                        Logger.info
                          (Printf.sprintf "Applying %d buffered updates"
                             buffered_count);

                      (* Apply buffered messages in order (oldest first) *)
                      List.iter
                        (function
                          | Wss.Types.Market (Book msg) ->
                              apply_book_snapshot ~token_id:yes_token book msg
                          | Wss.Types.Market (Price_change msg) ->
                              apply_price_changes ~token_id:yes_token book msg
                          | _ -> ())
                        (List.rev !early_messages);

                      Logger.ok "STREAM" "Streaming updates (Ctrl+C to stop)";

                      (* Main loop - process updates *)
                      let update_count = ref buffered_count in
                      let last_display = ref "" in
                      let log_if_changed label =
                        let display = format_orderbook book in
                        if display <> !last_display then begin
                          last_display := display;
                          Logger.ok label display
                        end
                      in

                      (* Use Fun.protect to ensure WebSocket is always closed *)
                      Fun.protect
                        ~finally:(fun () ->
                          Wss.Market.close wss_client;
                          Logger.info
                            (Printf.sprintf "Closed. Total updates: %d"
                               !update_count))
                        (fun () ->
                          try
                            while true do
                              match
                                Eio.Time.with_timeout clock 60.0 (fun () ->
                                    Ok (Eio.Stream.take stream))
                              with
                              | Ok (Wss.Types.Market (Book msg)) ->
                                  incr update_count;
                                  apply_book_snapshot ~token_id:yes_token book
                                    msg;
                                  log_if_changed "SNAPSHOT"
                              | Ok (Wss.Types.Market (Price_change msg)) ->
                                  incr update_count;
                                  apply_price_changes ~token_id:yes_token book
                                    msg;
                                  log_if_changed "UPDATE"
                              | Ok (Wss.Types.Market (Last_trade_price trade))
                                when trade.asset_id = yes_token ->
                                  Logger.ok "TRADE"
                                    (Printf.sprintf "%s @ %s (%s)" trade.side
                                       trade.price trade.size)
                              | Ok (Wss.Types.Market (Last_trade_price _)) -> ()
                              | Ok (Wss.Types.Market (Best_bid_ask _)) -> ()
                              | Ok _ -> ()
                              | Error `Timeout ->
                                  Logger.warn "TIMEOUT" "No updates in 60s";
                                  raise Exit
                            done
                          with
                          | Exit -> ()
                          | Eio.Cancel.Cancelled _ -> Logger.info "Cancelled")))
          ))

let () =
  Mirage_crypto_rng_unix.use_default ();
  Fun.protect ~finally:Logger.close (fun () -> Eio_main.run run)
