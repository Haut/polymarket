(** HTTP client for the Polymarket Gamma API.

    This module provides functions to interact with all public endpoints of the
    Polymarket Gamma API (https://gamma-api.polymarket.com). *)

open Query
open Responses

(** {1 Client Configuration} *)

type t = Http_client.Client.t

let default_base_url = "https://gamma-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net () =
  Http_client.Client.create ~base_url ~sw ~net ()

(** {1 Health Endpoint} *)

let status t = [] |> Http_client.Client.get_text t "/status"

(** {1 Teams Endpoints} *)

let get_teams t ?id () =
  []
  |> Http_client.Client.add_int "id" id
  |> Http_client.Client.get_json_list t "/teams" team_of_yojson

let get_team t ~id () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/teams/%d" id)
       team_of_yojson

(** {1 Tags Endpoints} *)

let get_tags t ?id ?label ?slug ?force_show ?limit ?offset () =
  []
  |> Http_client.Client.add "id" id
  |> Http_client.Client.add "label" label
  |> Http_client.Client.add "slug" slug
  |> Http_client.Client.add_bool "force_show" force_show
  |> Http_client.Client.add_int "limit" limit
  |> Http_client.Client.add_int "offset" offset
  |> Http_client.Client.get_json_list t "/tags" tag_of_yojson

let get_tag t ~id () =
  []
  |> Http_client.Client.get_json t (Printf.sprintf "/tags/%s" id) tag_of_yojson

let get_tag_by_slug t ~slug () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/tags/slug/%s" slug)
       tag_of_yojson

let get_related_tags t ~id () =
  []
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/tags/%s/related-tags" id)
       related_tag_of_yojson

(** {1 Events Endpoints} *)

let get_events t ?id ?ticker ?slug ?archived ?active ?closed ?liquidity_min
    ?end_date_min ?end_date_max ?start_date_min ?start_date_max ?status ?order
    ?ascending ?tag ?tag_slug ?limit ?offset ?cursor ?next_cursor ?slug_size ?_c
    () =
  []
  |> Http_client.Client.add "id" id
  |> Http_client.Client.add "ticker" ticker
  |> Http_client.Client.add "slug" slug
  |> Http_client.Client.add_bool "archived" archived
  |> Http_client.Client.add_bool "active" active
  |> Http_client.Client.add_bool "closed" closed
  |> Http_client.Client.add_float "liquidity_min" liquidity_min
  |> Http_client.Client.add "end_date_min" end_date_min
  |> Http_client.Client.add "end_date_max" end_date_max
  |> Http_client.Client.add "start_date_min" start_date_min
  |> Http_client.Client.add "start_date_max" start_date_max
  |> Http_client.Client.add "status" (Option.map string_of_status status)
  |> Http_client.Client.add "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add "tag" tag
  |> Http_client.Client.add "tag_slug" tag_slug
  |> Http_client.Client.add_int "limit" limit
  |> Http_client.Client.add_int "offset" offset
  |> Http_client.Client.add "cursor" cursor
  |> Http_client.Client.add "next_cursor" next_cursor
  |> Http_client.Client.add "slug_size"
       (Option.map string_of_slug_size slug_size)
  |> Http_client.Client.add "_c" _c
  |> Http_client.Client.get_json t "/events" (fun json ->
      match json with
      | `List events -> List.map event_of_yojson events
      | _ -> failwith "Expected list of events")

let get_event t ~id () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/events/%d" id)
       event_of_yojson

let get_event_by_slug t ~slug () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/events/slug/%s" slug)
       event_of_yojson

let get_event_tags t ~id () =
  []
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/events/%d/tags" id)
       tag_of_yojson

(** {1 Markets Endpoints} *)

let get_markets t ?id ?condition_id ?slug ?archived ?active ?closed
    ?clob_token_ids ?liquidity_num_min ?volume_num_min ?start_date_min
    ?start_date_max ?end_date_min ?end_date_max ?status ?order ?ascending
    ?tag_slug ?limit ?offset ?cursor ?next_cursor ?slug_size ?_c () =
  []
  |> Http_client.Client.add "id" id
  |> Http_client.Client.add "condition_id" condition_id
  |> Http_client.Client.add "slug" slug
  |> Http_client.Client.add_bool "archived" archived
  |> Http_client.Client.add_bool "active" active
  |> Http_client.Client.add_bool "closed" closed
  |> Http_client.Client.add "clob_token_ids" clob_token_ids
  |> Http_client.Client.add_float "liquidity_num_min" liquidity_num_min
  |> Http_client.Client.add_float "volume_num_min" volume_num_min
  |> Http_client.Client.add "start_date_min" start_date_min
  |> Http_client.Client.add "start_date_max" start_date_max
  |> Http_client.Client.add "end_date_min" end_date_min
  |> Http_client.Client.add "end_date_max" end_date_max
  |> Http_client.Client.add "status" (Option.map string_of_status status)
  |> Http_client.Client.add "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add "tag_slug" tag_slug
  |> Http_client.Client.add_int "limit" limit
  |> Http_client.Client.add_int "offset" offset
  |> Http_client.Client.add "cursor" cursor
  |> Http_client.Client.add "next_cursor" next_cursor
  |> Http_client.Client.add "slug_size"
       (Option.map string_of_slug_size slug_size)
  |> Http_client.Client.add "_c" _c
  |> Http_client.Client.get_json_list t "/markets" market_of_yojson

let get_market t ~id () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/markets/%d" id)
       market_of_yojson

let get_market_by_slug t ~slug () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/markets/slug/%s" slug)
       market_of_yojson

let get_market_tags t ~id () =
  []
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/markets/%d/tags" id)
       tag_of_yojson

let get_market_description t ~id () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/markets/%d/description" id)
       market_description_of_yojson

(** {1 Series Endpoints} *)

let get_series_list t ?id ?ticker ?slug ?archived ?active ?closed ?status ?order
    ?ascending ?limit ?offset ?cursor ?next_cursor () =
  []
  |> Http_client.Client.add "id" id
  |> Http_client.Client.add "ticker" ticker
  |> Http_client.Client.add "slug" slug
  |> Http_client.Client.add_bool "archived" archived
  |> Http_client.Client.add_bool "active" active
  |> Http_client.Client.add_bool "closed" closed
  |> Http_client.Client.add "status" (Option.map string_of_status status)
  |> Http_client.Client.add "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add_int "limit" limit
  |> Http_client.Client.add_int "offset" offset
  |> Http_client.Client.add "cursor" cursor
  |> Http_client.Client.add "next_cursor" next_cursor
  |> Http_client.Client.get_json_list t "/series" series_of_yojson

let get_series t ~id () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/series/%s" id)
       series_of_yojson

let get_series_summary t ~id () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/series-summary/%s" id)
       series_summary_of_yojson

(** {1 Comments Endpoints} *)

let get_comments t ?parent_entity_type ?parent_entity_id ?parent_comment_id
    ?user_address ?limit ?offset () =
  []
  |> Http_client.Client.add "parent_entity_type"
       (Option.map string_of_parent_entity_type parent_entity_type)
  |> Http_client.Client.add_int "parent_entity_id" parent_entity_id
  |> Http_client.Client.add "parent_comment_id" parent_comment_id
  |> Http_client.Client.add "user_address" user_address
  |> Http_client.Client.add_int "limit" limit
  |> Http_client.Client.add_int "offset" offset
  |> Http_client.Client.get_json_list t "/comments" comment_of_yojson

let get_comment t ~id () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/comments/%d" id)
       comment_of_yojson

let get_user_comments t ~user_address ?limit ?offset () =
  []
  |> Http_client.Client.add_int "limit" limit
  |> Http_client.Client.add_int "offset" offset
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/comments/user_address/%s" user_address)
       comment_of_yojson

(** {1 Profile Endpoints} *)

let get_public_profile t ~address () =
  [ ("address", [ address ]) ]
  |> Http_client.Client.get_json t "/public-profile"
       public_profile_response_of_yojson

let get_profile t ~user_address () =
  []
  |> Http_client.Client.get_json t
       (Printf.sprintf "/profiles/user_address/%s" user_address)
       profile_of_yojson

(** {1 Sports Endpoints} *)

let get_sports t () =
  [] |> Http_client.Client.get_json_list t "/sports" sports_metadata_of_yojson

let get_sports_market_types t () =
  []
  |> Http_client.Client.get_json t "/sports/market-types"
       sports_market_types_response_of_yojson

(** {1 Search Endpoint} *)

let public_search t ~q ?cache ?events_status ?limit_per_type ?page ?events_tag
    ?keep_closed_markets ?sort ?ascending ?search_tags ?search_profiles
    ?recurrence ?exclude_tag_id ?optimized () =
  [ ("q", [ q ]) ]
  |> Http_client.Client.add_bool "cache" cache
  |> Http_client.Client.add "events_status" events_status
  |> Http_client.Client.add_int "limit_per_type" limit_per_type
  |> Http_client.Client.add_int "page" page
  |> (fun params ->
  match events_tag with
  | Some tags ->
      List.fold_left (fun acc tag -> ("events_tag", [ tag ]) :: acc) params tags
  | None -> params)
  |> Http_client.Client.add_int "keep_closed_markets" keep_closed_markets
  |> Http_client.Client.add "sort" sort
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add_bool "search_tags" search_tags
  |> Http_client.Client.add_bool "search_profiles" search_profiles
  |> Http_client.Client.add "recurrence" recurrence
  |> (fun params ->
  match exclude_tag_id with
  | Some ids ->
      List.fold_left
        (fun acc id -> ("exclude_tag_id", [ string_of_int id ]) :: acc)
        params ids
  | None -> params)
  |> Http_client.Client.add_bool "optimized" optimized
  |> Http_client.Client.get_json t "/public-search" search_of_yojson
