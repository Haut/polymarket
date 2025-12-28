(** Endpoint implementations for the Polymarket Data API.

    This module provides functions to interact with all public endpoints of the
    Polymarket Data API (https://data-api.polymarket.com). *)

open Types
module B = Polymarket_http.Builder
module P = Polymarket_common.Primitives

type t = Polymarket_http.Client.t

(** {1 Health Endpoint} *)

let health_check t = B.new_get t "/" |> B.fetch_json health_response_of_yojson

(** {1 Positions Endpoint} *)

let get_positions t ~user ?market ?event_id ?size_threshold ?redeemable
    ?mergeable ?limit ?offset ?sort_by ?sort_direction ?title () =
  B.new_get t "/positions"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_list "eventId" P.Pos_int.to_string event_id
  |> B.query_option "sizeThreshold" P.Nonneg_float.to_string size_threshold
  |> B.query_bool "redeemable" redeemable
  |> B.query_bool "mergeable" mergeable
  |> B.query_option "limit" P.Limit.to_string limit
  |> B.query_option "offset" P.Offset.to_string offset
  |> B.query_option "sortBy" Position_sort_by.to_string sort_by
  |> B.query_option "sortDirection" Sort_direction.to_string sort_direction
  |> B.query_option "title" P.Bounded_string.to_string title
  |> B.fetch_json_list position_of_yojson

(** {1 Trades Endpoint} *)

let get_trades t ?user ?market ?event_id ?side ?filter_type ?filter_amount
    ?taker_only ?limit ?offset () =
  B.new_get t "/trades"
  |> B.query_option "limit" P.Nonneg_int.to_string limit
  |> B.query_option "offset" P.Nonneg_int.to_string offset
  |> B.query_bool "takerOnly" taker_only
  |> B.query_option "filterType" Filter_type.to_string filter_type
  |> B.query_option "filterAmount" P.Nonneg_float.to_string filter_amount
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_list "eventId" P.Pos_int.to_string event_id
  |> B.query_option "user" P.Address.to_string user
  |> B.query_option "side" Side.to_string side
  |> B.fetch_json_list trade_of_yojson

(** {1 Activity Endpoint} *)

let get_activity t ~user ?market ?event_id ?activity_types ?side ?start_time
    ?end_time ?sort_by ?sort_direction ?limit ?offset () =
  B.new_get t "/activity"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_option "limit" P.Limit.to_string limit
  |> B.query_option "offset" P.Offset.to_string offset
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_list "eventId" P.Pos_int.to_string event_id
  |> B.query_list "type" Activity_type.to_string activity_types
  |> B.query_option "start" P.Nonneg_int.to_string start_time
  |> B.query_option "end" P.Nonneg_int.to_string end_time
  |> B.query_option "sortBy" Activity_sort_by.to_string sort_by
  |> B.query_option "sortDirection" Sort_direction.to_string sort_direction
  |> B.query_option "side" Side.to_string side
  |> B.fetch_json_list activity_of_yojson

(** {1 Holders Endpoint} *)

let get_holders t ~market ?min_balance ?limit () =
  B.new_get t "/holders"
  |> B.query_option "limit" P.Holders_limit.to_string limit
  |> B.query_list "market" P.Hash64.to_string (Some market)
  |> B.query_option "minBalance" P.Min_balance.to_string min_balance
  |> B.fetch_json_list meta_holder_of_yojson

(** {1 Value Endpoint} *)

let get_value t ~user ?market () =
  B.new_get t "/value"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_list "market" P.Hash64.to_string market
  |> B.fetch_json_list value_of_yojson

(** {1 Closed Positions Endpoint} *)

let get_closed_positions t ~user ?market ?event_id ?title ?sort_by
    ?sort_direction ?limit ?offset () =
  B.new_get t "/closed-positions"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_option "title" P.Bounded_string.to_string title
  |> B.query_list "eventId" P.Pos_int.to_string event_id
  |> B.query_option "limit" P.Closed_positions_limit.to_string limit
  |> B.query_option "offset" P.Extended_offset.to_string offset
  |> B.query_option "sortBy" Closed_position_sort_by.to_string sort_by
  |> B.query_option "sortDirection" Sort_direction.to_string sort_direction
  |> B.fetch_json_list closed_position_of_yojson

(** {1 Trader Leaderboard Endpoint} *)

let get_trader_leaderboard t ?category ?time_period ?order_by ?user ?user_name
    ?limit ?offset () =
  B.new_get t "/v1/leaderboard"
  |> B.query_option "category" Leaderboard_category.to_string category
  |> B.query_option "timePeriod" Time_period.to_string time_period
  |> B.query_option "orderBy" Leaderboard_order_by.to_string order_by
  |> B.query_option "user" P.Address.to_string user
  |> B.query_add "userName" user_name
  |> B.query_option "limit" P.Leaderboard_limit.to_string limit
  |> B.query_option "offset" P.Leaderboard_offset.to_string offset
  |> B.fetch_json_list trader_leaderboard_entry_of_yojson

(** {1 Traded Endpoint} *)

let get_traded t ~user () =
  B.new_get t "/traded"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.fetch_json traded_of_yojson

(** {1 Open Interest Endpoint} *)

let get_open_interest t ?market () =
  B.new_get t "/oi"
  |> B.query_list "market" P.Hash64.to_string market
  |> B.fetch_json_list open_interest_of_yojson

(** {1 Live Volume Endpoint} *)

let get_live_volume t ~id () =
  B.new_get t "/live-volume"
  |> B.query_param "id" (P.Pos_int.to_string id)
  |> B.fetch_json_list live_volume_of_yojson

(** {1 Builder Leaderboard Endpoint} *)

let get_builder_leaderboard t ?time_period ?limit ?offset () =
  B.new_get t "/v1/builders/leaderboard"
  |> B.query_option "timePeriod" Time_period.to_string time_period
  |> B.query_option "limit" P.Builder_limit.to_string limit
  |> B.query_option "offset" P.Leaderboard_offset.to_string offset
  |> B.fetch_json_list leaderboard_entry_of_yojson

(** {1 Builder Volume Endpoint} *)

let get_builder_volume t ?time_period () =
  B.new_get t "/v1/builders/volume"
  |> B.query_option "timePeriod" Time_period.to_string time_period
  |> B.fetch_json_list builder_volume_entry_of_yojson
