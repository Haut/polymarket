(** HTTP client for the Polymarket Data API.

    This module provides functions to interact with all public endpoints
    of the Polymarket Data API (https://data-api.polymarket.com).
*)

open Data_api_types
open Data_api_params

(** {1 Client Configuration} *)

type t = {
  base_url : string;
  client : Cohttp_eio.Client.t;
  sw : Eio.Switch.t;
}

let default_base_url = "https://data-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net () =
  let client = Cohttp_eio.Client.make ~https:None net in
  { base_url; client; sw }

(** {1 Internal Helpers} *)

(* Pipe-friendly param builders: params comes last for |> chaining *)

let add key value params =
  match value with
  | Some v -> (key, [v]) :: params
  | None -> params

let add_list key to_string values params =
  match values with
  | Some vs when vs <> [] ->
    let joined = String.concat "," (List.map to_string vs) in
    (key, [joined]) :: params
  | _ -> params

let add_bool key value params =
  match value with
  | Some true -> (key, ["true"]) :: params
  | Some false -> (key, ["false"]) :: params
  | None -> params

let add_int key value params =
  match value with
  | Some v -> (key, [string_of_int v]) :: params
  | None -> params

let add_float key value params =
  match value with
  | Some v -> (key, [string_of_float v]) :: params
  | None -> params

let build_uri base_url path params =
  let uri = Uri.of_string (base_url ^ path) in
  Uri.add_query_params uri params

let parse_json parse_fn body =
  try
    let json = Yojson.Safe.from_string body in
    Ok (parse_fn json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _json) ->
    Error { error = "JSON parse error: " ^ Printexc.to_string exn }
  | Yojson.Json_error msg ->
    Error { error = "JSON error: " ^ msg }

let parse_json_list parse_item_fn body =
  try
    let json = Yojson.Safe.from_string body in
    match json with
    | `List items -> Ok (List.map parse_item_fn items)
    | _ -> Error { error = "Expected JSON array" }
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _json) ->
    Error { error = "JSON parse error: " ^ Printexc.to_string exn }
  | Yojson.Json_error msg ->
    Error { error = "JSON error: " ^ msg }

let do_get t uri =
  try
    let resp, body = Cohttp_eio.Client.get ~sw:t.sw t.client uri in
    let status = Cohttp.Response.status resp in
    let body_str = Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int in
    (status, body_str)
  with exn ->
    (`Internal_server_error, Printf.sprintf {|{"error": "Request failed: %s"}|} (Printexc.to_string exn))

let handle_response status body parse_fn =
  match Cohttp.Code.code_of_status status with
  | 200 -> parse_fn body
  | _ ->
    (try
      let json = Yojson.Safe.from_string body in
      Error (error_response_of_yojson json)
    with _ ->
      Error { error = Printf.sprintf "HTTP %d: %s" (Cohttp.Code.code_of_status status) body })

(* Unified request function: params |> request t path parser *)
let request t path parse_fn params =
  let uri = build_uri t.base_url path params in
  let status, body = do_get t uri in
  handle_response status body parse_fn

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
