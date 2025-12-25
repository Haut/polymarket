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
      | Error err -> print_endline ("Error: " ^ err.error)
    ]} *)

open Types

(** {1 Client Configuration} *)

type t
(** The client type holding connection configuration *)

val default_base_url : string
(** Default base URL for the Polymarket Data API *)

val create : ?base_url:string -> sw:Eio.Switch.t -> net:_ Eio.Net.t -> unit -> t
(** Create a new client instance.
    @param base_url The API base URL (default: {!default_base_url})
    @param sw The Eio switch for resource management
    @param net The Eio network capability *)

(** {1 Health Endpoint} *)

val health_check : t -> (health_response, error_response) result
(** Check if the API is healthy.
    @return [Ok response] on success, [Error error] on failure *)

(** {1 Position Endpoints} *)

val get_positions :
  t ->
  user:Common.Primitives.Address.t ->
  ?market:Common.Primitives.Hash64.t list ->
  ?event_id:Common.Primitives.Pos_int.t list ->
  ?size_threshold:Common.Primitives.Nonneg_float.t ->
  ?redeemable:bool ->
  ?mergeable:bool ->
  ?limit:Common.Primitives.Limit.t ->
  ?offset:Common.Primitives.Offset.t ->
  ?sort_by:position_sort_by ->
  ?sort_direction:sort_direction ->
  ?title:Common.Primitives.Bounded_string.t ->
  unit ->
  (position list, error_response) result
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
  user:Common.Primitives.Address.t ->
  ?market:Common.Primitives.Hash64.t list ->
  ?event_id:Common.Primitives.Pos_int.t list ->
  ?title:Common.Primitives.Bounded_string.t ->
  ?sort_by:closed_position_sort_by ->
  ?sort_direction:sort_direction ->
  ?limit:Common.Primitives.Closed_positions_limit.t ->
  ?offset:Common.Primitives.Extended_offset.t ->
  unit ->
  (closed_position list, error_response) result
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
  ?user:Common.Primitives.Address.t ->
  ?market:Common.Primitives.Hash64.t list ->
  ?event_id:Common.Primitives.Pos_int.t list ->
  ?side:side ->
  ?filter_type:filter_type ->
  ?filter_amount:Common.Primitives.Nonneg_float.t ->
  ?taker_only:bool ->
  ?limit:Common.Primitives.Nonneg_int.t ->
  ?offset:Common.Primitives.Nonneg_int.t ->
  unit ->
  (trade list, error_response) result
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
  user:Common.Primitives.Address.t ->
  ?market:Common.Primitives.Hash64.t list ->
  ?event_id:Common.Primitives.Pos_int.t list ->
  ?activity_types:activity_type list ->
  ?side:side ->
  ?start_time:Common.Primitives.Nonneg_int.t ->
  ?end_time:Common.Primitives.Nonneg_int.t ->
  ?sort_by:activity_sort_by ->
  ?sort_direction:sort_direction ->
  ?limit:Common.Primitives.Limit.t ->
  ?offset:Common.Primitives.Offset.t ->
  unit ->
  (activity list, error_response) result
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
  market:Common.Primitives.Hash64.t list ->
  ?min_balance:Common.Primitives.Min_balance.t ->
  ?limit:Common.Primitives.Holders_limit.t ->
  unit ->
  (meta_holder list, error_response) result
(** Get top holders for markets.
    @param market Condition IDs (required)
    @param min_balance Minimum balance 0-999999 (default: 1)
    @param limit Maximum holders per token 0-20 (default: 20) *)

(** {1 User Data Endpoints} *)

val get_traded :
  t ->
  user:Common.Primitives.Address.t ->
  unit ->
  (traded, error_response) result
(** Get total markets a user has traded.
    @param user User address (required) *)

val get_value :
  t ->
  user:Common.Primitives.Address.t ->
  ?market:Common.Primitives.Hash64.t list ->
  unit ->
  (value list, error_response) result
(** Get total value of a user's positions.
    @param user User address (required)
    @param market Condition IDs to filter by *)

(** {1 Market Data Endpoints} *)

val get_open_interest :
  t ->
  ?market:Common.Primitives.Hash64.t list ->
  unit ->
  (open_interest list, error_response) result
(** Get open interest for markets.
    @param market Condition IDs to filter by *)

val get_live_volume :
  t ->
  id:Common.Primitives.Pos_int.t ->
  unit ->
  (live_volume list, error_response) result
(** Get live volume for an event.
    @param id Event ID >= 1 (required) *)

(** {1 Leaderboard Endpoints} *)

val get_builder_leaderboard :
  t ->
  ?time_period:time_period ->
  ?limit:Common.Primitives.Builder_limit.t ->
  ?offset:Common.Primitives.Leaderboard_offset.t ->
  unit ->
  (leaderboard_entry list, error_response) result
(** Get aggregated builder leaderboard.
    @param time_period Time period to aggregate (default: DAY)
    @param limit Maximum results 0-50 (default: 25)
    @param offset Pagination offset 0-1000 (default: 0) *)

val get_builder_volume :
  t ->
  ?time_period:time_period ->
  unit ->
  (builder_volume_entry list, error_response) result
(** Get daily builder volume time-series.
    @param time_period Time period for daily records (default: DAY) *)

val get_trader_leaderboard :
  t ->
  ?category:leaderboard_category ->
  ?time_period:time_period ->
  ?order_by:leaderboard_order_by ->
  ?user:Common.Primitives.Address.t ->
  ?user_name:string ->
  ?limit:Common.Primitives.Leaderboard_limit.t ->
  ?offset:Common.Primitives.Leaderboard_offset.t ->
  unit ->
  (trader_leaderboard_entry list, error_response) result
(** Get trader leaderboard rankings.
    @param category Market category (default: OVERALL)
    @param time_period Time period (default: DAY)
    @param order_by Ordering criteria (default: PNL)
    @param user Filter to single user by address
    @param user_name Filter to single username
    @param limit Maximum results 1-50 (default: 25)
    @param offset Pagination offset 0-1000 (default: 0) *)
