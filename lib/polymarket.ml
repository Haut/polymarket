(* Polymarket OCaml client library *)

(** Generic HTTP client for all Polymarket APIs *)
module Http_client = Http_client

(** Re-export Data API modules for convenience *)
module Data_api_types = Data_api_types
module Data_api_params = Data_api_params
module Data_api_client = Data_api_client
