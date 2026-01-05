(** Live demo of the Polymarket RFQ (Request for Quote) API client.

    This example demonstrates the RFQ API for large block trades:
    - Listing active RFQ requests from other traders
    - Listing quotes on your requests
    - Creating and canceling requests/quotes (requires funded account)

    Run with: dune exec examples/rfq_demo.exe

    Required environment variables:
    - POLY_PRIVATE_KEY: Your Ethereum private key (hex, without 0x prefix)
    - POLY_API_KEY: Your Polymarket API key
    - POLY_API_SECRET: Your Polymarket API secret
    - POLY_API_PASSPHRASE: Your Polymarket API passphrase

    Or the demo will use test credentials (read-only operations only). *)

open Polymarket

(** {1 Helper Functions} *)

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name (Rfq.Types.error_to_string err)

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let clock = Eio.Stdenv.clock env in

  Logger.info (Printf.sprintf "Starting RFQ API demo (%s)" Rfq.default_base_url);

  (* Check for credentials *)
  let private_key =
    let pk_str =
      match Sys.getenv_opt "POLY_PRIVATE_KEY" with
      | Some pk -> pk
      (* Well-known Foundry/Hardhat test account #0 - DO NOT use with real funds *)
      | None ->
          Logger.warn "CREDENTIAL"
            "Using test private key - set POLY_PRIVATE_KEY for real use";
          "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    in
    Clob.private_key_of_string pk_str
  in

  let credentials : Clob.credentials =
    match
      ( Sys.getenv_opt "POLY_API_KEY",
        Sys.getenv_opt "POLY_API_SECRET",
        Sys.getenv_opt "POLY_API_PASSPHRASE" )
    with
    | Some api_key, Some secret, Some passphrase ->
        { api_key; secret; passphrase }
    | _ ->
        Logger.warn "CREDENTIAL"
          "Using placeholder credentials - set POLY_API_KEY, POLY_API_SECRET, \
           POLY_API_PASSPHRASE for real use";
        (* Placeholder credentials - API calls will fail auth but structure is correct *)
        {
          api_key = "placeholder-key";
          secret = "placeholder-secret";
          passphrase = "placeholder-passphrase";
        }
  in

  (* Create shared rate limiter with Polymarket presets *)
  let routes =
    match Rate_limit_presets.all ~behavior:Rate_limiter.Delay with
    | Ok r -> r
    | Error msg -> failwith ("Rate limit preset error: " ^ msg)
  in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in

  (* Create the RFQ client - requires L2 authentication *)
  let rfq_client =
    match
      Rfq.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter ~private_key
        ~credentials ()
    with
    | Ok c -> c
    | Error e ->
        failwith
          ("RFQ client error: " ^ Polymarket_http.Client.string_of_init_error e)
  in

  Logger.info
    (Printf.sprintf "Client address: %s (L2 auth)" (Rfq.address rfq_client));

  (* ===== Request Endpoints ===== *)

  (* Get active requests - shows requests from all traders *)
  let requests =
    Rfq.get_requests rfq_client ~state:Rfq.Types.State_filter.Active ~limit:10
      ()
  in
  print_result "get_requests (active)" requests
    ~on_ok:(fun (r : Rfq.Types.get_requests_response) ->
      Printf.sprintf "%d requests, next_cursor=%s" (List.length r.data)
        (if r.next_cursor = "" then "(none)" else r.next_cursor));

  (* Show details of first request if available *)
  (match requests with
  | Ok r when List.length r.data > 0 ->
      let req = List.hd r.data in
      Logger.info
        (Printf.sprintf "Sample request: %s %s@%.4f size=%.2f"
           (Rfq.Types.P.Request_id.to_string req.request_id)
           (Rfq.Types.Side.to_string req.side)
           req.price req.size_in)
  | _ -> ());

  (* Get inactive (completed/canceled) requests *)
  let inactive_requests =
    Rfq.get_requests rfq_client ~state:Rfq.Types.State_filter.Inactive ~limit:5
      ()
  in
  print_result "get_requests (inactive)" inactive_requests
    ~on_ok:(fun (r : Rfq.Types.get_requests_response) ->
      Printf.sprintf "%d requests" (List.length r.data));

  (* ===== Quote Endpoints ===== *)

  (* Get active quotes *)
  let quotes =
    Rfq.get_quotes rfq_client ~state:Rfq.Types.State_filter.Active ~limit:10 ()
  in
  print_result "get_quotes (active)" quotes
    ~on_ok:(fun (q : Rfq.Types.get_quotes_response) ->
      Printf.sprintf "%d quotes" (List.length q.data));

  (* Show details of first quote if available *)
  (match quotes with
  | Ok q when List.length q.data > 0 ->
      let quote = List.hd q.data in
      Logger.info
        (Printf.sprintf "Sample quote: %s for request %s @%.4f size=%.2f"
           (Rfq.Types.P.Quote_id.to_string quote.quote_id)
           (Rfq.Types.P.Request_id.to_string quote.request_id)
           quote.price quote.size_in)
  | _ -> ());

  (* Get inactive quotes *)
  let inactive_quotes =
    Rfq.get_quotes rfq_client ~state:Rfq.Types.State_filter.Inactive ~limit:5 ()
  in
  print_result "get_quotes (inactive)" inactive_quotes
    ~on_ok:(fun (q : Rfq.Types.get_quotes_response) ->
      Printf.sprintf "%d quotes" (List.length q.data));

  (* ===== Filtering Examples ===== *)

  (* Filter by price range *)
  let price_filtered =
    Rfq.get_requests rfq_client ~price_min:0.3 ~price_max:0.7
      ~sort_by:Rfq.Types.Sort_by.Price ~sort_dir:Rfq.Types.Sort_dir.Desc ()
  in
  print_result "get_requests (price 0.3-0.7)" price_filtered
    ~on_ok:(fun (r : Rfq.Types.get_requests_response) ->
      Printf.sprintf "%d requests" (List.length r.data));

  (* Filter by size *)
  let size_filtered =
    Rfq.get_requests rfq_client ~size_min:100.0 ~sort_by:Rfq.Types.Sort_by.Size
      ()
  in
  print_result "get_requests (size >= 100)" size_filtered
    ~on_ok:(fun (r : Rfq.Types.get_requests_response) ->
      Printf.sprintf "%d requests" (List.length r.data));

  (* ===== Write Operations (Skipped) ===== *)
  Logger.skip "create_request" "requires funded account with token balance";
  Logger.skip "cancel_request" "requires active request ID";
  Logger.skip "create_quote" "requires active request to quote on";
  Logger.skip "cancel_quote" "requires active quote ID";
  Logger.skip "accept_quote" "requires signed order parameters";
  Logger.skip "approve_order" "requires maker approval for matched quote";

  (* ===== Summary ===== *)
  Logger.info "Demo complete"

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
