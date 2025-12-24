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
open Params

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
  user:address ->
  ?market:hash64 list ->
  ?event_id:int list ->
  ?size_threshold:float ->
  ?redeemable:bool ->
  ?mergeable:bool ->
  ?limit:int ->
  ?offset:int ->
  ?sort_by:position_sort_by ->
  ?sort_direction:sort_direction ->
  ?title:string ->
  unit ->
  (position list, error_response) result
(** Get current positions for a user.
    @param user User address (required)
    @param market
      Comma-separated condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs (mutually exclusive with market)
    @param size_threshold Minimum position size (default: 1)
    @param redeemable Filter redeemable positions (default: false)
    @param mergeable Filter mergeable positions (default: false)
    @param limit Maximum results (default: 100, max: 500)
    @param offset Pagination offset (default: 0, max: 10000)
    @param sort_by Sort field (default: TOKENS)
    @param sort_direction Sort direction (default: DESC)
    @param title Filter by title (max 100 chars) *)

val get_closed_positions :
  t ->
  user:address ->
  ?market:hash64 list ->
  ?event_id:int list ->
  ?title:string ->
  ?sort_by:closed_position_sort_by ->
  ?sort_direction:sort_direction ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (closed_position list, error_response) result
(** Get closed positions for a user.
    @param user User address (required)
    @param market Condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs (mutually exclusive with market)
    @param title Filter by title
    @param sort_by Sort field (default: REALIZEDPNL)
    @param sort_direction Sort direction (default: DESC)
    @param limit Maximum results (default: 10, max: 50)
    @param offset Pagination offset (default: 0, max: 100000) *)

(** {1 Trade Endpoints} *)

val get_trades :
  t ->
  ?user:address ->
  ?market:hash64 list ->
  ?event_id:int list ->
  ?side:side ->
  ?filter_type:filter_type ->
  ?filter_amount:float ->
  ?taker_only:bool ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (trade list, error_response) result
(** Get trades for a user or markets.
    @param user User address
    @param market Condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs (mutually exclusive with market)
    @param side Filter by BUY or SELL
    @param filter_type Filter type (must be provided with filter_amount)
    @param filter_amount Filter amount (must be provided with filter_type)
    @param taker_only Only taker trades (default: true)
    @param limit Maximum results (default: 100, max: 10000)
    @param offset Pagination offset (default: 0, max: 10000) *)

(** {1 Activity Endpoint} *)

val get_activity :
  t ->
  user:address ->
  ?market:hash64 list ->
  ?event_id:int list ->
  ?activity_types:activity_type list ->
  ?side:side ->
  ?start_time:int ->
  ?end_time:int ->
  ?sort_by:activity_sort_by ->
  ?sort_direction:sort_direction ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (activity list, error_response) result
(** Get user activity (on-chain).
    @param user User address (required)
    @param market Condition IDs (mutually exclusive with event_id)
    @param event_id Event IDs (mutually exclusive with market)
    @param activity_types Filter by activity types
    @param side Filter by BUY or SELL
    @param start_time Start timestamp
    @param end_time End timestamp
    @param sort_by Sort field (default: TIMESTAMP)
    @param sort_direction Sort direction (default: DESC)
    @param limit Maximum results (default: 100, max: 500)
    @param offset Pagination offset (default: 0, max: 10000) *)

(** {1 Holders Endpoint} *)

val get_holders :
  t ->
  market:hash64 list ->
  ?min_balance:int ->
  ?limit:int ->
  unit ->
  (meta_holder list, error_response) result
(** Get top holders for markets.
    @param market Condition IDs (required)
    @param min_balance Minimum balance (default: 1)
    @param limit Maximum holders per token (default: 20, max: 20) *)

(** {1 User Data Endpoints} *)

val get_traded : t -> user:address -> unit -> (traded, error_response) result
(** Get total markets a user has traded.
    @param user User address (required) *)

val get_value :
  t ->
  user:address ->
  ?market:hash64 list ->
  unit ->
  (value list, error_response) result
(** Get total value of a user's positions.
    @param user User address (required)
    @param market Condition IDs to filter by *)

(** {1 Market Data Endpoints} *)

val get_open_interest :
  t ->
  ?market:hash64 list ->
  unit ->
  (open_interest list, error_response) result
(** Get open interest for markets.
    @param market Condition IDs to filter by *)

val get_live_volume :
  t -> id:int -> unit -> (live_volume list, error_response) result
(** Get live volume for an event.
    @param id Event ID (required) *)

(** {1 Leaderboard Endpoints} *)

val get_builder_leaderboard :
  t ->
  ?time_period:time_period ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (leaderboard_entry list, error_response) result
(** Get aggregated builder leaderboard.
    @param time_period Time period to aggregate (default: DAY)
    @param limit Maximum results (default: 25, max: 50)
    @param offset Pagination offset (default: 0, max: 1000) *)

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
  ?user:address ->
  ?user_name:string ->
  ?limit:int ->
  ?offset:int ->
  unit ->
  (trader_leaderboard_entry list, error_response) result
(** Get trader leaderboard rankings.
    @param category Market category (default: OVERALL)
    @param time_period Time period (default: DAY)
    @param order_by Ordering criteria (default: PNL)
    @param user Filter to single user by address
    @param user_name Filter to single username
    @param limit Maximum results (default: 25, max: 50)
    @param offset Pagination offset (default: 0, max: 1000) *)
