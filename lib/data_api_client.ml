(** HTTP client for the Polymarket Data API.

    This module provides functions to interact with all public endpoints
    of the Polymarket Data API (https://data-api.polymarket.com).
*)

open Data_api_types
open Data_api_params

(** {1 Client Configuration} *)

type t = Http_client.t

let default_base_url = "https://data-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net () =
  Http_client.create ~base_url ~sw ~net ()

(** {1 Internal Helpers} *)

(* Re-export param builders for convenience *)
let add = Http_client.add
let add_list = Http_client.add_list
let add_bool = Http_client.add_bool
let add_int = Http_client.add_int
let add_float = Http_client.add_float

(* Data API specific JSON parsers that return error_response on failure *)
let parse_json parse_fn body =
  match Http_client.parse_json parse_fn body with
  | Ok v -> Ok v
  | Error msg -> Error { error = msg }

let parse_json_list parse_item_fn body =
  match Http_client.parse_json_list parse_item_fn body with
  | Ok v -> Ok v
  | Error msg -> Error { error = msg }

(* Error parser for Data API responses *)
let parse_error body =
  try
    let json = Yojson.Safe.from_string body in
    error_response_of_yojson json
  with _ ->
    { error = body }

(* Unified request function: params |> request t path parser *)
let request t path parse_fn params =
  Http_client.request t path parse_fn parse_error params

(** {1 Health Endpoint} *)

let health_check t =
  [] |> request t "/" (parse_json health_response_of_yojson)

(** {1 Positions Endpoint} *)

let get_positions t ~user ?market ?event_id ?size_threshold ?redeemable
    ?mergeable ?limit ?offset ?sort_by ?sort_direction ?title () =
  [("user", [user])]
  |> add_list "market" Fun.id market
  |> add_list "eventId" string_of_int event_id
  |> add_float "sizeThreshold" size_threshold
  |> add_bool "redeemable" redeemable
  |> add_bool "mergeable" mergeable
  |> add_int "limit" limit
  |> add_int "offset" offset
  |> add "sortBy" (Option.map string_of_position_sort_by sort_by)
  |> add "sortDirection" (Option.map string_of_sort_direction sort_direction)
  |> add "title" title
  |> request t "/positions" (parse_json_list position_of_yojson)

(** {1 Trades Endpoint} *)

let get_trades t ?user ?market ?event_id ?side ?filter_type ?filter_amount
    ?taker_only ?limit ?offset () =
  []
  |> add "user" user
  |> add_list "market" Fun.id market
  |> add_list "eventId" string_of_int event_id
  |> add "side" (Option.map string_of_side side)
  |> add "filterType" (Option.map string_of_filter_type filter_type)
  |> add_float "filterAmount" filter_amount
  |> add_bool "takerOnly" taker_only
  |> add_int "limit" limit
  |> add_int "offset" offset
  |> request t "/trades" (parse_json_list trade_of_yojson)

(** {1 Activity Endpoint} *)

let get_activity t ~user ?market ?event_id ?activity_types ?side ?start_time
    ?end_time ?sort_by ?sort_direction ?limit ?offset () =
  [("user", [user])]
  |> add_list "market" Fun.id market
  |> add_list "eventId" string_of_int event_id
  |> add_list "type" string_of_activity_type activity_types
  |> add "side" (Option.map string_of_side side)
  |> add_int "start" start_time
  |> add_int "end" end_time
  |> add "sortBy" (Option.map string_of_activity_sort_by sort_by)
  |> add "sortDirection" (Option.map string_of_sort_direction sort_direction)
  |> add_int "limit" limit
  |> add_int "offset" offset
  |> request t "/activity" (parse_json_list activity_of_yojson)

(** {1 Holders Endpoint} *)

let get_holders t ~market ?min_balance ?limit () =
  []
  |> add_list "market" Fun.id (Some market)
  |> add_int "minBalance" min_balance
  |> add_int "limit" limit
  |> request t "/holders" (parse_json_list meta_holder_of_yojson)

(** {1 Traded Endpoint} *)

let get_traded t ~user () =
  [("user", [user])]
  |> request t "/traded" (parse_json traded_of_yojson)

(** {1 Value Endpoint} *)

let get_value t ~user ?market () =
  [("user", [user])]
  |> add_list "market" Fun.id market
  |> request t "/value" (parse_json_list value_of_yojson)

(** {1 Open Interest Endpoint} *)

let get_open_interest t ?market () =
  []
  |> add_list "market" Fun.id market
  |> request t "/oi" (parse_json_list open_interest_of_yojson)

(** {1 Live Volume Endpoint} *)

let get_live_volume t ~id () =
  [("id", [string_of_int id])]
  |> request t "/live-volume" (parse_json_list live_volume_of_yojson)

(** {1 Closed Positions Endpoint} *)

let get_closed_positions t ~user ?market ?event_id ?title ?sort_by
    ?sort_direction ?limit ?offset () =
  [("user", [user])]
  |> add_list "market" Fun.id market
  |> add_list "eventId" string_of_int event_id
  |> add "title" title
  |> add "sortBy" (Option.map string_of_closed_position_sort_by sort_by)
  |> add "sortDirection" (Option.map string_of_sort_direction sort_direction)
  |> add_int "limit" limit
  |> add_int "offset" offset
  |> request t "/closed-positions" (parse_json_list closed_position_of_yojson)

(** {1 Builder Leaderboard Endpoint} *)

let get_builder_leaderboard t ?time_period ?limit ?offset () =
  []
  |> add "timePeriod" (Option.map string_of_time_period time_period)
  |> add_int "limit" limit
  |> add_int "offset" offset
  |> request t "/v1/builders/leaderboard" (parse_json_list leaderboard_entry_of_yojson)

(** {1 Builder Volume Endpoint} *)

let get_builder_volume t ?time_period () =
  []
  |> add "timePeriod" (Option.map string_of_time_period time_period)
  |> request t "/v1/builders/volume" (parse_json_list builder_volume_entry_of_yojson)

(** {1 Trader Leaderboard Endpoint} *)

let get_trader_leaderboard t ?category ?time_period ?order_by ?user ?user_name
    ?limit ?offset () =
  []
  |> add "category" (Option.map string_of_leaderboard_category category)
  |> add "timePeriod" (Option.map string_of_time_period time_period)
  |> add "orderBy" (Option.map string_of_leaderboard_order_by order_by)
  |> add "user" user
  |> add "userName" user_name
  |> add_int "limit" limit
  |> add_int "offset" offset
  |> request t "/v1/leaderboard" (parse_json_list trader_leaderboard_entry_of_yojson)
