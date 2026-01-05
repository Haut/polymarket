(** Gamma API client for markets, events, series, and search. *)

include module type of struct
  include Types
end

type t
(** The Gamma API client type. *)

type init_error = Polymarket_http.Client.init_error
(** TLS/CA initialization error type *)

val string_of_init_error : init_error -> string
(** Convert initialization error to string *)

val default_base_url : string
(** Default base URL: https://gamma-api.polymarket.com *)

val create :
  ?base_url:string ->
  sw:Eio.Switch.t ->
  net:'a Eio.Net.t ->
  rate_limiter:Rate_limiter.t ->
  unit ->
  (t, init_error) result
(** Create a Gamma API client.
    @param base_url Override the default base URL
    @param sw Eio switch for resource management
    @param net Eio network capability
    @param rate_limiter Rate limiter for API requests
    @return Ok client on success, Error on TLS initialization failure *)

(** {1 Health Endpoint} *)

val status : t -> (string, error) result
(** Check if the API is healthy.
    @return [Ok "OK"] on success, [Error error] on failure *)

(** {1 Teams Endpoints} *)

val get_teams :
  t ->
  ?limit:int ->
  ?offset:int ->
  ?order:string list ->
  ?ascending:bool ->
  ?league:string list ->
  ?name:string list ->
  ?abbreviation:string list ->
  unit ->
  (team list, error) result
(** Get list of sports teams.
    @param limit Maximum number of results (non-negative)
    @param offset Pagination offset (non-negative)
    @param order Fields to order by
    @param ascending Sort ascending if true
    @param league Filter by league(s)
    @param name Filter by team name(s)
    @param abbreviation Filter by team abbreviation(s) *)

val get_sports : t -> unit -> (sports_metadata list, error) result
(** Get list of sports with metadata. *)

val get_sports_market_types :
  t -> unit -> (sports_market_types_response, error) result
(** Get list of sports market types. *)

(** {1 Tags Endpoints} *)

val get_tags :
  t ->
  ?limit:int ->
  ?offset:int ->
  ?order:string list ->
  ?ascending:bool ->
  ?include_template:bool ->
  ?is_carousel:bool ->
  unit ->
  (tag list, error) result
(** Get list of tags.
    @param limit Maximum number of results (non-negative)
    @param offset Pagination offset (non-negative)
    @param order Fields to order by
    @param ascending Sort ascending if true
    @param include_template Include template tags if true
    @param is_carousel Filter by carousel flag *)

val get_tag :
  t -> id:string -> ?include_template:bool -> unit -> (tag, error) result
(** Get a tag by ID.
    @param id Tag ID (required)
    @param include_template Include template data if true *)

val get_tag_by_slug :
  t -> slug:string -> ?include_template:bool -> unit -> (tag, error) result
(** Get a tag by slug.
    @param slug Tag slug (required)
    @param include_template Include template data if true *)

val get_related_tags :
  t ->
  id:string ->
  ?omit_empty:bool ->
  ?status:Status.t ->
  unit ->
  (related_tag list, error) result
(** Get related tags for a tag.
    @param id Tag ID (required)
    @param omit_empty Omit empty related tags
    @param status Filter by status (active, closed, all) *)

val get_related_tags_by_slug :
  t ->
  slug:string ->
  ?omit_empty:bool ->
  ?status:Status.t ->
  unit ->
  (related_tag list, error) result
(** Get related tags for a tag by slug.
    @param slug Tag slug (required)
    @param omit_empty Omit empty related tags
    @param status Filter by status (active, closed, all) *)

val get_related_tag_tags :
  t ->
  id:string ->
  ?omit_empty:bool ->
  ?status:Status.t ->
  unit ->
  (tag list, error) result
(** Get full tag objects for tags related to a tag.
    @param id Tag ID (required)
    @param omit_empty Omit empty related tags
    @param status Filter by status (active, closed, all) *)

val get_related_tag_tags_by_slug :
  t ->
  slug:string ->
  ?omit_empty:bool ->
  ?status:Status.t ->
  unit ->
  (tag list, error) result
(** Get full tag objects for tags related to a tag by slug.
    @param slug Tag slug (required)
    @param omit_empty Omit empty related tags
    @param status Filter by status (active, closed, all) *)

(** {1 Events Endpoints} *)

val get_events :
  t ->
  ?limit:int ->
  ?offset:int ->
  ?order:string list ->
  ?ascending:bool ->
  ?id:int list ->
  ?tag_id:int ->
  ?exclude_tag_id:int list ->
  ?slug:string list ->
  ?tag_slug:string ->
  ?related_tags:bool ->
  ?active:bool ->
  ?archived:bool ->
  ?featured:bool ->
  ?cyom:bool ->
  ?include_chat:bool ->
  ?include_template:bool ->
  ?recurrence:string ->
  ?closed:bool ->
  ?liquidity_min:float ->
  ?liquidity_max:float ->
  ?volume_min:float ->
  ?volume_max:float ->
  ?start_date_min:Common.Primitives.Timestamp.t ->
  ?start_date_max:Common.Primitives.Timestamp.t ->
  ?end_date_min:Common.Primitives.Timestamp.t ->
  ?end_date_max:Common.Primitives.Timestamp.t ->
  unit ->
  (event list, error) result
(** List events.
    @param limit Maximum number of results (non-negative)
    @param offset Pagination offset (non-negative)
    @param order Fields to order by
    @param ascending Sort ascending if true
    @param id Filter by event IDs (array)
    @param tag_id Filter by tag ID
    @param exclude_tag_id Exclude events with these tag IDs (array)
    @param slug Filter by event slugs (array)
    @param tag_slug Filter by tag slug
    @param related_tags Include related tags
    @param active Filter by active status
    @param archived Filter by archived status
    @param featured Filter by featured status
    @param cyom Filter by CYOM (create your own market) status
    @param include_chat Include chat data
    @param include_template Include template data
    @param recurrence Filter by recurrence type
    @param closed Filter by closed status
    @param liquidity_min Minimum liquidity
    @param liquidity_max Maximum liquidity
    @param volume_min Minimum volume
    @param volume_max Maximum volume
    @param start_date_min Minimum start date
    @param start_date_max Maximum start date
    @param end_date_min Minimum end date
    @param end_date_max Maximum end date *)

val get_event :
  t ->
  id:string ->
  ?include_chat:bool ->
  ?include_template:bool ->
  unit ->
  (event, error) result
(** Get an event by ID.
    @param id Event ID (required)
    @param include_chat Include chat data
    @param include_template Include template data *)

val get_event_by_slug :
  t ->
  slug:string ->
  ?include_chat:bool ->
  ?include_template:bool ->
  unit ->
  (event, error) result
(** Get an event by slug.
    @param slug Event slug (required)
    @param include_chat Include chat data
    @param include_template Include template data *)

val get_event_tags : t -> id:string -> unit -> (tag list, error) result
(** Get tags for an event.
    @param id Event ID (required) *)

(** {1 Markets Endpoints} *)

val get_markets :
  t ->
  ?limit:int ->
  ?offset:int ->
  ?order:string ->
  ?ascending:bool ->
  ?id:int list ->
  ?slug:string list ->
  ?clob_token_ids:string list ->
  ?condition_ids:string list ->
  ?market_maker_address:string list ->
  ?liquidity_num_min:float ->
  ?liquidity_num_max:float ->
  ?volume_num_min:float ->
  ?volume_num_max:float ->
  ?start_date_min:Common.Primitives.Timestamp.t ->
  ?start_date_max:Common.Primitives.Timestamp.t ->
  ?end_date_min:Common.Primitives.Timestamp.t ->
  ?end_date_max:Common.Primitives.Timestamp.t ->
  ?tag_id:int ->
  ?related_tags:bool ->
  ?cyom:bool ->
  ?uma_resolution_status:string ->
  ?game_id:string ->
  ?sports_market_types:string list ->
  ?rewards_min_size:float ->
  ?question_ids:string list ->
  ?include_tag:bool ->
  ?closed:bool ->
  unit ->
  (market list, error) result
(** Get list of markets.
    @param limit Maximum number of results (non-negative)
    @param offset Pagination offset (non-negative)
    @param order Comma-separated list of fields to order by
    @param ascending Sort ascending if true
    @param id Filter by market IDs (array)
    @param slug Filter by market slugs (array)
    @param clob_token_ids Filter by CLOB token IDs (array)
    @param condition_ids Filter by condition IDs (array)
    @param market_maker_address Filter by market maker addresses (array)
    @param liquidity_num_min Minimum liquidity
    @param liquidity_num_max Maximum liquidity
    @param volume_num_min Minimum volume
    @param volume_num_max Maximum volume
    @param start_date_min Minimum start date
    @param start_date_max Maximum start date
    @param end_date_min Minimum end date
    @param end_date_max Maximum end date
    @param tag_id Filter by tag ID
    @param related_tags Include related tags
    @param cyom Filter by CYOM (create your own market) status
    @param uma_resolution_status Filter by UMA resolution status
    @param game_id Filter by game ID
    @param sports_market_types Filter by sports market types (array)
    @param rewards_min_size Minimum rewards size
    @param question_ids Filter by question IDs (array)
    @param include_tag Include tag data
    @param closed Filter by closed status *)

val get_market :
  t -> id:string -> ?include_tag:bool -> unit -> (market, error) result
(** Get a market by ID.
    @param id Market ID (required)
    @param include_tag Include tag data *)

val get_market_by_slug :
  t -> slug:string -> ?include_tag:bool -> unit -> (market, error) result
(** Get a market by slug.
    @param slug Market slug (required)
    @param include_tag Include tag data *)

val get_market_tags : t -> id:string -> unit -> (tag list, error) result
(** Get tags for a market.
    @param id Market ID (required) *)

(** {1 Series Endpoints} *)

val get_series_list :
  t ->
  ?limit:int ->
  ?offset:int ->
  ?order:string ->
  ?ascending:bool ->
  ?slug:string list ->
  ?categories_ids:int list ->
  ?categories_labels:string list ->
  ?closed:bool ->
  ?include_chat:bool ->
  ?recurrence:string ->
  unit ->
  (series list, error) result
(** Get list of series.
    @param limit Maximum number of results (non-negative)
    @param offset Pagination offset (non-negative)
    @param order Comma-separated list of fields to order by
    @param ascending Sort ascending if true
    @param slug Filter by series slugs (array)
    @param categories_ids Filter by category IDs (array)
    @param categories_labels Filter by category labels (array)
    @param closed Filter by closed status
    @param include_chat Include chat data
    @param recurrence Filter by recurrence type *)

val get_series :
  t -> id:string -> ?include_chat:bool -> unit -> (series, error) result
(** Get a series by ID.
    @param id Series ID (required)
    @param include_chat Include chat data *)

(** {1 Comments Endpoints} *)

val get_comments :
  t ->
  ?limit:int ->
  ?offset:int ->
  ?order:string ->
  ?ascending:bool ->
  ?parent_entity_type:Parent_entity_type.t ->
  ?parent_entity_id:int ->
  ?get_positions:bool ->
  ?holders_only:bool ->
  unit ->
  (comment list, error) result
(** Get list of comments.
    @param limit Maximum number of results (non-negative)
    @param offset Pagination offset (non-negative)
    @param order Comma-separated list of fields to order by
    @param ascending Sort ascending if true
    @param parent_entity_type Entity type (Event, Series, market)
    @param parent_entity_id Entity ID
    @param get_positions Include position data
    @param holders_only Filter to holders only *)

val get_comment :
  t -> id:string -> ?get_positions:bool -> unit -> (comment, error) result
(** Get a comment by ID.
    @param id Comment ID (required)
    @param get_positions Include position data *)

val get_user_comments :
  t ->
  user_address:string ->
  ?limit:int ->
  ?offset:int ->
  ?order:string ->
  ?ascending:bool ->
  unit ->
  (comment list, error) result
(** Get comments by user address.
    @param user_address User address (required)
    @param limit Maximum number of results (non-negative)
    @param offset Pagination offset (non-negative)
    @param order Comma-separated list of fields to order by
    @param ascending Sort ascending if true *)

(** {1 Profile Endpoints} *)

val get_public_profile :
  t -> address:string -> unit -> (public_profile_response, error) result
(** Get public profile by address.
    @param address User address (required) *)

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
  (search, error) result
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
