(** Gamma API types for Polymarket.

    These types correspond to the Polymarket Gamma API
    (https://gamma-api.polymarket.com). *)

(** {1 Enum Modules} *)

module Status : sig
  (** Status filter for events and markets *)

  type t =
    | Active  (** Only active/open items *)
    | Closed  (** Only closed/resolved items *)
    | All  (** All items regardless of status *)

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Parent_entity_type : sig
  (** Parent entity type for comments *)

  type t =
    | Event  (** Event entity *)
    | Series  (** Series entity *)
    | Market  (** Market entity *)

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

module Slug_size : sig
  (** Slug size for URL slugs *)

  type t =
    | Sm  (** Small slug *)
    | Md  (** Medium slug *)
    | Lg  (** Large slug *)

  val to_string : t -> string
  val of_string : string -> t
  val of_string_opt : string -> t option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Response Types} *)

type pagination = { has_more : bool; total_results : int }
[@@deriving yojson, show, eq]
(** Pagination information *)

type image_optimization = {
  id : string;
  image_url_source : string option;
  image_url_optimized : string option;
  image_size_kb_source : float option;
  image_size_kb_optimized : float option;
  image_optimized_complete : bool option;
  image_optimized_last_updated : string option;
  rel_id : int option;
  field : string option;
  relname : string option;
}
[@@deriving yojson, show, eq]
(** Image optimization data *)

(** {1 Basic Domain Types} *)

type team = {
  id : int;
  name : string option;
  league : string option;
  record : string option;
  logo : string option;
  abbreviation : string option;
  alias : string option;
  created_at : Common.Primitives.Timestamp.t option;
  updated_at : Common.Primitives.Timestamp.t option;
  provider_id : int option;
  color : string option;
}
[@@deriving yojson, show, eq]
(** Sports team *)

type tag = {
  id : string;
  label : string option;
  slug : string option;
  force_show : bool option;
  published_at : string option;
  created_by : int option;
  updated_by : int option;
  created_at : Common.Primitives.Timestamp.t option;
  updated_at : Common.Primitives.Timestamp.t option;
  force_hide : bool option;
  is_carousel : bool option;
  requires_translation : bool option;
}
[@@deriving yojson, show, eq]
(** Tag for categorization *)

type related_tag = {
  id : string;
  tag_id : int option;
  related_tag_id : int option;
  rank : int option;
}
[@@deriving yojson, show, eq]
(** Related tag relationship *)

type category = {
  id : string option;
  label : string option;
  parent_category : string option;
  slug : string option;
  published_at : string option;
  created_by : string option;
  updated_by : string option;
  created_at : string option;
  updated_at : string option;
}
[@@deriving yojson, show, eq]
(** Market category *)

type event_creator = {
  id : string;
  creator_name : string option;
  creator_handle : string option;
  creator_url : string option;
  creator_image : string option;
  created_at : string option;
  updated_at : string option;
}
[@@deriving yojson, show, eq]
(** Event creator *)

type chat = {
  id : string;
  channel_id : string option;
  channel_name : string option;
  channel_image : string option;
  live : bool option;
  start_time : Common.Primitives.Timestamp.t option;
  end_time : Common.Primitives.Timestamp.t option;
}
[@@deriving yojson, show, eq]
(** Chat channel *)

type template = {
  id : string;
  event_title : string option;
  event_slug : string option;
  event_image : string option;
  market_title : string option;
  description : string option;
  resolution_source : string option;
  neg_risk : bool option;
  sort_by : string option;
  show_market_images : bool option;
  series_slug : string option;
  outcomes : string option;
}
[@@deriving yojson, show, eq]
(** Event template *)

type search_tag = {
  id : string option;
  label : string option;
  slug : string option;
  event_count : int option;
}
[@@deriving yojson, show, eq]
(** Search result tag *)

(** {1 Comment Types} *)

type comment_position = {
  token_id : string option;
  position_size : string option;
}
[@@deriving yojson, show, eq]
(** Position held by a commenter *)

type comment_profile = {
  name : string option;
  pseudonym : string option;
  display_username_public : bool option;
  bio : string option;
  is_mod : bool option;
  is_creator : bool option;
  proxy_wallet : string option;
  base_address : string option;
  profile_image : string option;
  profile_image_optimized : image_optimization option;
  positions : comment_position list;
}
[@@deriving yojson, show, eq]
(** Comment author profile *)

type reaction = {
  id : string;
  comment_id : int option;
  reaction_type : string option;
  icon : string option;
  user_address : string option;
  created_at : string option;
  profile : comment_profile option;
}
[@@deriving yojson, show, eq]
(** Comment reaction *)

type comment = {
  id : string;
  body : string option;
  parent_entity_type : string option;
  parent_entity_id : int option;
  parent_comment_id : string option;
  user_address : string option;
  reply_address : string option;
  created_at : Common.Primitives.Timestamp.t option;
  updated_at : Common.Primitives.Timestamp.t option;
  profile : comment_profile option;
  reactions : reaction list;
  report_count : int option;
  reaction_count : int option;
}
[@@deriving yojson, show, eq]
(** Comment *)

(** {1 Profile Types} *)

type public_profile_user = { id : string; creator : bool; is_mod : bool }
[@@deriving yojson, show, eq]
(** Public profile user *)

type public_profile_response = {
  created_at : Common.Primitives.Timestamp.t option;
  proxy_wallet : string option;
  profile_image : string option;
  display_username_public : bool option;
  bio : string option;
  pseudonym : string option;
  name : string option;
  users : public_profile_user list option;
  x_username : string option;
  verified_badge : bool option;
}
[@@deriving yojson, show, eq]
(** Public profile response *)

type profile = {
  id : string;
  name : string option;
  user : int option;
  referral : string option;
  created_by : int option;
  updated_by : int option;
  created_at : Common.Primitives.Timestamp.t option;
  updated_at : Common.Primitives.Timestamp.t option;
  utm_source : string option;
  utm_medium : string option;
  utm_campaign : string option;
  utm_content : string option;
  utm_term : string option;
  wallet_activated : bool option;
  pseudonym : string option;
  display_username_public : bool option;
  profile_image : string option;
  bio : string option;
  proxy_wallet : string option;
  profile_image_optimized : image_optimization option;
  is_close_only : bool option;
  is_cert_req : bool option;
  cert_req_date : string option;
}
[@@deriving yojson, show, eq]
(** User profile *)

(** {1 Collection Type} *)

type collection = {
  id : string;
  ticker : string option;
  slug : string option;
  title : string option;
  subtitle : string option;
  collection_type : string option;
  description : string option;
  tags : string option;
  image : string option;
  icon : string option;
  header_image : string option;
  layout : string option;
  active : bool option;
  closed : bool option;
  archived : bool option;
  is_new : bool option;
  featured : bool option;
  restricted : bool option;
  is_template : bool option;
  template_variables : string option;
  published_at : string option;
  created_by : string option;
  updated_by : string option;
  created_at : string option;
  updated_at : string option;
  comments_enabled : bool option;
  image_optimized : image_optimization option;
  icon_optimized : image_optimization option;
  header_image_optimized : image_optimization option;
}
[@@deriving yojson, show, eq]
(** Collection of events/markets *)

type clob_reward = {
  id : string option;
  condition_id : string option;
  asset_address : string option;
  rewards_amount : float option;
  rewards_daily_rate : float option;
  start_date : string option;
  end_date : string option;
}
[@@deriving yojson, show, eq]
(** CLOB rewards configuration for a market *)

(** {1 Mutually Recursive Types: Market, Event, Series} *)

type market = {
  id : string;
  question : string option;
  condition_id : string option;
  slug : string option;
  twitter_card_image : string option;
  resolution_source : string option;
  end_date : Common.Primitives.Timestamp.t option;
  category : string option;
  amm_type : string option;
  liquidity : string option;
  sponsor_name : string option;
  sponsor_image : string option;
  start_date : Common.Primitives.Timestamp.t option;
  x_axis_value : string option;
  y_axis_value : string option;
  denomination_token : string option;
  fee : string option;
  image : string option;
  icon : string option;
  lower_bound : string option;
  upper_bound : string option;
  description : string option;
  outcomes : string option;
  outcome_prices : string option;
  volume : string option;
  active : bool option;
  market_type : string option;
  format_type : string option;
  lower_bound_date : string option;
  upper_bound_date : string option;
  closed : bool option;
  market_maker_address : string option;
  created_by : int option;
  updated_by : int option;
  created_at : Common.Primitives.Timestamp.t option;
  updated_at : Common.Primitives.Timestamp.t option;
  closed_time : string option;
  wide_format : bool option;
  is_new : bool option;
  mailchimp_tag : string option;
  category_mailchimp_tag : string option;
  sent_discord : bool option;
  featured : bool option;
  archived : bool option;
  resolved_by : string option;
  restricted : bool option;
  market_group : int option;
  group_item_title : string option;
  group_item_threshold : string option;
  question_id : string option;
  uma_end_date : string option;
  enable_order_book : bool option;
  order_price_min_tick_size : float option;
  order_min_size : float option;
  uma_resolution_status : string option;
  curation_order : int option;
  volume_num : float option;
  liquidity_num : float option;
  end_date_iso : string option;
  start_date_iso : string option;
  uma_end_date_iso : string option;
  has_reviewed_dates : bool option;
  ready_for_cron : bool option;
  comments_enabled : bool option;
  volume_24hr : float option;
  volume_1wk : float option;
  volume_1mo : float option;
  volume_1yr : float option;
  game_start_time : string option;
  seconds_delay : int option;
  clob_token_ids : string option;
  disqus_thread : string option;
  short_outcomes : string option;
  team_a_id : string option;
  team_b_id : string option;
  uma_bond : string option;
  uma_reward : string option;
  fpmm_live : bool option;
  volume_24hr_amm : float option;
  volume_1wk_amm : float option;
  volume_1mo_amm : float option;
  volume_1yr_amm : float option;
  volume_24hr_clob : float option;
  volume_1wk_clob : float option;
  volume_1mo_clob : float option;
  volume_1yr_clob : float option;
  volume_amm : float option;
  volume_clob : float option;
  liquidity_amm : float option;
  liquidity_clob : float option;
  maker_base_fee : int option;
  taker_base_fee : int option;
  custom_liveness : int option;
  accepting_orders : bool option;
  notifications_enabled : bool option;
  score : int option;
  image_optimized : image_optimization option;
  icon_optimized : image_optimization option;
  events : event list;
  categories : category list;
  tags : tag list;
  creator : string option;
  ready : bool option;
  funded : bool option;
  past_slugs : string option;
  ready_timestamp : Common.Primitives.Timestamp.t option;
  funded_timestamp : Common.Primitives.Timestamp.t option;
  accepting_orders_timestamp : Common.Primitives.Timestamp.t option;
  competitive : float option;
  rewards_min_size : float option;
  rewards_max_spread : float option;
  spread : float option;
  automatically_resolved : bool option;
  one_day_price_change : float option;
  one_hour_price_change : float option;
  one_week_price_change : float option;
  one_month_price_change : float option;
  one_year_price_change : float option;
  last_trade_price : float option;
  best_bid : float option;
  best_ask : float option;
  automatically_active : bool option;
  clear_book_on_start : bool option;
  chart_color : string option;
  series_color : string option;
  show_gmp_series : bool option;
  show_gmp_outcome : bool option;
  manual_activation : bool option;
  neg_risk_other : bool option;
  game_id : string option;
  group_item_range : string option;
  sports_market_type : string option;
  line : float option;
  uma_resolution_statuses : string option;
  pending_deployment : bool option;
  deploying : bool option;
  deploying_timestamp : Common.Primitives.Timestamp.t option;
  scheduled_deployment_timestamp : Common.Primitives.Timestamp.t option;
  rfq_enabled : bool option;
  event_start_time : Common.Primitives.Timestamp.t option;
  cyom : bool option;
  pager_duty_notification_enabled : bool option;
  approved : bool option;
  holding_rewards_enabled : bool option;
  fees_enabled : bool option;
  requires_translation : bool option;
  submitted_by : string option;
  neg_risk : bool option;
  neg_risk_market_id : string option;
  neg_risk_request_id : string option;
  clob_rewards : clob_reward list;
}
[@@deriving yojson, show, eq]
(** Market *)

and event = {
  id : string;
  ticker : string option;
  slug : string option;
  title : string option;
  subtitle : string option;
  description : string option;
  resolution_source : string option;
  start_date : Common.Primitives.Timestamp.t option;
  creation_date : Common.Primitives.Timestamp.t option;
  end_date : Common.Primitives.Timestamp.t option;
  image : string option;
  icon : string option;
  active : bool option;
  closed : bool option;
  archived : bool option;
  is_new : bool option;
  featured : bool option;
  restricted : bool option;
  liquidity : float option;
  volume : float option;
  open_interest : float option;
  sort_by : string option;
  category : string option;
  subcategory : string option;
  is_template : bool option;
  template_variables : string option;
  published_at : string option;
  created_by : string option;
  updated_by : string option;
  created_at : Common.Primitives.Timestamp.t option;
  updated_at : Common.Primitives.Timestamp.t option;
  comments_enabled : bool option;
  competitive : float option;
  volume_24hr : float option;
  volume_1wk : float option;
  volume_1mo : float option;
  volume_1yr : float option;
  featured_image : string option;
  disqus_thread : string option;
  parent_event : string option;
  enable_order_book : bool option;
  liquidity_amm : float option;
  liquidity_clob : float option;
  neg_risk : bool option;
  neg_risk_market_id : string option;
  neg_risk_fee_bips : int option;
  comment_count : int option;
  image_optimized : image_optimization option;
  icon_optimized : image_optimization option;
  featured_image_optimized : image_optimization option;
  sub_events : string list option;
  markets : market list;
  series : series list;
  categories : category list;
  collections : collection list;
  tags : tag list;
  cyom : bool option;
  closed_time : Common.Primitives.Timestamp.t option;
  show_all_outcomes : bool option;
  show_market_images : bool option;
  automatically_resolved : bool option;
  enable_neg_risk : bool option;
  automatically_active : bool option;
  event_date : string option;
  start_time : Common.Primitives.Timestamp.t option;
  event_week : int option;
  series_slug : string option;
  score : string option;
  elapsed : string option;
  period : string option;
  live : bool option;
  ended : bool option;
  finished_timestamp : Common.Primitives.Timestamp.t option;
  gmp_chart_mode : string option;
  event_creators : event_creator list;
  tweet_count : int option;
  chats : chat list;
  featured_order : int option;
  estimate_value : bool option;
  cant_estimate : bool option;
  estimated_value : string option;
  templates : template list;
  spreads_main_line : float option;
  totals_main_line : float option;
  carousel_map : string option;
  pending_deployment : bool option;
  deploying : bool option;
  deploying_timestamp : Common.Primitives.Timestamp.t option;
  scheduled_deployment_timestamp : Common.Primitives.Timestamp.t option;
  game_status : string option;
  neg_risk_augmented : bool option;
  requires_translation : bool option;
  cumulative_markets : bool option;
  country_name : string option;
  election_type : string option;
}
[@@deriving yojson, show, eq]
(** Event *)

and series = {
  id : string;
  ticker : string option;
  slug : string option;
  title : string option;
  subtitle : string option;
  series_type : string option;
  recurrence : string option;
  description : string option;
  image : string option;
  icon : string option;
  layout : string option;
  active : bool option;
  closed : bool option;
  archived : bool option;
  is_new : bool option;
  featured : bool option;
  restricted : bool option;
  is_template : bool option;
  template_variables : bool option;
  published_at : string option;
  created_by : string option;
  updated_by : string option;
  created_at : Common.Primitives.Timestamp.t option;
  updated_at : Common.Primitives.Timestamp.t option;
  comments_enabled : bool option;
  competitive : string option;
  volume_24hr : float option;
  volume : float option;
  liquidity : float option;
  start_date : Common.Primitives.Timestamp.t option;
  pyth_token_id : string option;
  cg_asset_name : string option;
  score : int option;
  events : event list;
  collections : collection list;
  categories : category list;
  tags : tag list;
  comment_count : int option;
  requires_translation : bool option;
  chats : chat list;
}
[@@deriving yojson, show, eq]
(** Series *)

(** {1 Pagination Response Types} *)

type events_pagination = { data : event list; pagination : pagination option }
[@@deriving yojson, show, eq]
(** Paginated events response *)

type search = {
  events : event list option;
  tags : search_tag list option;
  profiles : profile list option;
  pagination : pagination option;
}
[@@deriving yojson, show, eq]
(** Search results *)

(** {1 Sports Types} *)

type sports_metadata = {
  id : int option;
  sport : string;
  image : string option;
  resolution : string option;
  ordering : string;
  tags : string;
  series : string;
  created_at : string option;
}
[@@deriving yojson, show, eq]
(** Sports metadata *)

type sports_market_types_response = { market_types : string list }
[@@deriving yojson, show, eq]
(** Sports market types response *)

(** {1 Field Lists for Extra Field Detection} *)

val yojson_fields_of_pagination : string list
val yojson_fields_of_image_optimization : string list
val yojson_fields_of_team : string list
val yojson_fields_of_tag : string list
val yojson_fields_of_related_tag : string list
val yojson_fields_of_category : string list
val yojson_fields_of_event_creator : string list
val yojson_fields_of_chat : string list
val yojson_fields_of_template : string list
val yojson_fields_of_search_tag : string list
val yojson_fields_of_comment_position : string list
val yojson_fields_of_comment_profile : string list
val yojson_fields_of_reaction : string list
val yojson_fields_of_comment : string list
val yojson_fields_of_public_profile_user : string list
val yojson_fields_of_public_profile_response : string list
val yojson_fields_of_profile : string list
val yojson_fields_of_collection : string list
val yojson_fields_of_market : string list
val yojson_fields_of_event : string list
val yojson_fields_of_series : string list
val yojson_fields_of_events_pagination : string list
val yojson_fields_of_search : string list
val yojson_fields_of_sports_metadata : string list
val yojson_fields_of_sports_market_types_response : string list

(** {1 Error Types} *)

type error = Polymarket_http.Client.error
(** Structured error type for all API errors. *)

val error_to_string : error -> string
(** Convert error to human-readable string *)
