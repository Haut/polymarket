(** Test runner for Polymarket library *)

let prefix_tests prefix tests =
  List.map (fun (name, cases) -> (prefix ^ ": " ^ name, cases)) tests

let () =
  Alcotest.run "Polymarket"
    (List.concat
       [
         (* Common module tests *)
         prefix_tests "Common.Http_client" Test_common.Test_http_client.tests;
         (* Data API tests *)
         prefix_tests "Data_api.Types" Test_data_api.Test_types.tests;
         prefix_tests "Data_api.Params" Test_data_api.Test_params.tests;
       ])
