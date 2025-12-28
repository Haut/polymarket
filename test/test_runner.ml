(** Test runner for Polymarket library *)

let prefix_tests prefix tests =
  List.map (fun (name, cases) -> (prefix ^ ": " ^ name, cases)) tests

let () =
  Mirage_crypto_rng_unix.use_default ();
  Alcotest.run "Polymarket"
    (List.concat
       [
         (* Common module tests *)
         prefix_tests "Common.Http_client" Test_common.Test_http_client.tests;
         prefix_tests "Common.Primitives" Test_common.Test_primitives.tests;
         (* Data API tests *)
         prefix_tests "Data_api.Types" Test_data_api.Test_types.tests;
         (* Gamma API tests *)
         prefix_tests "Gamma_api.Types" Test_gamma_api.Test_types.tests;
         (* CLOB API tests *)
         prefix_tests "Clob_api.Types" Test_clob_api.Test_types.tests;
         Test_clob_api.Test_crypto.tests;
         (* WebSocket client tests *)
         prefix_tests "Wss.Frame" Test_websocket_client.Test_frame.tests;
         prefix_tests "Wss.Types" Test_websocket_client.Test_types.tests;
       ])
