(** Data API client for positions, trades, activity, and leaderboards. *)

module B = Polymarket_http.Builder
module P = Polymarket_common.Primitives
include Types

type t = Polymarket_http.Client.t

let default_base_url = "https://data-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
  Polymarket_http.Client.create ~base_url ~sw ~net ~rate_limiter ()

(** {1 Health Endpoint} *)

let health_check t =
  B.new_get t "/"
  |> B.fetch_json ~expected_fields:yojson_fields_of_health_response
       ~context:"health_response" health_response_of_yojson

(** {1 Positions Endpoint} *)

let get_positions t ~user ?market ?event_id ?size_threshold ?redeemable
    ?mergeable ?limit ?offset ?sort_by ?sort_direction ?title () =
  B.new_get t "/positions"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_list "eventId" string_of_int event_id
  |> B.query_option "sizeThreshold" string_of_float size_threshold
  |> B.query_bool "redeemable" redeemable
  |> B.query_bool "mergeable" mergeable
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "offset" string_of_int offset
  |> B.query_option "sortBy" Position_sort_by.to_string sort_by
  |> B.query_option "sortDirection" Sort_direction.to_string sort_direction
  |> B.query_add "title" title
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_position
       ~context:"position" position_of_yojson

(** {1 Trades Endpoint} *)

let get_trades t ?user ?market ?event_id ?side ?filter_type ?filter_amount
    ?taker_only ?limit ?offset () =
  B.new_get t "/trades"
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "offset" string_of_int offset
  |> B.query_bool "takerOnly" taker_only
  |> B.query_option "filterType" Filter_type.to_string filter_type
  |> B.query_option "filterAmount" string_of_float filter_amount
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_list "eventId" string_of_int event_id
  |> B.query_option "user" P.Address.to_string user
  |> B.query_option "side" Side.to_string side
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_trade ~context:"trade"
       trade_of_yojson

(** {1 Activity Endpoint} *)

let get_activity t ~user ?market ?event_id ?activity_types ?side ?start_time
    ?end_time ?sort_by ?sort_direction ?limit ?offset () =
  B.new_get t "/activity"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "offset" string_of_int offset
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_list "eventId" string_of_int event_id
  |> B.query_list "type" Activity_type.to_string activity_types
  |> B.query_option "start" string_of_int start_time
  |> B.query_option "end" string_of_int end_time
  |> B.query_option "sortBy" Activity_sort_by.to_string sort_by
  |> B.query_option "sortDirection" Sort_direction.to_string sort_direction
  |> B.query_option "side" Side.to_string side
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_activity
       ~context:"activity" activity_of_yojson

(** {1 Holders Endpoint} *)

let get_holders t ~market ?min_balance ?limit () =
  B.new_get t "/holders"
  |> B.query_option "limit" string_of_int limit
  |> B.query_list "market" P.Hash64.to_string (Some market)
  |> B.query_option "minBalance" string_of_int min_balance
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_meta_holder
       ~context:"meta_holder" meta_holder_of_yojson

(** {1 Value Endpoint} *)

let get_value t ~user ?market () =
  B.new_get t "/value"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_list "market" P.Hash64.to_string market
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_value ~context:"value"
       value_of_yojson

(** {1 Closed Positions Endpoint} *)

let get_closed_positions t ~user ?market ?event_id ?title ?sort_by
    ?sort_direction ?limit ?offset () =
  B.new_get t "/closed-positions"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.query_list "market" P.Hash64.to_string market
  |> B.query_add "title" title
  |> B.query_list "eventId" string_of_int event_id
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "offset" string_of_int offset
  |> B.query_option "sortBy" Closed_position_sort_by.to_string sort_by
  |> B.query_option "sortDirection" Sort_direction.to_string sort_direction
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_closed_position
       ~context:"closed_position" closed_position_of_yojson

(** {1 Trader Leaderboard Endpoint} *)

let get_trader_leaderboard t ?category ?time_period ?order_by ?user ?user_name
    ?limit ?offset () =
  B.new_get t "/v1/leaderboard"
  |> B.query_option "category" Leaderboard_category.to_string category
  |> B.query_option "timePeriod" Time_period.to_string time_period
  |> B.query_option "orderBy" Leaderboard_order_by.to_string order_by
  |> B.query_option "user" P.Address.to_string user
  |> B.query_add "userName" user_name
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "offset" string_of_int offset
  |> B.fetch_json_list
       ~expected_fields:yojson_fields_of_trader_leaderboard_entry
       ~context:"trader_leaderboard_entry" trader_leaderboard_entry_of_yojson

(** {1 Traded Endpoint} *)

let get_traded t ~user () =
  B.new_get t "/traded"
  |> B.query_param "user" (P.Address.to_string user)
  |> B.fetch_json ~expected_fields:yojson_fields_of_traded ~context:"traded"
       traded_of_yojson

(** {1 Open Interest Endpoint} *)

let get_open_interest t ?market () =
  B.new_get t "/oi"
  |> B.query_list "market" P.Hash64.to_string market
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_open_interest
       ~context:"open_interest" open_interest_of_yojson

(** {1 Live Volume Endpoint} *)

let get_live_volume t ~id () =
  B.new_get t "/live-volume"
  |> B.query_param "id" (string_of_int id)
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_live_volume
       ~context:"live_volume" live_volume_of_yojson

(** {1 Builder Leaderboard Endpoint} *)

let get_builder_leaderboard t ?time_period ?limit ?offset () =
  B.new_get t "/v1/builders/leaderboard"
  |> B.query_option "timePeriod" Time_period.to_string time_period
  |> B.query_option "limit" string_of_int limit
  |> B.query_option "offset" string_of_int offset
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_leaderboard_entry
       ~context:"leaderboard_entry" leaderboard_entry_of_yojson

(** {1 Builder Volume Endpoint} *)

let get_builder_volume t ?time_period () =
  B.new_get t "/v1/builders/volume"
  |> B.query_option "timePeriod" Time_period.to_string time_period
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_builder_volume_entry
       ~context:"builder_volume_entry" builder_volume_entry_of_yojson
