(** Live demo of the Polymarket Bridge API client.

    This example demonstrates the Bridge API for cross-chain deposits. Run with:
    dune exec examples/bridge_api_demo.exe

    The Bridge API enables users to bridge assets from various chains (Ethereum,
    Solana, Arbitrum, Base, Bitcoin, etc.) to USDC.e on Polygon for trading on
    Polymarket. *)

open Polymarket

(** {1 Option monad syntax} *)

let ( let* ) = Option.bind

(** {1 Helper Functions} *)

let print_result name ~on_ok result =
  match result with
  | Ok value -> Logger.ok name (on_ok value)
  | Error err -> Logger.error name (Bridge.error_to_string err)

let print_result_count name result =
  match result with
  | Ok items -> Logger.ok name (Printf.sprintf "%d items" (List.length items))
  | Error err -> Logger.error name (Bridge.error_to_string err)

(** Print an optional value with a label *)
let print_optional label value =
  Option.iter (fun v -> Logger.info (Printf.sprintf "  %s: %s" label v)) value

(** Truncate a string to max_len characters, adding "..." if truncated *)
let truncate max_len s =
  if String.length s <= max_len then s else String.sub s 0 max_len ^ "..."

(** {1 Main Demo} *)

let run_demo env =
  Logger.setup ();
  Eio.Switch.run @@ fun sw ->
  let clock = Eio.Stdenv.clock env in

  Logger.info
    (Printf.sprintf "Starting Bridge API demo (%s)" Bridge.default_base_url);

  (* Create shared rate limiter with Polymarket presets *)
  let routes =
    match Rate_limit_presets.all ~behavior:Rate_limiter.Delay with
    | Ok r -> r
    | Error msg -> failwith ("Rate limit preset error: " ^ msg)
  in
  let rate_limiter = Rate_limiter.create ~routes ~clock () in
  let client =
    match Bridge.create ~sw ~net:(Eio.Stdenv.net env) ~rate_limiter () with
    | Ok c -> c
    | Error e ->
        failwith ("Bridge client error: " ^ Bridge.string_of_init_error e)
  in

  (* ===== Get Supported Assets ===== *)
  Logger.info "Fetching supported assets...";
  let supported_assets = Bridge.get_supported_assets client () in
  print_result_count "get_supported_assets" supported_assets;

  (* Print details about supported assets *)
  (match supported_assets with
  | Ok assets ->
      List.iter
        (fun (asset : Bridge.supported_asset) ->
          let chain_name = Option.value ~default:"Unknown" asset.chain_name in
          let chain_id = Option.value ~default:"?" asset.chain_id in
          let min_usd =
            match asset.min_checkout_usd with
            | Some v -> Printf.sprintf "$%.2f" (Primitives.Decimal.to_float v)
            | None -> "N/A"
          in
          let token_symbol =
            let* token = asset.token in
            token.symbol
          in
          let symbol = Option.value ~default:"?" token_symbol in
          Logger.info
            (Printf.sprintf "  Chain: %s (ID: %s) | Token: %s | Min: %s"
               chain_name chain_id symbol min_usd))
        assets
  | Error _ -> ());

  (* ===== Create Deposit Addresses ===== *)
  Logger.info "Creating deposit addresses...";

  (* Use a test address - in real usage this would be the user's Polymarket wallet *)
  let test_address = "0xa41249c581990c31fb2a0dfc4417ede58e0de774" in
  (match Primitives.Address.make test_address with
  | Ok address -> (
      let deposit = Bridge.create_deposit_addresses client ~address () in
      print_result "create_deposit_addresses" deposit
        ~on_ok:(fun (r : Bridge.deposit_response) ->
          match r.address with
          | Some (addrs : Bridge.deposit_addresses) ->
              let evm =
                Option.fold ~none:"N/A" ~some:Primitives.Address.to_string
                  addrs.evm
              in
              let svm = Option.value ~default:"N/A" addrs.svm in
              let btc = Option.value ~default:"N/A" addrs.btc in
              Printf.sprintf "EVM: %s | SVM: %s | BTC: %s" (truncate 20 evm)
                (truncate 10 svm) (truncate 10 btc)
          | None -> "(no addresses returned)");

      (* Print full deposit addresses *)
      match deposit with
      | Ok (resp : Bridge.deposit_response) -> (
          match resp.address with
          | Some (addrs : Bridge.deposit_addresses) ->
              Logger.info "Full deposit addresses:";
              print_optional "EVM"
                (Option.map Primitives.Address.to_string addrs.evm);
              print_optional "SVM" addrs.svm;
              print_optional "BTC" addrs.btc;
              print_optional "Note" resp.note
          | None -> Logger.info "No addresses in response")
      | Error _ -> ())
  | Error err ->
      Logger.error "create_deposit_addresses"
        (Printf.sprintf "Invalid address: %s"
           (Primitives.string_of_validation_error err)));

  (* ===== Summary ===== *)
  Logger.info "All Bridge API endpoints exercised"

let () =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run run_demo;
  Logger.close ()
