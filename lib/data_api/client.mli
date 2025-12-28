(** HTTP client for the Polymarket Data API.

    This module provides functions to interact with all public endpoints of the
    Polymarket Data API (https://data-api.polymarket.com).

    {2 Example Usage}

    {[
      Eio_main.run @@ fun env ->
      Eio.Switch.run @@ fun sw ->
      let client =
        Polymarket.Data_api.Client.create ~sw ~net:(Eio.Stdenv.net env) ()
      in
      match Polymarket.Data_api.Client.health_check client with
      | Ok response -> print_endline (Option.value ~default:"OK" response.data)
      | Error err ->
          print_endline ("Error: " ^ Polymarket_http.Client.error_to_string err)
    ]} *)

open Types

(** {1 Client Configuration} *)

type t
(** The client type holding connection configuration *)

val default_base_url : string
(** Default base URL for the Polymarket Data API *)

val create :
  ?base_url:string ->
  sw:Eio.Switch.t ->
  net:_ Eio.Net.t ->
  rate_limiter:Polymarket_rate_limiter.Rate_limiter.t ->
  unit ->
  t
(** Create a new client instance.
    @param base_url The API base URL (default: {!default_base_url})
    @param sw The Eio switch for resource management
    @param net The Eio network interface
    @param rate_limiter Shared rate limiter for enforcing API limits *)

(** {1 Health Endpoint} *)

val health_check : t -> (health_response, Polymarket_http.Client.error) result
(** Check if the API is healthy.
    @return [Ok response] on success, [Error error] on failure *)

(** {1 Position Endpoints} *)

val get_positions :
  t ->
  user:Polymarket_common.Primitives.Address.t ->
  ?market:Polymarket_common.Primitives.Hash64.t list ->
  ?event_id:Polymarket_common.Primitives.Pos_int.t list ->
  ?size_threshold:Polymarket_common.Primitives.Nonneg_float.t ->
  ?redeemable:bool ->
  ?mergeable:bool ->
  ?limit:Polymarket_common.Primitives.Limit.t ->
  ?offset:Polymarket_common.Primitives.Offset.t ->
  ?sort_by:Position_sort_by.t ->
  ?sort_direction:Sort_direction.t ->
  ?title:Polymarket_common.Primitives.Bounded_string.t ->
  unit ->
  (position list, Polymarket_http.Client.error) result
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
  user:Polymarket_common.Primitives.Address.t ->
  ?market:Polymarket_common.Primitives.Hash64.t list ->
  ?event_id:Polymarket_common.Primitives.Pos_int.t list ->
  ?title:Polymarket_common.Primitives.Bounded_string.t ->
  ?sort_by:Closed_position_sort_by.t ->
  ?sort_direction:Sort_direction.t ->
  ?limit:Polymarket_common.Primitives.Closed_positions_limit.t ->
  ?offset:Polymarket_common.Primitives.Extended_offset.t ->
  unit ->
  (closed_position list, Polymarket_http.Client.error) result
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
  ?user:Polymarket_common.Primitives.Address.t ->
  ?market:Polymarket_common.Primitives.Hash64.t list ->
  ?event_id:Polymarket_common.Primitives.Pos_int.t list ->
  ?side:Side.t ->
  ?filter_type:Filter_type.t ->
  ?filter_amount:Polymarket_common.Primitives.Nonneg_float.t ->
  ?taker_only:bool ->
  ?limit:Polymarket_common.Primitives.Nonneg_int.t ->
  ?offset:Polymarket_common.Primitives.Nonneg_int.t ->
  unit ->
  (trade list, Polymarket_http.Client.error) result
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
  user:Polymarket_common.Primitives.Address.t ->
  ?market:Polymarket_common.Primitives.Hash64.t list ->
  ?event_id:Polymarket_common.Primitives.Pos_int.t list ->
  ?activity_types:Activity_type.t list ->
  ?side:Side.t ->
  ?start_time:Polymarket_common.Primitives.Nonneg_int.t ->
  ?end_time:Polymarket_common.Primitives.Nonneg_int.t ->
  ?sort_by:Activity_sort_by.t ->
  ?sort_direction:Sort_direction.t ->
  ?limit:Polymarket_common.Primitives.Limit.t ->
  ?offset:Polymarket_common.Primitives.Offset.t ->
  unit ->
  (activity list, Polymarket_http.Client.error) result
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
  market:Polymarket_common.Primitives.Hash64.t list ->
  ?min_balance:Polymarket_common.Primitives.Min_balance.t ->
  ?limit:Polymarket_common.Primitives.Holders_limit.t ->
  unit ->
  (meta_holder list, Polymarket_http.Client.error) result
(** Get top holders for markets.
    @param market Condition IDs (required)
    @param min_balance Minimum balance 0-999999 (default: 1)
    @param limit Maximum holders per token 0-20 (default: 20) *)

(** {1 User Data Endpoints} *)

val get_traded :
  t ->
  user:Polymarket_common.Primitives.Address.t ->
  unit ->
  (traded, Polymarket_http.Client.error) result
(** Get total markets a user has traded.
    @param user User address (required) *)

val get_value :
  t ->
  user:Polymarket_common.Primitives.Address.t ->
  ?market:Polymarket_common.Primitives.Hash64.t list ->
  unit ->
  (value list, Polymarket_http.Client.error) result
(** Get total value of a user's positions.
    @param user User address (required)
    @param market Condition IDs to filter by *)

(** {1 Market Data Endpoints} *)

val get_open_interest :
  t ->
  ?market:Polymarket_common.Primitives.Hash64.t list ->
  unit ->
  (open_interest list, Polymarket_http.Client.error) result
(** Get open interest for markets.
    @param market Condition IDs to filter by *)

val get_live_volume :
  t ->
  id:Polymarket_common.Primitives.Pos_int.t ->
  unit ->
  (live_volume list, Polymarket_http.Client.error) result
(** Get live volume for an event.
    @param id Event ID >= 1 (required) *)

(** {1 Leaderboard Endpoints} *)

val get_builder_leaderboard :
  t ->
  ?time_period:Time_period.t ->
  ?limit:Polymarket_common.Primitives.Builder_limit.t ->
  ?offset:Polymarket_common.Primitives.Leaderboard_offset.t ->
  unit ->
  (leaderboard_entry list, Polymarket_http.Client.error) result
(** Get aggregated builder leaderboard.
    @param time_period Time period to aggregate (default: DAY)
    @param limit Maximum results 0-50 (default: 25)
    @param offset Pagination offset 0-1000 (default: 0) *)

val get_builder_volume :
  t ->
  ?time_period:Time_period.t ->
  unit ->
  (builder_volume_entry list, Polymarket_http.Client.error) result
(** Get daily builder volume time-series.
    @param time_period Time period for daily records (default: DAY) *)

val get_trader_leaderboard :
  t ->
  ?category:Leaderboard_category.t ->
  ?time_period:Time_period.t ->
  ?order_by:Leaderboard_order_by.t ->
  ?user:Polymarket_common.Primitives.Address.t ->
  ?user_name:string ->
  ?limit:Polymarket_common.Primitives.Leaderboard_limit.t ->
  ?offset:Polymarket_common.Primitives.Leaderboard_offset.t ->
  unit ->
  (trader_leaderboard_entry list, Polymarket_http.Client.error) result
(** Get trader leaderboard rankings.
    @param category Market category (default: OVERALL)
    @param time_period Time period (default: DAY)
    @param order_by Ordering criteria (default: PNL)
    @param user Filter to single user by address
    @param user_name Filter to single username
    @param limit Maximum results 1-50 (default: 25)
    @param offset Pagination offset 0-1000 (default: 0) *)
