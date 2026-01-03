(** Data API client for positions, trades, activity, and leaderboards. *)

include module type of struct
  include Data_types
end

module N = Primitives.Nonneg_int
(** Non-negative integer type for limit/offset parameters *)

type t
(** The Data API client type. *)

val default_base_url : string
(** Default base URL: https://data-api.polymarket.com *)

val create :
  ?base_url:string ->
  sw:Eio.Switch.t ->
  net:'a Eio.Net.t ->
  rate_limiter:Rate_limiter.t ->
  unit ->
  t
(** Create a Data API client.
    @param base_url Override the default base URL
    @param sw Eio switch for resource management
    @param net Eio network capability
    @param rate_limiter Rate limiter for API requests *)

(** {1 Health Endpoint} *)

val health_check : t -> (health_response, error) result
(** Check if the API is healthy.
    @return [Ok response] on success, [Error error] on failure *)

(** {1 Position Endpoints} *)

val get_positions :
  t ->
  user:Primitives.Address.t ->
  ?market:Primitives.Hash64.t list ->
  ?event_id:int list ->
  ?size_threshold:float ->
  ?redeemable:bool ->
  ?mergeable:bool ->
  ?limit:N.t ->
  ?offset:N.t ->
  ?sort_by:Position_sort_by.t ->
  ?sort_direction:Sort_direction.t ->
  ?title:string ->
  unit ->
  (position list, error) result
(** Get current positions for a user.
    @param user User address (required)
    @param market
      Comma-separated condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs >= 1 (mutually exclusive with market)
    @param size_threshold Minimum position size >= 0 (default: 1)
    @param redeemable Filter redeemable positions (default: false)
    @param mergeable Filter mergeable positions (default: false)
    @param limit Maximum results 0-500 (default: 100)
    @param offset Pagination offset 0-10000 (default: 0)
    @param sort_by Sort field (default: TOKENS)
    @param sort_direction Sort direction (default: DESC)
    @param title Filter by title (max 100 chars) *)

val get_closed_positions :
  t ->
  user:Primitives.Address.t ->
  ?market:Primitives.Hash64.t list ->
  ?event_id:int list ->
  ?title:string ->
  ?sort_by:Closed_position_sort_by.t ->
  ?sort_direction:Sort_direction.t ->
  ?limit:N.t ->
  ?offset:N.t ->
  unit ->
  (closed_position list, error) result
(** Get closed positions for a user.
    @param user User address (required)
    @param market Condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs >= 1 (mutually exclusive with market)
    @param title Filter by title (max 100 chars)
    @param sort_by Sort field (default: REALIZEDPNL)
    @param sort_direction Sort direction (default: DESC)
    @param limit Maximum results 0-50 (default: 10)
    @param offset Pagination offset 0-100000 (default: 0) *)

(** {1 Trade Endpoints} *)

val get_trades :
  t ->
  ?user:Primitives.Address.t ->
  ?market:Primitives.Hash64.t list ->
  ?event_id:int list ->
  ?side:Side.t ->
  ?filter_type:Filter_type.t ->
  ?filter_amount:float ->
  ?taker_only:bool ->
  ?limit:N.t ->
  ?offset:N.t ->
  unit ->
  (trade list, error) result
(** Get trades for a user or markets.
    @param user User address
    @param market Condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs >= 1 (mutually exclusive with market)
    @param side Filter by BUY or SELL
    @param filter_type Filter type (must be provided with filter_amount)
    @param filter_amount Filter amount >= 0 (must be provided with filter_type)
    @param taker_only Only taker trades (default: true)
    @param limit Maximum results >= 0 (default: 100, max: 10000)
    @param offset Pagination offset >= 0 (default: 0, max: 10000) *)

(** {1 Activity Endpoint} *)

val get_activity :
  t ->
  user:Primitives.Address.t ->
  ?market:Primitives.Hash64.t list ->
  ?event_id:int list ->
  ?activity_types:Activity_type.t list ->
  ?side:Side.t ->
  ?start_time:int ->
  ?end_time:int ->
  ?sort_by:Activity_sort_by.t ->
  ?sort_direction:Sort_direction.t ->
  ?limit:N.t ->
  ?offset:N.t ->
  unit ->
  (activity list, error) result
(** Get user activity (on-chain).
    @param user User address (required)
    @param market Condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs >= 1 (mutually exclusive with market)
    @param activity_types Filter by activity types
    @param side Filter by BUY or SELL
    @param start_time Start timestamp >= 0
    @param end_time End timestamp >= 0
    @param sort_by Sort field (default: TIMESTAMP)
    @param sort_direction Sort direction (default: DESC)
    @param limit Maximum results 0-500 (default: 100)
    @param offset Pagination offset 0-10000 (default: 0) *)

(** {1 Holders Endpoint} *)

val get_holders :
  t ->
  market:Primitives.Hash64.t list ->
  ?min_balance:int ->
  ?limit:N.t ->
  unit ->
  (meta_holder list, error) result
(** Get top holders for markets.
    @param market Condition IDs (required)
    @param min_balance Minimum balance 0-999999 (default: 1)
    @param limit Maximum holders per token 0-20 (default: 20) *)

(** {1 User Data Endpoints} *)

val get_traded :
  t -> user:Primitives.Address.t -> unit -> (traded, error) result
(** Get total markets a user has traded.
    @param user User address (required) *)

val get_value :
  t ->
  user:Primitives.Address.t ->
  ?market:Primitives.Hash64.t list ->
  unit ->
  (value list, error) result
(** Get total value of a user's positions.
    @param user User address (required)
    @param market Condition IDs to filter by *)

(** {1 Market Data Endpoints} *)

val get_open_interest :
  t ->
  ?market:Primitives.Hash64.t list ->
  unit ->
  (open_interest list, error) result
(** Get open interest for markets.
    @param market Condition IDs to filter by *)

val get_live_volume : t -> id:int -> unit -> (live_volume list, error) result
(** Get live volume for an event.
    @param id Event ID >= 1 (required) *)

(** {1 Leaderboard Endpoints} *)

val get_builder_leaderboard :
  t ->
  ?time_period:Time_period.t ->
  ?limit:N.t ->
  ?offset:N.t ->
  unit ->
  (leaderboard_entry list, error) result
(** Get aggregated builder leaderboard.
    @param time_period Time period to aggregate (default: DAY)
    @param limit Maximum results 0-50 (default: 25)
    @param offset Pagination offset 0-1000 (default: 0) *)

val get_builder_volume :
  t ->
  ?time_period:Time_period.t ->
  unit ->
  (builder_volume_entry list, error) result
(** Get daily builder volume time-series.
    @param time_period Time period for daily records (default: DAY) *)

val get_trader_leaderboard :
  t ->
  ?category:Leaderboard_category.t ->
  ?time_period:Time_period.t ->
  ?order_by:Leaderboard_order_by.t ->
  ?user:Primitives.Address.t ->
  ?user_name:string ->
  ?limit:N.t ->
  ?offset:N.t ->
  unit ->
  (trader_leaderboard_entry list, error) result
(** Get trader leaderboard rankings.
    @param category Market category (default: OVERALL)
    @param time_period Time period (default: DAY)
    @param order_by Ordering criteria (default: PNL)
    @param user Filter to single user by address
    @param user_name Filter to single username
    @param limit Maximum results 1-50 (default: 25)
    @param offset Pagination offset 0-1000 (default: 0) *)
