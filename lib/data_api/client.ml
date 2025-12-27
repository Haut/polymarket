(** HTTP client for the Polymarket Data API.

    This module provides functions to interact with all public endpoints of the
    Polymarket Data API (https://data-api.polymarket.com). *)

open Types

(** {1 Client Configuration} *)

type t = Polymarket_http.Client.t

module H = Polymarket_http.Client
module P = Polymarket_common.Primitives

let default_base_url = "https://data-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~env ~rate_limiter () =
  H.create ~base_url ~sw ~env ~rate_limiter ()

(** {1 Health Endpoint} *)

let health_check t = [] |> H.get_json t "/" health_response_of_yojson

(** {1 Positions Endpoint} *)

let get_positions t ~user ?market ?event_id ?size_threshold ?redeemable
    ?mergeable ?limit ?offset ?sort_by ?sort_direction ?title () =
  [ ("user", [ P.Address.to_string user ]) ]
  |> H.add_list "market" P.Hash64.to_string market
  |> H.add_list "eventId" P.Pos_int.to_string event_id
  |> H.add_option "sizeThreshold" P.Nonneg_float.to_string size_threshold
  |> H.add_bool "redeemable" redeemable
  |> H.add_bool "mergeable" mergeable
  |> H.add_option "limit" P.Limit.to_string limit
  |> H.add_option "offset" P.Offset.to_string offset
  |> H.add_option "sortBy" Position_sort_by.to_string sort_by
  |> H.add_option "sortDirection" Sort_direction.to_string sort_direction
  |> H.add_option "title" P.Bounded_string.to_string title
  |> H.get_json_list t "/positions" position_of_yojson

(** {1 Trades Endpoint} *)

let get_trades t ?user ?market ?event_id ?side ?filter_type ?filter_amount
    ?taker_only ?limit ?offset () =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add_bool "takerOnly" taker_only
  |> H.add_option "filterType" Filter_type.to_string filter_type
  |> H.add_option "filterAmount" P.Nonneg_float.to_string filter_amount
  |> H.add_list "market" P.Hash64.to_string market
  |> H.add_list "eventId" P.Pos_int.to_string event_id
  |> H.add_option "user" P.Address.to_string user
  |> H.add_option "side" Side.to_string side
  |> H.get_json_list t "/trades" trade_of_yojson

(** {1 Activity Endpoint} *)

let get_activity t ~user ?market ?event_id ?activity_types ?side ?start_time
    ?end_time ?sort_by ?sort_direction ?limit ?offset () =
  [ ("user", [ P.Address.to_string user ]) ]
  |> H.add_option "limit" P.Limit.to_string limit
  |> H.add_option "offset" P.Offset.to_string offset
  |> H.add_list "market" P.Hash64.to_string market
  |> H.add_list "eventId" P.Pos_int.to_string event_id
  |> H.add_list "type" Activity_type.to_string activity_types
  |> H.add_option "start" P.Nonneg_int.to_string start_time
  |> H.add_option "end" P.Nonneg_int.to_string end_time
  |> H.add_option "sortBy" Activity_sort_by.to_string sort_by
  |> H.add_option "sortDirection" Sort_direction.to_string sort_direction
  |> H.add_option "side" Side.to_string side
  |> H.get_json_list t "/activity" activity_of_yojson

(** {1 Holders Endpoint} *)

let get_holders t ~market ?min_balance ?limit () =
  []
  |> H.add_option "limit" P.Holders_limit.to_string limit
  |> H.add_list "market" P.Hash64.to_string (Some market)
  |> H.add_option "minBalance" P.Min_balance.to_string min_balance
  |> H.get_json_list t "/holders" meta_holder_of_yojson

(** {1 Value Endpoint} *)

let get_value t ~user ?market () =
  [ ("user", [ P.Address.to_string user ]) ]
  |> H.add_list "market" P.Hash64.to_string market
  |> H.get_json_list t "/value" value_of_yojson

(** {1 Closed Positions Endpoint} *)

let get_closed_positions t ~user ?market ?event_id ?title ?sort_by
    ?sort_direction ?limit ?offset () =
  [ ("user", [ P.Address.to_string user ]) ]
  |> H.add_list "market" P.Hash64.to_string market
  |> H.add_option "title" P.Bounded_string.to_string title
  |> H.add_list "eventId" P.Pos_int.to_string event_id
  |> H.add_option "limit" P.Closed_positions_limit.to_string limit
  |> H.add_option "offset" P.Extended_offset.to_string offset
  |> H.add_option "sortBy" Closed_position_sort_by.to_string sort_by
  |> H.add_option "sortDirection" Sort_direction.to_string sort_direction
  |> H.get_json_list t "/closed-positions" closed_position_of_yojson

(** {1 Trader Leaderboard Endpoint} *)

let get_trader_leaderboard t ?category ?time_period ?order_by ?user ?user_name
    ?limit ?offset () =
  []
  |> H.add_option "category" Leaderboard_category.to_string category
  |> H.add_option "timePeriod" Time_period.to_string time_period
  |> H.add_option "orderBy" Leaderboard_order_by.to_string order_by
  |> H.add_option "user" P.Address.to_string user
  |> H.add "userName" user_name
  |> H.add_option "limit" P.Leaderboard_limit.to_string limit
  |> H.add_option "offset" P.Leaderboard_offset.to_string offset
  |> H.get_json_list t "/v1/leaderboard" trader_leaderboard_entry_of_yojson

(** {1 Traded Endpoint} *)

let get_traded t ~user () =
  [ ("user", [ P.Address.to_string user ]) ]
  |> H.get_json t "/traded" traded_of_yojson

(** {1 Open Interest Endpoint} *)

let get_open_interest t ?market () =
  []
  |> H.add_list "market" P.Hash64.to_string market
  |> H.get_json_list t "/oi" open_interest_of_yojson

(** {1 Live Volume Endpoint} *)

let get_live_volume t ~id () =
  [ ("id", [ P.Pos_int.to_string id ]) ]
  |> H.get_json_list t "/live-volume" live_volume_of_yojson

(** {1 Builder Leaderboard Endpoint} *)

let get_builder_leaderboard t ?time_period ?limit ?offset () =
  []
  |> H.add_option "timePeriod" Time_period.to_string time_period
  |> H.add_option "limit" P.Builder_limit.to_string limit
  |> H.add_option "offset" P.Leaderboard_offset.to_string offset
  |> H.get_json_list t "/v1/builders/leaderboard" leaderboard_entry_of_yojson

(** {1 Builder Volume Endpoint} *)

let get_builder_volume t ?time_period () =
  []
  |> H.add_option "timePeriod" Time_period.to_string time_period
  |> H.get_json_list t "/v1/builders/volume" builder_volume_entry_of_yojson
