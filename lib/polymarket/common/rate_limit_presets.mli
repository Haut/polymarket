(** Pre-configured rate limit presets for Polymarket APIs.

    Based on official documentation:
    https://docs.polymarket.com/#/api-rate-limits *)

(** {1 General Rate Limits} *)

val general : behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** Global rate limit across all endpoints. *)

(** {1 Data API Rate Limits} *)

val data_api : behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** Rate limits for Data API endpoints. *)

(** {1 Gamma API Rate Limits} *)

val gamma_api : behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** Rate limits for Gamma API endpoints. *)

(** {1 CLOB API Rate Limits} *)

val clob_trading :
  behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** Rate limits for CLOB trading endpoints with burst and sustained limits. *)

val clob_market_data :
  behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** Rate limits for CLOB market data endpoints. *)

val clob_ledger :
  behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** Rate limits for CLOB ledger endpoints. *)

val clob_other :
  behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** Rate limits for CLOB balance and auth endpoints. *)

val clob_api : behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** All CLOB API rate limits combined. *)

(** {1 Combined Presets} *)

val all : behavior:Rate_limiter.behavior -> Rate_limiter.route_config list
(** All rate limit presets combined (Data + Gamma + CLOB + General). *)
