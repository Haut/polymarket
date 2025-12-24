(* Polymarket OCaml client library *)

module Common = Common
(** Common utilities shared across all Polymarket APIs *)

module Http_client = Http_client
(** HTTP client utilities for making API requests *)

module Data_api = Data_api
(** Data API client for positions, trades, activity, and leaderboards *)

module Gamma_api = Gamma_api
(** Gamma API client for markets, events, series, and search *)
