(** HTTP client for the Polymarket Gamma API.

    This module provides functions to interact with all public endpoints of the
    Polymarket Gamma API (https://gamma-api.polymarket.com).

    {2 Example Usage}

    {[
      Eio_main.run @@ fun env ->
      Eio.Switch.run @@ fun sw ->
      let client =
        Polymarket.Gamma_api.Client.create ~sw ~net:(Eio.Stdenv.net env) ()
      in
      match Polymarket.Gamma_api.Client.status client with
      | Ok status -> print_endline status
      | Error err -> print_endline ("Error: " ^ err.error)
    ]} *)

open Types
open Params

(** {1 Client Configuration} *)

type t
(** The client type holding connection configuration *)

val default_base_url : string
(** Default base URL for the Polymarket Gamma API *)

val create : ?base_url:string -> sw:Eio.Switch.t -> net:_ Eio.Net.t -> unit -> t
(** Create a new client instance.
    @param base_url The API base URL (default: {!default_base_url})
    @param sw The Eio switch for resource management
    @param net The Eio network capability *)

(** {1 Health Endpoint} *)

val status : t -> (string, Http_client.Client.error_response) result
(** Check if the API is healthy.
    @return [Ok "OK"] on success, [Error error] on failure *)

(** {1 Teams Endpoints} *)

val get_teams :
  t -> ?id:int -> unit -> (team list, Http_client.Client.error_response) result
(** Get list of sports teams.
    @param id Optional team ID to filter by *)

val get_team :
  t -> id:int -> unit -> (team, Http_client.Client.error_response) result
(** Get a team by ID.
    @param id Team ID (required) *)

(** {1 Tags Endpoints} *)

val get_tags :
  t ->
  ?id:string ->
  ?label:string ->
  ?slug:string ->
  ?force_show:bool ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (tag list, Http_client.Client.error_response) result
(** Get list of tags.
    @param id Tag ID to filter by
    @param label Tag label to filter by
    @param slug Tag slug to filter by
    @param force_show Filter by force_show flag
    @param limit Maximum results
    @param offset Pagination offset *)

val get_tag :
  t -> id:string -> unit -> (tag, Http_client.Client.error_response) result
(** Get a tag by ID.
    @param id Tag ID (required) *)

val get_tag_by_slug :
  t -> slug:string -> unit -> (tag, Http_client.Client.error_response) result
(** Get a tag by slug.
    @param slug Tag slug (required) *)

val get_related_tags :
  t ->
  id:string ->
  unit ->
  (related_tag list, Http_client.Client.error_response) result
(** Get related tags for a tag.
    @param id Tag ID (required) *)

(** {1 Events Endpoints} *)

val get_events :
  t ->
  ?id:string ->
  ?ticker:string ->
  ?slug:string ->
  ?archived:bool ->
  ?active:bool ->
  ?closed:bool ->
  ?liquidity_min:float ->
  ?end_date_min:string ->
  ?end_date_max:string ->
  ?start_date_min:string ->
  ?start_date_max:string ->
  ?status:status ->
  ?order:string ->
  ?ascending:bool ->
  ?tag:string ->
  ?tag_slug:string ->
  ?limit:int ->
  ?offset:int ->
  ?cursor:string ->
  ?next_cursor:string ->
  ?slug_size:slug_size ->
  ?_c:string ->
  unit ->
  (event list, Http_client.Client.error_response) result
(** Get events list.
    @param id Event ID to filter by
    @param ticker Event ticker to filter by
    @param slug Event slug to filter by
    @param archived Filter by archived status
    @param active Filter by active status
    @param closed Filter by closed status
    @param liquidity_min Minimum liquidity
    @param end_date_min Minimum end date (ISO format)
    @param end_date_max Maximum end date (ISO format)
    @param start_date_min Minimum start date (ISO format)
    @param start_date_max Maximum start date (ISO format)
    @param status Filter by status (active, closed, all)
    @param order Order field
    @param ascending Sort ascending if true
    @param tag Tag to filter by
    @param tag_slug Tag slug to filter by
    @param limit Maximum results
    @param offset Pagination offset
    @param cursor Pagination cursor
    @param next_cursor Next pagination cursor
    @param slug_size Size for slug in response
    @param _c Cache buster parameter *)

val get_event :
  t -> id:int -> unit -> (event, Http_client.Client.error_response) result
(** Get an event by ID.
    @param id Event ID (required) *)

val get_event_by_slug :
  t -> slug:string -> unit -> (event, Http_client.Client.error_response) result
(** Get an event by slug.
    @param slug Event slug (required) *)

val get_event_tags :
  t -> id:int -> unit -> (tag list, Http_client.Client.error_response) result
(** Get tags for an event.
    @param id Event ID (required) *)

(** {1 Markets Endpoints} *)

val get_markets :
  t ->
  ?id:string ->
  ?condition_id:string ->
  ?slug:string ->
  ?archived:bool ->
  ?active:bool ->
  ?closed:bool ->
  ?clob_token_ids:string ->
  ?liquidity_num_min:float ->
  ?volume_num_min:float ->
  ?start_date_min:string ->
  ?start_date_max:string ->
  ?end_date_min:string ->
  ?end_date_max:string ->
  ?status:status ->
  ?order:string ->
  ?ascending:bool ->
  ?tag_slug:string ->
  ?limit:int ->
  ?offset:int ->
  ?cursor:string ->
  ?next_cursor:string ->
  ?slug_size:slug_size ->
  ?_c:string ->
  unit ->
  (market list, Http_client.Client.error_response) result
(** Get list of markets.
    @param id Market ID to filter by
    @param condition_id Condition ID to filter by
    @param slug Market slug to filter by
    @param archived Filter by archived status
    @param active Filter by active status
    @param closed Filter by closed status
    @param clob_token_ids CLOB token IDs to filter by
    @param liquidity_num_min Minimum liquidity
    @param volume_num_min Minimum volume
    @param start_date_min Minimum start date (ISO format)
    @param start_date_max Maximum start date (ISO format)
    @param end_date_min Minimum end date (ISO format)
    @param end_date_max Maximum end date (ISO format)
    @param status Filter by status (active, closed, all)
    @param order Order field
    @param ascending Sort ascending if true
    @param tag_slug Tag slug to filter by
    @param limit Maximum results
    @param offset Pagination offset
    @param cursor Pagination cursor
    @param next_cursor Next pagination cursor
    @param slug_size Size for slug in response
    @param _c Cache buster parameter *)

val get_market :
  t -> id:int -> unit -> (market, Http_client.Client.error_response) result
(** Get a market by ID.
    @param id Market ID (required) *)

val get_market_by_slug :
  t -> slug:string -> unit -> (market, Http_client.Client.error_response) result
(** Get a market by slug.
    @param slug Market slug (required) *)

val get_market_tags :
  t -> id:int -> unit -> (tag list, Http_client.Client.error_response) result
(** Get tags for a market.
    @param id Market ID (required) *)

val get_market_description :
  t ->
  id:int ->
  unit ->
  (market_description, Http_client.Client.error_response) result
(** Get description for a market.
    @param id Market ID (required) *)

(** {1 Series Endpoints} *)

val get_series_list :
  t ->
  ?id:string ->
  ?ticker:string ->
  ?slug:string ->
  ?archived:bool ->
  ?active:bool ->
  ?closed:bool ->
  ?status:status ->
  ?order:string ->
  ?ascending:bool ->
  ?limit:int ->
  ?offset:int ->
  ?cursor:string ->
  ?next_cursor:string ->
  unit ->
  (series list, Http_client.Client.error_response) result
(** Get list of series.
    @param id Series ID to filter by
    @param ticker Series ticker to filter by
    @param slug Series slug to filter by
    @param archived Filter by archived status
    @param active Filter by active status
    @param closed Filter by closed status
    @param status Filter by status (active, closed, all)
    @param order Order field
    @param ascending Sort ascending if true
    @param limit Maximum results
    @param offset Pagination offset
    @param cursor Pagination cursor
    @param next_cursor Next pagination cursor *)

val get_series :
  t -> id:int -> unit -> (series, Http_client.Client.error_response) result
(** Get a series by ID.
    @param id Series ID (required) *)

val get_series_summary :
  t ->
  id:int ->
  unit ->
  (series_summary, Http_client.Client.error_response) result
(** Get a series summary by ID.
    @param id Series ID (required) *)

(** {1 Comments Endpoints} *)

val get_comments :
  t ->
  ?parent_entity_type:parent_entity_type ->
  ?parent_entity_id:int ->
  ?parent_comment_id:string ->
  ?user_address:string ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (comment list, Http_client.Client.error_response) result
(** Get list of comments.
    @param parent_entity_type Entity type (Event, Series, market)
    @param parent_entity_id Entity ID
    @param parent_comment_id Parent comment ID for replies
    @param user_address Filter by user address
    @param limit Maximum results
    @param offset Pagination offset *)

val get_comment :
  t -> id:int -> unit -> (comment, Http_client.Client.error_response) result
(** Get a comment by ID.
    @param id Comment ID (required) *)

val get_user_comments :
  t ->
  user_address:string ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (comment list, Http_client.Client.error_response) result
(** Get comments by user address.
    @param user_address User address (required)
    @param limit Maximum results
    @param offset Pagination offset *)

(** {1 Profile Endpoints} *)

val get_public_profile :
  t ->
  address:string ->
  unit ->
  (public_profile_response, Http_client.Client.error_response) result
(** Get public profile by address.
    @param address User address (required) *)

val get_profile :
  t ->
  user_address:string ->
  unit ->
  (profile, Http_client.Client.error_response) result
(** Get profile by user address.
    @param user_address User address (required) *)

(** {1 Sports Endpoints} *)

val get_sports :
  t -> unit -> (sports_metadata list, Http_client.Client.error_response) result
(** Get list of sports with metadata. *)

val get_sports_market_types :
  t ->
  unit ->
  (sports_market_types_response, Http_client.Client.error_response) result
(** Get list of sports market types. *)

(** {1 Search Endpoint} *)

val public_search :
  t ->
  q:string ->
  ?cache:bool ->
  ?events_status:string ->
  ?limit_per_type:int ->
  ?page:int ->
  ?events_tag:string list ->
  ?keep_closed_markets:int ->
  ?sort:string ->
  ?ascending:bool ->
  ?search_tags:bool ->
  ?search_profiles:bool ->
  ?recurrence:string ->
  ?exclude_tag_id:int list ->
  ?optimized:bool ->
  unit ->
  (search, Http_client.Client.error_response) result
(** Search for events, tags, and profiles.
    @param q Search query (required)
    @param cache Enable caching
    @param events_status Filter events by status
    @param limit_per_type Maximum results per type
    @param page Pagination page number
    @param events_tag Filter by event tags (array)
    @param keep_closed_markets Include closed markets (0 or 1)
    @param sort Sort field
    @param ascending Sort ascending if true
    @param search_tags Include tags in search results
    @param search_profiles Include profiles in search results
    @param recurrence Filter by recurrence type
    @param exclude_tag_id Tag IDs to exclude (array)
    @param optimized Use optimized response format *)
