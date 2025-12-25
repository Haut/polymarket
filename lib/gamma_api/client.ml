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

let get_teams t ?limit ?offset ?order ?ascending ?league ?name ?abbreviation ()
    =
  []
  |> Http_client.Client.add_nonneg_int "limit" limit
  |> Http_client.Client.add_nonneg_int "offset" offset
  |> Http_client.Client.add_string_array "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add_string_array "league" league
  |> Http_client.Client.add_string_array "name" name
  |> Http_client.Client.add_string_array "abbreviation" abbreviation
  |> Http_client.Client.get_json_list t "/teams" team_of_yojson

let get_sports t () =
  [] |> Http_client.Client.get_json_list t "/sports" sports_metadata_of_yojson

let get_sports_market_types t () =
  []
  |> Http_client.Client.get_json t "/sports/market-types"
       sports_market_types_response_of_yojson

(** {1 Tags Endpoints} *)

let get_tags t ?limit ?offset ?order ?ascending ?include_template ?is_carousel
    () =
  []
  |> Http_client.Client.add_nonneg_int "limit" limit
  |> Http_client.Client.add_nonneg_int "offset" offset
  |> Http_client.Client.add_string_array "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add_bool "include_template" include_template
  |> Http_client.Client.add_bool "is_carousel" is_carousel
  |> Http_client.Client.get_json_list t "/tags" tag_of_yojson

let get_tag t ~id ?include_template () =
  []
  |> Http_client.Client.add_bool "include_template" include_template
  |> Http_client.Client.get_json t (Printf.sprintf "/tags/%s" id) tag_of_yojson

let get_tag_by_slug t ~slug ?include_template () =
  []
  |> Http_client.Client.add_bool "include_template" include_template
  |> Http_client.Client.get_json t
       (Printf.sprintf "/tags/slug/%s" slug)
       tag_of_yojson

let get_related_tags t ~id ?omit_empty ?status () =
  []
  |> Http_client.Client.add_bool "omit_empty" omit_empty
  |> Http_client.Client.add "status" (Option.map string_of_status status)
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/tags/%s/related-tags" id)
       related_tag_of_yojson

let get_related_tags_by_slug t ~slug ?omit_empty ?status () =
  []
  |> Http_client.Client.add_bool "omit_empty" omit_empty
  |> Http_client.Client.add "status" (Option.map string_of_status status)
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/tags/slug/%s/related-tags" slug)
       related_tag_of_yojson

let get_related_tag_tags t ~id ?omit_empty ?status () =
  []
  |> Http_client.Client.add_bool "omit_empty" omit_empty
  |> Http_client.Client.add "status" (Option.map string_of_status status)
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/tags/%s/related-tags/tags" id)
       tag_of_yojson

let get_related_tag_tags_by_slug t ~slug ?omit_empty ?status () =
  []
  |> Http_client.Client.add_bool "omit_empty" omit_empty
  |> Http_client.Client.add "status" (Option.map string_of_status status)
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/tags/slug/%s/related-tags/tags" slug)
       tag_of_yojson

(** {1 Events Endpoints} *)

let get_events t ?limit ?offset ?order ?ascending ?id ?tag_id ?exclude_tag_id
    ?slug ?tag_slug ?related_tags ?active ?archived ?featured ?cyom
    ?include_chat ?include_template ?recurrence ?closed ?liquidity_min
    ?liquidity_max ?volume_min ?volume_max ?start_date_min ?start_date_max
    ?end_date_min ?end_date_max () =
  []
  |> Http_client.Client.add_nonneg_int "limit" limit
  |> Http_client.Client.add_nonneg_int "offset" offset
  |> Http_client.Client.add_string_array "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add_int_array "id" id
  |> Http_client.Client.add_int "tag_id" tag_id
  |> Http_client.Client.add_int_array "exclude_tag_id" exclude_tag_id
  |> Http_client.Client.add_string_array "slug" slug
  |> Http_client.Client.add "tag_slug" tag_slug
  |> Http_client.Client.add_bool "related_tags" related_tags
  |> Http_client.Client.add_bool "active" active
  |> Http_client.Client.add_bool "archived" archived
  |> Http_client.Client.add_bool "featured" featured
  |> Http_client.Client.add_bool "cyom" cyom
  |> Http_client.Client.add_bool "include_chat" include_chat
  |> Http_client.Client.add_bool "include_template" include_template
  |> Http_client.Client.add "recurrence" recurrence
  |> Http_client.Client.add_bool "closed" closed
  |> Http_client.Client.add_float "liquidity_min" liquidity_min
  |> Http_client.Client.add_float "liquidity_max" liquidity_max
  |> Http_client.Client.add_float "volume_min" volume_min
  |> Http_client.Client.add_float "volume_max" volume_max
  |> Http_client.Client.add_timestamp "start_date_min" start_date_min
  |> Http_client.Client.add_timestamp "start_date_max" start_date_max
  |> Http_client.Client.add_timestamp "end_date_min" end_date_min
  |> Http_client.Client.add_timestamp "end_date_max" end_date_max
  |> Http_client.Client.get_json_list t "/events" event_of_yojson

let get_event t ~id ?include_chat ?include_template () =
  []
  |> Http_client.Client.add_bool "include_chat" include_chat
  |> Http_client.Client.add_bool "include_template" include_template
  |> Http_client.Client.get_json t
       (Printf.sprintf "/events/%d" id)
       event_of_yojson

let get_event_tags t ~id () =
  []
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/events/%d/tags" id)
       tag_of_yojson

let get_event_by_slug t ~slug ?include_chat ?include_template () =
  []
  |> Http_client.Client.add_bool "include_chat" include_chat
  |> Http_client.Client.add_bool "include_template" include_template
  |> Http_client.Client.get_json t
       (Printf.sprintf "/events/slug/%s" slug)
       event_of_yojson

(** {1 Markets Endpoints} *)

let get_markets t ?limit ?offset ?order ?ascending ?id ?slug ?clob_token_ids
    ?condition_ids ?market_maker_address ?liquidity_num_min ?liquidity_num_max
    ?volume_num_min ?volume_num_max ?start_date_min ?start_date_max
    ?end_date_min ?end_date_max ?tag_id ?related_tags ?cyom
    ?uma_resolution_status ?game_id ?sports_market_types ?rewards_min_size
    ?question_ids ?include_tag ?closed () =
  []
  |> Http_client.Client.add_nonneg_int "limit" limit
  |> Http_client.Client.add_nonneg_int "offset" offset
  |> Http_client.Client.add "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add_int_array "id" id
  |> Http_client.Client.add_string_array "slug" slug
  |> Http_client.Client.add_string_array "clob_token_ids" clob_token_ids
  |> Http_client.Client.add_string_array "condition_ids" condition_ids
  |> Http_client.Client.add_string_array "market_maker_address"
       market_maker_address
  |> Http_client.Client.add_float "liquidity_num_min" liquidity_num_min
  |> Http_client.Client.add_float "liquidity_num_max" liquidity_num_max
  |> Http_client.Client.add_float "volume_num_min" volume_num_min
  |> Http_client.Client.add_float "volume_num_max" volume_num_max
  |> Http_client.Client.add_timestamp "start_date_min" start_date_min
  |> Http_client.Client.add_timestamp "start_date_max" start_date_max
  |> Http_client.Client.add_timestamp "end_date_min" end_date_min
  |> Http_client.Client.add_timestamp "end_date_max" end_date_max
  |> Http_client.Client.add_int "tag_id" tag_id
  |> Http_client.Client.add_bool "related_tags" related_tags
  |> Http_client.Client.add_bool "cyom" cyom
  |> Http_client.Client.add "uma_resolution_status" uma_resolution_status
  |> Http_client.Client.add "game_id" game_id
  |> Http_client.Client.add_string_array "sports_market_types"
       sports_market_types
  |> Http_client.Client.add_float "rewards_min_size" rewards_min_size
  |> Http_client.Client.add_string_array "question_ids" question_ids
  |> Http_client.Client.add_bool "include_tag" include_tag
  |> Http_client.Client.add_bool "closed" closed
  |> Http_client.Client.get_json_list t "/markets" market_of_yojson

let get_market t ~id ?include_tag () =
  []
  |> Http_client.Client.add_bool "include_tag" include_tag
  |> Http_client.Client.get_json t
       (Printf.sprintf "/markets/%d" id)
       market_of_yojson

let get_market_tags t ~id () =
  []
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/markets/%d/tags" id)
       tag_of_yojson

let get_market_by_slug t ~slug ?include_tag () =
  []
  |> Http_client.Client.add_bool "include_tag" include_tag
  |> Http_client.Client.get_json t
       (Printf.sprintf "/markets/slug/%s" slug)
       market_of_yojson

(** {1 Series Endpoints} *)

let get_series_list t ?limit ?offset ?order ?ascending ?slug ?categories_ids
    ?categories_labels ?closed ?include_chat ?recurrence () =
  []
  |> Http_client.Client.add_nonneg_int "limit" limit
  |> Http_client.Client.add_nonneg_int "offset" offset
  |> Http_client.Client.add "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add_string_array "slug" slug
  |> Http_client.Client.add_int_array "categories_ids" categories_ids
  |> Http_client.Client.add_string_array "categories_labels" categories_labels
  |> Http_client.Client.add_bool "closed" closed
  |> Http_client.Client.add_bool "include_chat" include_chat
  |> Http_client.Client.add "recurrence" recurrence
  |> Http_client.Client.get_json_list t "/series" series_of_yojson

let get_series t ~id ?include_chat () =
  []
  |> Http_client.Client.add_bool "include_chat" include_chat
  |> Http_client.Client.get_json t
       (Printf.sprintf "/series/%d" id)
       series_of_yojson

(** {1 Comments Endpoints} *)

let get_comments t ?limit ?offset ?order ?ascending ?parent_entity_type
    ?parent_entity_id ?get_positions ?holders_only () =
  []
  |> Http_client.Client.add_nonneg_int "limit" limit
  |> Http_client.Client.add_nonneg_int "offset" offset
  |> Http_client.Client.add "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.add "parent_entity_type"
       (Option.map string_of_parent_entity_type parent_entity_type)
  |> Http_client.Client.add_int "parent_entity_id" parent_entity_id
  |> Http_client.Client.add_bool "get_positions" get_positions
  |> Http_client.Client.add_bool "holders_only" holders_only
  |> Http_client.Client.get_json_list t "/comments" comment_of_yojson

let get_comment t ~id ?get_positions () =
  []
  |> Http_client.Client.add_bool "get_positions" get_positions
  |> Http_client.Client.get_json t
       (Printf.sprintf "/comments/%d" id)
       comment_of_yojson

let get_user_comments t ~user_address ?limit ?offset ?order ?ascending () =
  []
  |> Http_client.Client.add_nonneg_int "limit" limit
  |> Http_client.Client.add_nonneg_int "offset" offset
  |> Http_client.Client.add "order" order
  |> Http_client.Client.add_bool "ascending" ascending
  |> Http_client.Client.get_json_list t
       (Printf.sprintf "/comments/user_address/%s" user_address)
       comment_of_yojson

(** {1 Profile Endpoints} *)

let get_public_profile t ~address () =
  [ ("address", [ address ]) ]
  |> Http_client.Client.get_json t "/public-profile"
       public_profile_response_of_yojson

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
  |> Http_client.Client.add_int_array "exclude_tag_id" exclude_tag_id
  |> Http_client.Client.add_bool "optimized" optimized
  |> Http_client.Client.get_json t "/public-search" search_of_yojson
