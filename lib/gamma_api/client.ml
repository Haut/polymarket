(** HTTP client for the Polymarket Gamma API.

    This module provides functions to interact with all public endpoints of the
    Polymarket Gamma API (https://gamma-api.polymarket.com). *)

open Types
module P = Polymarket_common.Primitives
module H = Polymarket_http.Client

(** {1 Client Configuration} *)

type t = Polymarket_http.Client.t

let default_base_url = "https://gamma-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
  H.create ~base_url ~sw ~net ~rate_limiter ()

(** {1 Health Endpoint} *)

let status t = [] |> H.get_text t "/status"

(** {1 Teams Endpoints} *)

let get_teams t ?limit ?offset ?order ?ascending ?league ?name ?abbreviation ()
    =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add_each "order" Fun.id order
  |> H.add_bool "ascending" ascending
  |> H.add_each "league" Fun.id league
  |> H.add_each "name" Fun.id name
  |> H.add_each "abbreviation" Fun.id abbreviation
  |> H.get_json_list t "/teams" team_of_yojson

let get_sports t () =
  [] |> H.get_json_list t "/sports" sports_metadata_of_yojson

let get_sports_market_types t () =
  []
  |> H.get_json t "/sports/market-types" sports_market_types_response_of_yojson

(** {1 Tags Endpoints} *)

let get_tags t ?limit ?offset ?order ?ascending ?include_template ?is_carousel
    () =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add_each "order" Fun.id order
  |> H.add_bool "ascending" ascending
  |> H.add_bool "include_template" include_template
  |> H.add_bool "is_carousel" is_carousel
  |> H.get_json_list t "/tags" tag_of_yojson

let get_tag t ~id ?include_template () =
  []
  |> H.add_bool "include_template" include_template
  |> H.get_json t (Printf.sprintf "/tags/%s" id) tag_of_yojson

let get_tag_by_slug t ~slug ?include_template () =
  []
  |> H.add_bool "include_template" include_template
  |> H.get_json t (Printf.sprintf "/tags/slug/%s" slug) tag_of_yojson

let get_related_tags t ~id ?omit_empty ?status () =
  []
  |> H.add_bool "omit_empty" omit_empty
  |> H.add_option "status" Status.to_string status
  |> H.get_json_list t
       (Printf.sprintf "/tags/%s/related-tags" id)
       related_tag_of_yojson

let get_related_tags_by_slug t ~slug ?omit_empty ?status () =
  []
  |> H.add_bool "omit_empty" omit_empty
  |> H.add_option "status" Status.to_string status
  |> H.get_json_list t
       (Printf.sprintf "/tags/slug/%s/related-tags" slug)
       related_tag_of_yojson

let get_related_tag_tags t ~id ?omit_empty ?status () =
  []
  |> H.add_bool "omit_empty" omit_empty
  |> H.add_option "status" Status.to_string status
  |> H.get_json_list t
       (Printf.sprintf "/tags/%s/related-tags/tags" id)
       tag_of_yojson

let get_related_tag_tags_by_slug t ~slug ?omit_empty ?status () =
  []
  |> H.add_bool "omit_empty" omit_empty
  |> H.add_option "status" Status.to_string status
  |> H.get_json_list t
       (Printf.sprintf "/tags/slug/%s/related-tags/tags" slug)
       tag_of_yojson

(** {1 Events Endpoints} *)

let get_events t ?limit ?offset ?order ?ascending ?id ?tag_id ?exclude_tag_id
    ?slug ?tag_slug ?related_tags ?active ?archived ?featured ?cyom
    ?include_chat ?include_template ?recurrence ?closed ?liquidity_min
    ?liquidity_max ?volume_min ?volume_max ?start_date_min ?start_date_max
    ?end_date_min ?end_date_max () =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add_each "order" Fun.id order
  |> H.add_bool "ascending" ascending
  |> H.add_each "id" string_of_int id
  |> H.add_option "tag_id" string_of_int tag_id
  |> H.add_each "exclude_tag_id" string_of_int exclude_tag_id
  |> H.add_each "slug" Fun.id slug
  |> H.add "tag_slug" tag_slug
  |> H.add_bool "related_tags" related_tags
  |> H.add_bool "active" active
  |> H.add_bool "archived" archived
  |> H.add_bool "featured" featured
  |> H.add_bool "cyom" cyom
  |> H.add_bool "include_chat" include_chat
  |> H.add_bool "include_template" include_template
  |> H.add "recurrence" recurrence
  |> H.add_bool "closed" closed
  |> H.add_option "liquidity_min" string_of_float liquidity_min
  |> H.add_option "liquidity_max" string_of_float liquidity_max
  |> H.add_option "volume_min" string_of_float volume_min
  |> H.add_option "volume_max" string_of_float volume_max
  |> H.add_option "start_date_min" P.Timestamp.to_string start_date_min
  |> H.add_option "start_date_max" P.Timestamp.to_string start_date_max
  |> H.add_option "end_date_min" P.Timestamp.to_string end_date_min
  |> H.add_option "end_date_max" P.Timestamp.to_string end_date_max
  |> H.get_json_list t "/events" event_of_yojson

let get_event t ~id ?include_chat ?include_template () =
  []
  |> H.add_bool "include_chat" include_chat
  |> H.add_bool "include_template" include_template
  |> H.get_json t (Printf.sprintf "/events/%s" id) event_of_yojson

let get_event_tags t ~id () =
  [] |> H.get_json_list t (Printf.sprintf "/events/%s/tags" id) tag_of_yojson

let get_event_by_slug t ~slug ?include_chat ?include_template () =
  []
  |> H.add_bool "include_chat" include_chat
  |> H.add_bool "include_template" include_template
  |> H.get_json t (Printf.sprintf "/events/slug/%s" slug) event_of_yojson

(** {1 Markets Endpoints} *)

let get_markets t ?limit ?offset ?order ?ascending ?id ?slug ?clob_token_ids
    ?condition_ids ?market_maker_address ?liquidity_num_min ?liquidity_num_max
    ?volume_num_min ?volume_num_max ?start_date_min ?start_date_max
    ?end_date_min ?end_date_max ?tag_id ?related_tags ?cyom
    ?uma_resolution_status ?game_id ?sports_market_types ?rewards_min_size
    ?question_ids ?include_tag ?closed () =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add "order" order
  |> H.add_bool "ascending" ascending
  |> H.add_each "id" string_of_int id
  |> H.add_each "slug" Fun.id slug
  |> H.add_each "clob_token_ids" Fun.id clob_token_ids
  |> H.add_each "condition_ids" Fun.id condition_ids
  |> H.add_each "market_maker_address" Fun.id market_maker_address
  |> H.add_option "liquidity_num_min" string_of_float liquidity_num_min
  |> H.add_option "liquidity_num_max" string_of_float liquidity_num_max
  |> H.add_option "volume_num_min" string_of_float volume_num_min
  |> H.add_option "volume_num_max" string_of_float volume_num_max
  |> H.add_option "start_date_min" P.Timestamp.to_string start_date_min
  |> H.add_option "start_date_max" P.Timestamp.to_string start_date_max
  |> H.add_option "end_date_min" P.Timestamp.to_string end_date_min
  |> H.add_option "end_date_max" P.Timestamp.to_string end_date_max
  |> H.add_option "tag_id" string_of_int tag_id
  |> H.add_bool "related_tags" related_tags
  |> H.add_bool "cyom" cyom
  |> H.add "uma_resolution_status" uma_resolution_status
  |> H.add "game_id" game_id
  |> H.add_each "sports_market_types" Fun.id sports_market_types
  |> H.add_option "rewards_min_size" string_of_float rewards_min_size
  |> H.add_each "question_ids" Fun.id question_ids
  |> H.add_bool "include_tag" include_tag
  |> H.add_bool "closed" closed
  |> H.get_json_list t "/markets" market_of_yojson

let get_market t ~id ?include_tag () =
  []
  |> H.add_bool "include_tag" include_tag
  |> H.get_json t (Printf.sprintf "/markets/%s" id) market_of_yojson

let get_market_tags t ~id () =
  [] |> H.get_json_list t (Printf.sprintf "/markets/%s/tags" id) tag_of_yojson

let get_market_by_slug t ~slug ?include_tag () =
  []
  |> H.add_bool "include_tag" include_tag
  |> H.get_json t (Printf.sprintf "/markets/slug/%s" slug) market_of_yojson

(** {1 Series Endpoints} *)

let get_series_list t ?limit ?offset ?order ?ascending ?slug ?categories_ids
    ?categories_labels ?closed ?include_chat ?recurrence () =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add "order" order
  |> H.add_bool "ascending" ascending
  |> H.add_each "slug" Fun.id slug
  |> H.add_each "categories_ids" string_of_int categories_ids
  |> H.add_each "categories_labels" Fun.id categories_labels
  |> H.add_bool "closed" closed
  |> H.add_bool "include_chat" include_chat
  |> H.add "recurrence" recurrence
  |> H.get_json_list t "/series" series_of_yojson

let get_series t ~id ?include_chat () =
  []
  |> H.add_bool "include_chat" include_chat
  |> H.get_json t (Printf.sprintf "/series/%s" id) series_of_yojson

(** {1 Comments Endpoints} *)

let get_comments t ?limit ?offset ?order ?ascending ?parent_entity_type
    ?parent_entity_id ?get_positions ?holders_only () =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add "order" order
  |> H.add_bool "ascending" ascending
  |> H.add_option "parent_entity_type" Parent_entity_type.to_string
       parent_entity_type
  |> H.add_option "parent_entity_id" string_of_int parent_entity_id
  |> H.add_bool "get_positions" get_positions
  |> H.add_bool "holders_only" holders_only
  |> H.get_json_list t "/comments" comment_of_yojson

let get_comment t ~id ?get_positions () =
  []
  |> H.add_bool "get_positions" get_positions
  |> H.get_json t (Printf.sprintf "/comments/%s" id) comment_of_yojson

let get_user_comments t ~user_address ?limit ?offset ?order ?ascending () =
  []
  |> H.add_option "limit" P.Nonneg_int.to_string limit
  |> H.add_option "offset" P.Nonneg_int.to_string offset
  |> H.add "order" order
  |> H.add_bool "ascending" ascending
  |> H.get_json_list t
       (Printf.sprintf "/comments/user_address/%s" user_address)
       comment_of_yojson

(** {1 Profile Endpoints} *)

let get_public_profile t ~address () =
  [ ("address", [ address ]) ]
  |> H.get_json t "/public-profile" public_profile_response_of_yojson

(** {1 Search Endpoint} *)

let public_search t ~q ?cache ?events_status ?limit_per_type ?page ?events_tag
    ?keep_closed_markets ?sort ?ascending ?search_tags ?search_profiles
    ?recurrence ?exclude_tag_id ?optimized () =
  [ ("q", [ q ]) ]
  |> H.add_bool "cache" cache
  |> H.add "events_status" events_status
  |> H.add_option "limit_per_type" string_of_int limit_per_type
  |> H.add_option "page" string_of_int page
  |> H.add_each "events_tag" Fun.id events_tag
  |> H.add_option "keep_closed_markets" string_of_int keep_closed_markets
  |> H.add "sort" sort
  |> H.add_bool "ascending" ascending
  |> H.add_bool "search_tags" search_tags
  |> H.add_bool "search_profiles" search_profiles
  |> H.add "recurrence" recurrence
  |> H.add_each "exclude_tag_id" string_of_int exclude_tag_id
  |> H.add_bool "optimized" optimized
  |> H.get_json t "/public-search" search_of_yojson
