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

let add_param params key value =
  match value with
  | Some v -> (key, [v]) :: params
  | None -> params

let add_param_list params key values to_string =
  match values with
  | Some vs when vs <> [] ->
    let joined = String.concat "," (List.map to_string vs) in
    (key, [joined]) :: params
  | _ -> params

let add_param_bool params key value =
  match value with
  | Some true -> (key, ["true"]) :: params
  | Some false -> (key, ["false"]) :: params
  | None -> params

let add_param_int params key value =
  match value with
  | Some v -> (key, [string_of_int v]) :: params
  | None -> params

let add_param_float params key value =
  match value with
  | Some v -> (key, [string_of_float v]) :: params
  | None -> params

let build_uri base_url path params =
  let uri = Uri.of_string (base_url ^ path) in
  Uri.add_query_params uri params

let parse_json_response body parse_fn =
  try
    let json = Yojson.Safe.from_string body in
    Ok (parse_fn json)
  with
  | Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, _json) ->
    Error { error = "JSON parse error: " ^ Printexc.to_string exn }
  | Yojson.Json_error msg ->
    Error { error = "JSON error: " ^ msg }

let parse_json_list_response body parse_item_fn =
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
    (* Try to parse as error response *)
    (try
      let json = Yojson.Safe.from_string body in
      Error (error_response_of_yojson json)
    with _ ->
      Error { error = Printf.sprintf "HTTP %d: %s" (Cohttp.Code.code_of_status status) body })

(** {1 Health Endpoint} *)

let health_check t =
  let uri = build_uri t.base_url "/" [] in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_response b health_response_of_yojson)

(** {1 Positions Endpoint} *)

let get_positions t
    ~user
    ?market
    ?event_id
    ?size_threshold
    ?redeemable
    ?mergeable
    ?limit
    ?offset
    ?sort_by
    ?sort_direction
    ?title
    () =
  let params = [("user", [user])] in
  let params = add_param_list params "market" market Fun.id in
  let params = add_param_list params "eventId" event_id string_of_int in
  let params = add_param_float params "sizeThreshold" size_threshold in
  let params = add_param_bool params "redeemable" redeemable in
  let params = add_param_bool params "mergeable" mergeable in
  let params = add_param_int params "limit" limit in
  let params = add_param_int params "offset" offset in
  let params = add_param params "sortBy" (Option.map string_of_position_sort_by sort_by) in
  let params = add_param params "sortDirection" (Option.map string_of_sort_direction sort_direction) in
  let params = add_param params "title" title in
  let uri = build_uri t.base_url "/positions" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b position_of_yojson)

(** {1 Trades Endpoint} *)

let get_trades t
    ?user
    ?market
    ?event_id
    ?side
    ?filter_type
    ?filter_amount
    ?taker_only
    ?limit
    ?offset
    () =
  let params = [] in
  let params = add_param params "user" user in
  let params = add_param_list params "market" market Fun.id in
  let params = add_param_list params "eventId" event_id string_of_int in
  let params = add_param params "side" (Option.map (function BUY -> "BUY" | SELL -> "SELL") side) in
  let params = add_param params "filterType" (Option.map string_of_filter_type filter_type) in
  let params = add_param_float params "filterAmount" filter_amount in
  let params = add_param_bool params "takerOnly" taker_only in
  let params = add_param_int params "limit" limit in
  let params = add_param_int params "offset" offset in
  let uri = build_uri t.base_url "/trades" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b trade_of_yojson)

(** {1 Activity Endpoint} *)

let get_activity t
    ~user
    ?market
    ?event_id
    ?activity_types
    ?side
    ?start_time
    ?end_time
    ?sort_by
    ?sort_direction
    ?limit
    ?offset
    () =
  let params = [("user", [user])] in
  let params = add_param_list params "market" market Fun.id in
  let params = add_param_list params "eventId" event_id string_of_int in
  let params = add_param_list params "type" activity_types (function
    | TRADE -> "TRADE"
    | SPLIT -> "SPLIT"
    | MERGE -> "MERGE"
    | REDEEM -> "REDEEM"
    | REWARD -> "REWARD"
    | CONVERSION -> "CONVERSION"
  ) in
  let params = add_param params "side" (Option.map (function BUY -> "BUY" | SELL -> "SELL") side) in
  let params = add_param_int params "start" start_time in
  let params = add_param_int params "end" end_time in
  let params = add_param params "sortBy" (Option.map string_of_activity_sort_by sort_by) in
  let params = add_param params "sortDirection" (Option.map string_of_sort_direction sort_direction) in
  let params = add_param_int params "limit" limit in
  let params = add_param_int params "offset" offset in
  let uri = build_uri t.base_url "/activity" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b activity_of_yojson)

(** {1 Holders Endpoint} *)

let get_holders t
    ~market
    ?min_balance
    ?limit
    () =
  let params = [] in
  let params = add_param_list params "market" (Some market) Fun.id in
  let params = add_param_int params "minBalance" min_balance in
  let params = add_param_int params "limit" limit in
  let uri = build_uri t.base_url "/holders" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b meta_holder_of_yojson)

(** {1 Traded Endpoint} *)

let get_traded t ~user () =
  let params = [("user", [user])] in
  let uri = build_uri t.base_url "/traded" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_response b traded_of_yojson)

(** {1 Value Endpoint} *)

let get_value t
    ~user
    ?market
    () =
  let params = [("user", [user])] in
  let params = add_param_list params "market" market Fun.id in
  let uri = build_uri t.base_url "/value" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b value_of_yojson)

(** {1 Open Interest Endpoint} *)

let get_open_interest t ?market () =
  let params = [] in
  let params = add_param_list params "market" market Fun.id in
  let uri = build_uri t.base_url "/oi" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b open_interest_of_yojson)

(** {1 Live Volume Endpoint} *)

let get_live_volume t ~id () =
  let params = [("id", [string_of_int id])] in
  let uri = build_uri t.base_url "/live-volume" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b live_volume_of_yojson)

(** {1 Closed Positions Endpoint} *)

let get_closed_positions t
    ~user
    ?market
    ?event_id
    ?title
    ?sort_by
    ?sort_direction
    ?limit
    ?offset
    () =
  let params = [("user", [user])] in
  let params = add_param_list params "market" market Fun.id in
  let params = add_param_list params "eventId" event_id string_of_int in
  let params = add_param params "title" title in
  let params = add_param params "sortBy" (Option.map string_of_closed_position_sort_by sort_by) in
  let params = add_param params "sortDirection" (Option.map string_of_sort_direction sort_direction) in
  let params = add_param_int params "limit" limit in
  let params = add_param_int params "offset" offset in
  let uri = build_uri t.base_url "/closed-positions" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b closed_position_of_yojson)

(** {1 Builder Leaderboard Endpoint} *)

let get_builder_leaderboard t
    ?time_period
    ?limit
    ?offset
    () =
  let params = [] in
  let params = add_param params "timePeriod" (Option.map string_of_time_period time_period) in
  let params = add_param_int params "limit" limit in
  let params = add_param_int params "offset" offset in
  let uri = build_uri t.base_url "/v1/builders/leaderboard" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b leaderboard_entry_of_yojson)

(** {1 Builder Volume Endpoint} *)

let get_builder_volume t ?time_period () =
  let params = [] in
  let params = add_param params "timePeriod" (Option.map string_of_time_period time_period) in
  let uri = build_uri t.base_url "/v1/builders/volume" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b builder_volume_entry_of_yojson)

(** {1 Trader Leaderboard Endpoint} *)

let get_trader_leaderboard t
    ?category
    ?time_period
    ?order_by
    ?user
    ?user_name
    ?limit
    ?offset
    () =
  let params = [] in
  let params = add_param params "category" (Option.map string_of_leaderboard_category category) in
  let params = add_param params "timePeriod" (Option.map string_of_time_period time_period) in
  let params = add_param params "orderBy" (Option.map string_of_leaderboard_order_by order_by) in
  let params = add_param params "user" user in
  let params = add_param params "userName" user_name in
  let params = add_param_int params "limit" limit in
  let params = add_param_int params "offset" offset in
  let uri = build_uri t.base_url "/v1/leaderboard" params in
  let status, body = do_get t uri in
  handle_response status body (fun b -> parse_json_list_response b trader_leaderboard_entry_of_yojson)
