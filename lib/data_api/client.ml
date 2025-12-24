(** HTTP client for the Polymarket Data API.

    This module provides functions to interact with all public endpoints
    of the Polymarket Data API (https://data-api.polymarket.com).
*)

open Types
open Params

(** {1 Client Configuration} *)

type t = Common.Http_client.t

let default_base_url = "https://data-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net () =
  Common.Http_client.create ~base_url ~sw ~net ()

(** {1 Health Endpoint} *)

let health_check t =
  [] |> Common.Http_client.get_json t "/" health_response_of_yojson

(** {1 Positions Endpoint} *)

let get_positions t ~user ?market ?event_id ?size_threshold ?redeemable
    ?mergeable ?limit ?offset ?sort_by ?sort_direction ?title () =
  [("user", [user])]
  |> Common.Http_client.add_list "market" Fun.id market
  |> Common.Http_client.add_list "eventId" string_of_int event_id
  |> Common.Http_client.add_float "sizeThreshold" size_threshold
  |> Common.Http_client.add_bool "redeemable" redeemable
  |> Common.Http_client.add_bool "mergeable" mergeable
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.add "sortBy" (Option.map string_of_position_sort_by sort_by)
  |> Common.Http_client.add "sortDirection" (Option.map string_of_sort_direction sort_direction)
  |> Common.Http_client.add "title" title
  |> Common.Http_client.get_json_list t "/positions" position_of_yojson

(** {1 Trades Endpoint} *)

let get_trades t ?user ?market ?event_id ?side ?filter_type ?filter_amount
    ?taker_only ?limit ?offset () =
  []
  |> Common.Http_client.add "user" user
  |> Common.Http_client.add_list "market" Fun.id market
  |> Common.Http_client.add_list "eventId" string_of_int event_id
  |> Common.Http_client.add "side" (Option.map string_of_side side)
  |> Common.Http_client.add "filterType" (Option.map string_of_filter_type filter_type)
  |> Common.Http_client.add_float "filterAmount" filter_amount
  |> Common.Http_client.add_bool "takerOnly" taker_only
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t "/trades" trade_of_yojson

(** {1 Activity Endpoint} *)

let get_activity t ~user ?market ?event_id ?activity_types ?side ?start_time
    ?end_time ?sort_by ?sort_direction ?limit ?offset () =
  [("user", [user])]
  |> Common.Http_client.add_list "market" Fun.id market
  |> Common.Http_client.add_list "eventId" string_of_int event_id
  |> Common.Http_client.add_list "type" string_of_activity_type activity_types
  |> Common.Http_client.add "side" (Option.map string_of_side side)
  |> Common.Http_client.add_int "start" start_time
  |> Common.Http_client.add_int "end" end_time
  |> Common.Http_client.add "sortBy" (Option.map string_of_activity_sort_by sort_by)
  |> Common.Http_client.add "sortDirection" (Option.map string_of_sort_direction sort_direction)
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t "/activity" activity_of_yojson

(** {1 Holders Endpoint} *)

let get_holders t ~market ?min_balance ?limit () =
  []
  |> Common.Http_client.add_list "market" Fun.id (Some market)
  |> Common.Http_client.add_int "minBalance" min_balance
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.get_json_list t "/holders" meta_holder_of_yojson

(** {1 Traded Endpoint} *)

let get_traded t ~user () =
  [("user", [user])]
  |> Common.Http_client.get_json t "/traded" traded_of_yojson

(** {1 Value Endpoint} *)

let get_value t ~user ?market () =
  [("user", [user])]
  |> Common.Http_client.add_list "market" Fun.id market
  |> Common.Http_client.get_json_list t "/value" value_of_yojson

(** {1 Open Interest Endpoint} *)

let get_open_interest t ?market () =
  []
  |> Common.Http_client.add_list "market" Fun.id market
  |> Common.Http_client.get_json_list t "/oi" open_interest_of_yojson

(** {1 Live Volume Endpoint} *)

let get_live_volume t ~id () =
  [("id", [string_of_int id])]
  |> Common.Http_client.get_json_list t "/live-volume" live_volume_of_yojson

(** {1 Closed Positions Endpoint} *)

let get_closed_positions t ~user ?market ?event_id ?title ?sort_by
    ?sort_direction ?limit ?offset () =
  [("user", [user])]
  |> Common.Http_client.add_list "market" Fun.id market
  |> Common.Http_client.add_list "eventId" string_of_int event_id
  |> Common.Http_client.add "title" title
  |> Common.Http_client.add "sortBy" (Option.map string_of_closed_position_sort_by sort_by)
  |> Common.Http_client.add "sortDirection" (Option.map string_of_sort_direction sort_direction)
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t "/closed-positions" closed_position_of_yojson

(** {1 Builder Leaderboard Endpoint} *)

let get_builder_leaderboard t ?time_period ?limit ?offset () =
  []
  |> Common.Http_client.add "timePeriod" (Option.map string_of_time_period time_period)
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t "/v1/builders/leaderboard" leaderboard_entry_of_yojson

(** {1 Builder Volume Endpoint} *)

let get_builder_volume t ?time_period () =
  []
  |> Common.Http_client.add "timePeriod" (Option.map string_of_time_period time_period)
  |> Common.Http_client.get_json_list t "/v1/builders/volume" builder_volume_entry_of_yojson

(** {1 Trader Leaderboard Endpoint} *)

let get_trader_leaderboard t ?category ?time_period ?order_by ?user ?user_name
    ?limit ?offset () =
  []
  |> Common.Http_client.add "category" (Option.map string_of_leaderboard_category category)
  |> Common.Http_client.add "timePeriod" (Option.map string_of_time_period time_period)
  |> Common.Http_client.add "orderBy" (Option.map string_of_leaderboard_order_by order_by)
  |> Common.Http_client.add "user" user
  |> Common.Http_client.add "userName" user_name
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t "/v1/leaderboard" trader_leaderboard_entry_of_yojson
