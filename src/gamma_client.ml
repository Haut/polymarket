(** Gamma API client for markets, events, series, and search. *)

module P = Primitives
module N = P.Nonneg_int
module B = Http_builder
include Gamma_types

type t = Http_client.t

let default_base_url = "https://gamma-api.polymarket.com"

let create ?(base_url = default_base_url) ~sw ~net ~rate_limiter () =
  Http_client.create ~base_url ~sw ~net ~rate_limiter ()

(** {1 Health Endpoint} *)

let status t = B.new_get t "/status" |> B.fetch_text

(** {1 Teams Endpoints} *)

let get_teams t ?limit ?offset ?order ?ascending ?league ?name ?abbreviation ()
    =
  B.new_get t "/teams"
  |> B.query_option "limit" N.to_string limit
  |> B.query_option "offset" N.to_string offset
  |> B.query_each "order" Fun.id order
  |> B.query_bool "ascending" ascending
  |> B.query_each "league" Fun.id league
  |> B.query_each "name" Fun.id name
  |> B.query_each "abbreviation" Fun.id abbreviation
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_team ~context:"team"
       team_of_yojson

let get_sports t () =
  B.new_get t "/sports"
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_sports_metadata
       ~context:"sports_metadata" sports_metadata_of_yojson

let get_sports_market_types t () =
  B.new_get t "/sports/market-types"
  |> B.fetch_json ~expected_fields:yojson_fields_of_sports_market_types_response
       ~context:"sports_market_types_response"
       sports_market_types_response_of_yojson

(** {1 Tags Endpoints} *)

let get_tags t ?limit ?offset ?order ?ascending ?include_template ?is_carousel
    () =
  B.new_get t "/tags"
  |> B.query_option "limit" N.to_string limit
  |> B.query_option "offset" N.to_string offset
  |> B.query_each "order" Fun.id order
  |> B.query_bool "ascending" ascending
  |> B.query_bool "include_template" include_template
  |> B.query_bool "is_carousel" is_carousel
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_tag ~context:"tag"
       tag_of_yojson

let get_tag t ~id ?include_template () =
  B.new_get t (Printf.sprintf "/tags/%s" id)
  |> B.query_bool "include_template" include_template
  |> B.fetch_json ~expected_fields:yojson_fields_of_tag ~context:"tag"
       tag_of_yojson

let get_tag_by_slug t ~slug ?include_template () =
  B.new_get t (Printf.sprintf "/tags/slug/%s" slug)
  |> B.query_bool "include_template" include_template
  |> B.fetch_json ~expected_fields:yojson_fields_of_tag ~context:"tag"
       tag_of_yojson

let get_related_tags t ~id ?omit_empty ?status () =
  B.new_get t (Printf.sprintf "/tags/%s/related-tags" id)
  |> B.query_bool "omit_empty" omit_empty
  |> B.query_option "status" Status.to_string status
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_related_tag
       ~context:"related_tag" related_tag_of_yojson

let get_related_tags_by_slug t ~slug ?omit_empty ?status () =
  B.new_get t (Printf.sprintf "/tags/slug/%s/related-tags" slug)
  |> B.query_bool "omit_empty" omit_empty
  |> B.query_option "status" Status.to_string status
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_related_tag
       ~context:"related_tag" related_tag_of_yojson

let get_related_tag_tags t ~id ?omit_empty ?status () =
  B.new_get t (Printf.sprintf "/tags/%s/related-tags/tags" id)
  |> B.query_bool "omit_empty" omit_empty
  |> B.query_option "status" Status.to_string status
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_tag ~context:"tag"
       tag_of_yojson

let get_related_tag_tags_by_slug t ~slug ?omit_empty ?status () =
  B.new_get t (Printf.sprintf "/tags/slug/%s/related-tags/tags" slug)
  |> B.query_bool "omit_empty" omit_empty
  |> B.query_option "status" Status.to_string status
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_tag ~context:"tag"
       tag_of_yojson

(** {1 Events Endpoints} *)

let get_events t ?limit ?offset ?order ?ascending ?id ?tag_id ?exclude_tag_id
    ?slug ?tag_slug ?related_tags ?active ?archived ?featured ?cyom
    ?include_chat ?include_template ?recurrence ?closed ?liquidity_min
    ?liquidity_max ?volume_min ?volume_max ?start_date_min ?start_date_max
    ?end_date_min ?end_date_max () =
  B.new_get t "/events"
  |> B.query_option "limit" N.to_string limit
  |> B.query_option "offset" N.to_string offset
  |> B.query_each "order" Fun.id order
  |> B.query_bool "ascending" ascending
  |> B.query_each "id" string_of_int id
  |> B.query_option "tag_id" string_of_int tag_id
  |> B.query_each "exclude_tag_id" string_of_int exclude_tag_id
  |> B.query_each "slug" Fun.id slug
  |> B.query_add "tag_slug" tag_slug
  |> B.query_bool "related_tags" related_tags
  |> B.query_bool "active" active
  |> B.query_bool "archived" archived
  |> B.query_bool "featured" featured
  |> B.query_bool "cyom" cyom
  |> B.query_bool "include_chat" include_chat
  |> B.query_bool "include_template" include_template
  |> B.query_add "recurrence" recurrence
  |> B.query_bool "closed" closed
  |> B.query_option "liquidity_min" string_of_float liquidity_min
  |> B.query_option "liquidity_max" string_of_float liquidity_max
  |> B.query_option "volume_min" string_of_float volume_min
  |> B.query_option "volume_max" string_of_float volume_max
  |> B.query_option "start_date_min" P.Timestamp.to_string start_date_min
  |> B.query_option "start_date_max" P.Timestamp.to_string start_date_max
  |> B.query_option "end_date_min" P.Timestamp.to_string end_date_min
  |> B.query_option "end_date_max" P.Timestamp.to_string end_date_max
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_event ~context:"event"
       event_of_yojson

let get_event t ~id ?include_chat ?include_template () =
  B.new_get t (Printf.sprintf "/events/%s" id)
  |> B.query_bool "include_chat" include_chat
  |> B.query_bool "include_template" include_template
  |> B.fetch_json ~expected_fields:yojson_fields_of_event ~context:"event"
       event_of_yojson

let get_event_tags t ~id () =
  B.new_get t (Printf.sprintf "/events/%s/tags" id)
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_tag ~context:"tag"
       tag_of_yojson

let get_event_by_slug t ~slug ?include_chat ?include_template () =
  B.new_get t (Printf.sprintf "/events/slug/%s" slug)
  |> B.query_bool "include_chat" include_chat
  |> B.query_bool "include_template" include_template
  |> B.fetch_json ~expected_fields:yojson_fields_of_event ~context:"event"
       event_of_yojson

(** {1 Markets Endpoints} *)

let get_markets t ?limit ?offset ?order ?ascending ?id ?slug ?clob_token_ids
    ?condition_ids ?market_maker_address ?liquidity_num_min ?liquidity_num_max
    ?volume_num_min ?volume_num_max ?start_date_min ?start_date_max
    ?end_date_min ?end_date_max ?tag_id ?related_tags ?cyom
    ?uma_resolution_status ?game_id ?sports_market_types ?rewards_min_size
    ?question_ids ?include_tag ?closed () =
  B.new_get t "/markets"
  |> B.query_option "limit" N.to_string limit
  |> B.query_option "offset" N.to_string offset
  |> B.query_add "order" order
  |> B.query_bool "ascending" ascending
  |> B.query_each "id" string_of_int id
  |> B.query_each "slug" Fun.id slug
  |> B.query_each "clob_token_ids" Fun.id clob_token_ids
  |> B.query_each "condition_ids" Fun.id condition_ids
  |> B.query_each "market_maker_address" Fun.id market_maker_address
  |> B.query_option "liquidity_num_min" string_of_float liquidity_num_min
  |> B.query_option "liquidity_num_max" string_of_float liquidity_num_max
  |> B.query_option "volume_num_min" string_of_float volume_num_min
  |> B.query_option "volume_num_max" string_of_float volume_num_max
  |> B.query_option "start_date_min" P.Timestamp.to_string start_date_min
  |> B.query_option "start_date_max" P.Timestamp.to_string start_date_max
  |> B.query_option "end_date_min" P.Timestamp.to_string end_date_min
  |> B.query_option "end_date_max" P.Timestamp.to_string end_date_max
  |> B.query_option "tag_id" string_of_int tag_id
  |> B.query_bool "related_tags" related_tags
  |> B.query_bool "cyom" cyom
  |> B.query_add "uma_resolution_status" uma_resolution_status
  |> B.query_add "game_id" game_id
  |> B.query_each "sports_market_types" Fun.id sports_market_types
  |> B.query_option "rewards_min_size" string_of_float rewards_min_size
  |> B.query_each "question_ids" Fun.id question_ids
  |> B.query_bool "include_tag" include_tag
  |> B.query_bool "closed" closed
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_market
       ~context:"market" market_of_yojson

let get_market t ~id ?include_tag () =
  B.new_get t (Printf.sprintf "/markets/%s" id)
  |> B.query_bool "include_tag" include_tag
  |> B.fetch_json ~expected_fields:yojson_fields_of_market ~context:"market"
       market_of_yojson

let get_market_tags t ~id () =
  B.new_get t (Printf.sprintf "/markets/%s/tags" id)
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_tag ~context:"tag"
       tag_of_yojson

let get_market_by_slug t ~slug ?include_tag () =
  B.new_get t (Printf.sprintf "/markets/slug/%s" slug)
  |> B.query_bool "include_tag" include_tag
  |> B.fetch_json ~expected_fields:yojson_fields_of_market ~context:"market"
       market_of_yojson

(** {1 Series Endpoints} *)

let get_series_list t ?limit ?offset ?order ?ascending ?slug ?categories_ids
    ?categories_labels ?closed ?include_chat ?recurrence () =
  B.new_get t "/series"
  |> B.query_option "limit" N.to_string limit
  |> B.query_option "offset" N.to_string offset
  |> B.query_add "order" order
  |> B.query_bool "ascending" ascending
  |> B.query_each "slug" Fun.id slug
  |> B.query_each "categories_ids" string_of_int categories_ids
  |> B.query_each "categories_labels" Fun.id categories_labels
  |> B.query_bool "closed" closed
  |> B.query_bool "include_chat" include_chat
  |> B.query_add "recurrence" recurrence
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_series
       ~context:"series" series_of_yojson

let get_series t ~id ?include_chat () =
  B.new_get t (Printf.sprintf "/series/%s" id)
  |> B.query_bool "include_chat" include_chat
  |> B.fetch_json ~expected_fields:yojson_fields_of_series ~context:"series"
       series_of_yojson

(** {1 Comments Endpoints} *)

let get_comments t ?limit ?offset ?order ?ascending ?parent_entity_type
    ?parent_entity_id ?get_positions ?holders_only () =
  B.new_get t "/comments"
  |> B.query_option "limit" N.to_string limit
  |> B.query_option "offset" N.to_string offset
  |> B.query_add "order" order
  |> B.query_bool "ascending" ascending
  |> B.query_option "parent_entity_type" Parent_entity_type.to_string
       parent_entity_type
  |> B.query_option "parent_entity_id" string_of_int parent_entity_id
  |> B.query_bool "get_positions" get_positions
  |> B.query_bool "holders_only" holders_only
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_comment
       ~context:"comment" comment_of_yojson

let get_comment t ~id ?get_positions () =
  B.new_get t (Printf.sprintf "/comments/%s" id)
  |> B.query_bool "get_positions" get_positions
  |> B.fetch_json ~expected_fields:yojson_fields_of_comment ~context:"comment"
       comment_of_yojson

let get_user_comments t ~user_address ?limit ?offset ?order ?ascending () =
  B.new_get t (Printf.sprintf "/comments/user_address/%s" user_address)
  |> B.query_option "limit" N.to_string limit
  |> B.query_option "offset" N.to_string offset
  |> B.query_add "order" order
  |> B.query_bool "ascending" ascending
  |> B.fetch_json_list ~expected_fields:yojson_fields_of_comment
       ~context:"comment" comment_of_yojson

(** {1 Profile Endpoints} *)

let get_public_profile t ~address () =
  B.new_get t "/public-profile"
  |> B.query_param "address" address
  |> B.fetch_json ~expected_fields:yojson_fields_of_public_profile_response
       ~context:"public_profile_response" public_profile_response_of_yojson

(** {1 Search Endpoint} *)

let public_search t ~q ?cache ?events_status ?limit_per_type ?page ?events_tag
    ?keep_closed_markets ?sort ?ascending ?search_tags ?search_profiles
    ?recurrence ?exclude_tag_id ?optimized () =
  B.new_get t "/public-search"
  |> B.query_param "q" q |> B.query_bool "cache" cache
  |> B.query_add "events_status" events_status
  |> B.query_option "limit_per_type" N.to_string limit_per_type
  |> B.query_option "page" N.to_string page
  |> B.query_each "events_tag" Fun.id events_tag
  |> B.query_option "keep_closed_markets" string_of_int keep_closed_markets
  |> B.query_add "sort" sort
  |> B.query_bool "ascending" ascending
  |> B.query_bool "search_tags" search_tags
  |> B.query_bool "search_profiles" search_profiles
  |> B.query_add "recurrence" recurrence
  |> B.query_each "exclude_tag_id" string_of_int exclude_tag_id
  |> B.query_bool "optimized" optimized
  |> B.fetch_json ~expected_fields:yojson_fields_of_search ~context:"search"
       search_of_yojson
