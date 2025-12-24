(** HTTP client for the Polymarket Gamma API.

    This module provides functions to interact with all public endpoints of the
    Polymarket Gamma API (https://gamma-api.polymarket.com). *)

open Types
open Params

(** {1 Client Configuration} *)

type t = Common.Http_client.t

let default_base_url = "https://gamma-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net () =
  Common.Http_client.create ~base_url ~sw ~net ()

(** {1 Health Endpoint} *)

let status t =
  let parse json =
    match Yojson.Safe.Util.to_string_option json with
    | Some s -> s
    | None -> Yojson.Safe.to_string json
  in
  [] |> Common.Http_client.get_json t "/status" parse

(** {1 Teams Endpoints} *)

let get_teams t ?id () =
  []
  |> Common.Http_client.add_int "id" id
  |> Common.Http_client.get_json_list t "/teams" team_of_yojson

let get_team t ~id () =
  []
  |> Common.Http_client.get_json t (Printf.sprintf "/teams/%d" id) team_of_yojson

(** {1 Tags Endpoints} *)

let get_tags t ?id ?label ?slug ?force_show ?limit ?offset () =
  []
  |> Common.Http_client.add "id" id
  |> Common.Http_client.add "label" label
  |> Common.Http_client.add "slug" slug
  |> Common.Http_client.add_bool "force_show" force_show
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t "/tags" tag_of_yojson

let get_tag t ~id () =
  []
  |> Common.Http_client.get_json t (Printf.sprintf "/tags/%s" id) tag_of_yojson

let get_tag_by_slug t ~slug () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/tags/slug/%s" slug)
       tag_of_yojson

let get_related_tags t ~id () =
  []
  |> Common.Http_client.get_json_list t
       (Printf.sprintf "/tags/%s/related-tags" id)
       related_tag_of_yojson

(** {1 Events Endpoints} *)

let get_events t ?id ?ticker ?slug ?archived ?active ?closed ?liquidity_min
    ?end_date_min ?end_date_max ?start_date_min ?start_date_max ?status ?order
    ?ascending ?tag ?tag_slug ?limit ?offset ?cursor ?next_cursor
    ?slug_size ?_c () =
  []
  |> Common.Http_client.add "id" id
  |> Common.Http_client.add "ticker" ticker
  |> Common.Http_client.add "slug" slug
  |> Common.Http_client.add_bool "archived" archived
  |> Common.Http_client.add_bool "active" active
  |> Common.Http_client.add_bool "closed" closed
  |> Common.Http_client.add_float "liquidity_min" liquidity_min
  |> Common.Http_client.add "end_date_min" end_date_min
  |> Common.Http_client.add "end_date_max" end_date_max
  |> Common.Http_client.add "start_date_min" start_date_min
  |> Common.Http_client.add "start_date_max" start_date_max
  |> Common.Http_client.add "status" (Option.map string_of_status status)
  |> Common.Http_client.add "order" order
  |> Common.Http_client.add_bool "ascending" ascending
  |> Common.Http_client.add "tag" tag
  |> Common.Http_client.add "tag_slug" tag_slug
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.add "cursor" cursor
  |> Common.Http_client.add "next_cursor" next_cursor
  |> Common.Http_client.add "slug_size"
       (Option.map string_of_slug_size slug_size)
  |> Common.Http_client.add "_c" _c
  |> Common.Http_client.get_json t "/events" events_pagination_of_yojson

let get_event t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/events/%d" id)
       event_of_yojson

let get_event_by_slug t ~slug () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/events/slug/%s" slug)
       event_of_yojson

let get_event_tags t ~id () =
  []
  |> Common.Http_client.get_json_list t
       (Printf.sprintf "/events/%d/tags" id)
       tag_of_yojson

let get_event_markets t ~id () =
  []
  |> Common.Http_client.get_json_list t
       (Printf.sprintf "/events/%d/markets" id)
       market_of_yojson

let get_event_comments_count t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/events/%d/comments-count" id)
       count_of_yojson

let get_event_tweet_count t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/events/%d/tweet-count" id)
       event_tweet_count_of_yojson

(** {1 Markets Endpoints} *)

let get_markets t ?id ?condition_id ?slug ?archived ?active ?closed ?clob_token_ids
    ?liquidity_num_min ?volume_num_min ?start_date_min ?start_date_max
    ?end_date_min ?end_date_max ?status ?order ?ascending ?tag_slug ?limit
    ?offset ?cursor ?next_cursor ?slug_size ?_c () =
  []
  |> Common.Http_client.add "id" id
  |> Common.Http_client.add "condition_id" condition_id
  |> Common.Http_client.add "slug" slug
  |> Common.Http_client.add_bool "archived" archived
  |> Common.Http_client.add_bool "active" active
  |> Common.Http_client.add_bool "closed" closed
  |> Common.Http_client.add "clob_token_ids" clob_token_ids
  |> Common.Http_client.add_float "liquidity_num_min" liquidity_num_min
  |> Common.Http_client.add_float "volume_num_min" volume_num_min
  |> Common.Http_client.add "start_date_min" start_date_min
  |> Common.Http_client.add "start_date_max" start_date_max
  |> Common.Http_client.add "end_date_min" end_date_min
  |> Common.Http_client.add "end_date_max" end_date_max
  |> Common.Http_client.add "status" (Option.map string_of_status status)
  |> Common.Http_client.add "order" order
  |> Common.Http_client.add_bool "ascending" ascending
  |> Common.Http_client.add "tag_slug" tag_slug
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.add "cursor" cursor
  |> Common.Http_client.add "next_cursor" next_cursor
  |> Common.Http_client.add "slug_size"
       (Option.map string_of_slug_size slug_size)
  |> Common.Http_client.add "_c" _c
  |> Common.Http_client.get_json_list t "/markets" market_of_yojson

let get_market t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/markets/%d" id)
       market_of_yojson

let get_market_by_slug t ~slug () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/markets/slug/%s" slug)
       market_of_yojson

let get_market_tags t ~id () =
  []
  |> Common.Http_client.get_json_list t
       (Printf.sprintf "/markets/%d/tags" id)
       tag_of_yojson

let get_market_events t ~id () =
  []
  |> Common.Http_client.get_json_list t
       (Printf.sprintf "/markets/%d/events" id)
       event_of_yojson

let get_market_description t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/markets/%d/description" id)
       market_description_of_yojson

(** {1 Series Endpoints} *)

let get_series_list t ?id ?ticker ?slug ?archived ?active ?closed ?status ?order
    ?ascending ?limit ?offset ?cursor ?next_cursor () =
  []
  |> Common.Http_client.add "id" id
  |> Common.Http_client.add "ticker" ticker
  |> Common.Http_client.add "slug" slug
  |> Common.Http_client.add_bool "archived" archived
  |> Common.Http_client.add_bool "active" active
  |> Common.Http_client.add_bool "closed" closed
  |> Common.Http_client.add "status" (Option.map string_of_status status)
  |> Common.Http_client.add "order" order
  |> Common.Http_client.add_bool "ascending" ascending
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.add "cursor" cursor
  |> Common.Http_client.add "next_cursor" next_cursor
  |> Common.Http_client.get_json_list t "/series" series_of_yojson

let get_series t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/series/%d" id)
       series_of_yojson

let get_series_summary t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/series-summary/%d" id)
       series_summary_of_yojson

(** {1 Comments Endpoints} *)

let get_comments t ?parent_entity_type ?parent_entity_id ?parent_comment_id
    ?user_address ?limit ?offset () =
  []
  |> Common.Http_client.add "parent_entity_type"
       (Option.map string_of_parent_entity_type parent_entity_type)
  |> Common.Http_client.add_int "parent_entity_id" parent_entity_id
  |> Common.Http_client.add "parent_comment_id" parent_comment_id
  |> Common.Http_client.add "user_address" user_address
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t "/comments" comment_of_yojson

let get_comment t ~id () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/comments/%d" id)
       comment_of_yojson

let get_user_comments t ~user_address ?limit ?offset () =
  []
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add_int "offset" offset
  |> Common.Http_client.get_json_list t
       (Printf.sprintf "/comments/user_address/%s" user_address)
       comment_of_yojson

(** {1 Profile Endpoints} *)

let get_public_profile t ~address () =
  [ ("address", [ address ]) ]
  |> Common.Http_client.get_json t "/public-profile" public_profile_response_of_yojson

let get_profile t ~user_address () =
  []
  |> Common.Http_client.get_json t
       (Printf.sprintf "/profiles/user_address/%s" user_address)
       profile_of_yojson

(** {1 Sports Endpoints} *)

let get_sports t () =
  []
  |> Common.Http_client.get_json_list t "/sports" sports_metadata_of_yojson

let get_sports_market_types t () =
  []
  |> Common.Http_client.get_json t "/sports/market-types"
       sports_market_types_response_of_yojson

(** {1 Search Endpoint} *)

let public_search t ~q ?limit ?tag_slug () =
  [ ("q", [ q ]) ]
  |> Common.Http_client.add_int "limit" limit
  |> Common.Http_client.add "tag_slug" tag_slug
  |> Common.Http_client.get_json t "/public-search" search_of_yojson
