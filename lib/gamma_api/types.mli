(** Gamma API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    gamma-openapi.json for the Polymarket Gamma API
    (https://gamma-api.polymarket.com). *)

(** {1 Simple Types} *)

type pagination = { has_more : bool option; total_results : int option }
(** Pagination information *)

type count = { count : int option }
(** Generic count response *)

type event_tweet_count = { tweet_count : int option }
(** Event tweet count response *)

type market_description = {
  id : string option;
  condition_id : string option;
  market_maker_address : string option;
  description : string option;
}
(** Market description response *)

type image_optimization = {
  id : string option;
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
(** Image optimization data *)

(** {1 Basic Domain Types} *)

type team = {
  id : int option;
  name : string option;
  league : string option;
  record : string option;
  logo : string option;
  abbreviation : string option;
  alias : string option;
  created_at : string option;
  updated_at : string option;
  provider_id : int option;
  color : string option;
}
(** Sports team *)

type tag = {
  id : string option;
  label : string option;
  slug : string option;
  force_show : bool option;
  published_at : string option;
  created_by : int option;
  updated_by : int option;
  created_at : string option;
  updated_at : string option;
  force_hide : bool option;
  is_carousel : bool option;
  requires_translation : bool option;
}
(** Tag for categorization *)

type related_tag = {
  id : string option;
  tag_id : int option;
  related_tag_id : int option;
  rank : int option;
}
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
(** Market category *)

type event_creator = {
  id : string option;
  creator_name : string option;
  creator_handle : string option;
  creator_url : string option;
  creator_image : string option;
  created_at : string option;
  updated_at : string option;
}
(** Event creator *)

type chat = {
  id : string option;
  channel_id : string option;
  channel_name : string option;
  channel_image : string option;
  live : bool option;
  start_time : string option;
  end_time : string option;
}
(** Chat channel *)

type template = {
  id : string option;
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
(** Event template *)

type search_tag = {
  id : string option;
  label : string option;
  slug : string option;
  event_count : int option;
}
(** Search result tag *)

(** {1 Comment Types} *)

type comment_position = {
  token_id : string option;
  position_size : string option;
}
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
(** Comment author profile *)

type reaction = {
  id : string option;
  comment_id : int option;
  reaction_type : string option;
  icon : string option;
  user_address : string option;
  created_at : string option;
  profile : comment_profile option;
}
(** Comment reaction *)

type comment = {
  id : string option;
  body : string option;
  parent_entity_type : string option;
  parent_entity_id : int option;
  parent_comment_id : string option;
  user_address : string option;
  reply_address : string option;
  created_at : string option;
  updated_at : string option;
  profile : comment_profile option;
  reactions : reaction list;
  report_count : int option;
  reaction_count : int option;
}
(** Comment *)

(** {1 Profile Types} *)

type public_profile_user = {
  id : string option;
  creator : bool option;
  mod_ : bool option;
}
(** Public profile user *)

type public_profile_error = { type_ : string option; error : string option }
(** Public profile error response *)

type public_profile_response = {
  created_at : string option;
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
(** Public profile response *)

type profile = {
  id : string option;
  name : string option;
  user : int option;
  referral : string option;
  created_by : int option;
  updated_by : int option;
  created_at : string option;
  updated_at : string option;
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
(** User profile *)

(** {1 Collection Type} *)

type collection = {
  id : string option;
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
  new_ : bool option;
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
(** Collection of events/markets *)

(** {1 Series Summary Type} *)

type series_summary = {
  id : string option;
  title : string option;
  slug : string option;
  event_dates : string list;
  event_weeks : int list;
  earliest_open_week : int option;
  earliest_open_date : string option;
}
(** Series summary *)

(** {1 CLOB Rewards Type} *)

type clob_reward = {
  id : string option;
  condition_id : string option;
  asset_address : string option;
  rewards_amount : float option;
  rewards_daily_rate : float option;
  start_date : string option;
  end_date : string option;
}
(** CLOB reward configuration *)

(** {1 Mutually Recursive Types: Market, Event, Series}

    These types reference each other and must be defined together. *)

type market = {
  id : string option;
  question : string option;
  condition_id : string option;
  slug : string option;
  twitter_card_image : string option;
  resolution_source : string option;
  end_date : string option;
  category : string option;
  amm_type : string option;
  liquidity : string option;
  sponsor_name : string option;
  sponsor_image : string option;
  start_date : string option;
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
  created_at : string option;
  updated_at : string option;
  closed_time : string option;
  wide_format : bool option;
  new_ : bool option;
  mailchimp_tag : string option;
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
  ready_timestamp : string option;
  funded_timestamp : string option;
  accepting_orders_timestamp : string option;
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
  deploying_timestamp : string option;
  scheduled_deployment_timestamp : string option;
  rfq_enabled : bool option;
  event_start_time : string option;
  submitted_by : string option;
  cyom : bool option;
  pager_duty_notification_enabled : bool option;
  approved : bool option;
  holding_rewards_enabled : bool option;
  fees_enabled : bool option;
  requires_translation : bool option;
  neg_risk : bool option;
  neg_risk_market_id : string option;
  neg_risk_request_id : string option;
  clob_rewards : clob_reward list;
  sent_discord : bool option;
  twitter_card_location : string option;
  twitter_card_last_refreshed : string option;
  twitter_card_last_validated : string option;
}
(** Market *)

and event = {
  id : string option;
  ticker : string option;
  slug : string option;
  title : string option;
  subtitle : string option;
  description : string option;
  resolution_source : string option;
  start_date : string option;
  creation_date : string option;
  end_date : string option;
  image : string option;
  icon : string option;
  active : bool option;
  closed : bool option;
  archived : bool option;
  new_ : bool option;
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
  created_at : string option;
  updated_at : string option;
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
  closed_time : string option;
  show_all_outcomes : bool option;
  show_market_images : bool option;
  automatically_resolved : bool option;
  enable_neg_risk : bool option;
  automatically_active : bool option;
  event_date : string option;
  start_time : string option;
  event_week : int option;
  series_slug : string option;
  score : string option;
  elapsed : string option;
  period : string option;
  live : bool option;
  ended : bool option;
  finished_timestamp : string option;
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
  deploying_timestamp : string option;
  scheduled_deployment_timestamp : string option;
  game_status : string option;
  neg_risk_augmented : bool option;
  requires_translation : bool option;
  game_id : string option;
}
(** Event *)

and series = {
  id : string option;
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
  new_ : bool option;
  featured : bool option;
  restricted : bool option;
  is_template : bool option;
  template_variables : bool option;
  published_at : string option;
  created_by : string option;
  updated_by : string option;
  created_at : string option;
  updated_at : string option;
  comments_enabled : bool option;
  competitive : string option;
  volume_24hr : float option;
  volume : float option;
  liquidity : float option;
  start_date : string option;
  pyth_token_id : string option;
  cg_asset_name : string option;
  score : int option;
  events : event list;
  collections : collection list;
  categories : category list;
  tags : tag list;
  comment_count : int option;
  chats : chat list;
  requires_translation : bool option;
}
(** Series *)

(** {1 Pagination Response Types} *)

type events_pagination = { data : event list; pagination : pagination option }
(** Paginated events response *)

type search = {
  events : event list option;
  tags : search_tag list option;
  profiles : profile list option;
  pagination : pagination option;
}
(** Search results *)

(** {1 Sports Types} *)

type sports_metadata = {
  id : int option;
  sport : string option;
  image : string option;
  resolution : string option;
  ordering : string option;
  tags : string option;
  series : string option;
  created_at : string option;
}
(** Sports metadata *)

type sports_market_types_response = { market_types : string list }
(** Sports market types response *)

(** {1 Request Body Types} *)

type markets_information_body = {
  id : int list option;
  slug : string list option;
  closed : bool option;
  clob_token_ids : string list option;
  condition_ids : string list option;
  market_maker_address : string list option;
  liquidity_num_min : float option;
  liquidity_num_max : float option;
  volume_num_min : float option;
  volume_num_max : float option;
  start_date_min : string option;
  start_date_max : string option;
  end_date_min : string option;
  end_date_max : string option;
}
(** Markets information request body *)

(** {1 JSON Conversion Functions} *)

val pagination_of_yojson : Yojson.Safe.t -> pagination
val yojson_of_pagination : pagination -> Yojson.Safe.t
val count_of_yojson : Yojson.Safe.t -> count
val yojson_of_count : count -> Yojson.Safe.t
val event_tweet_count_of_yojson : Yojson.Safe.t -> event_tweet_count
val yojson_of_event_tweet_count : event_tweet_count -> Yojson.Safe.t
val market_description_of_yojson : Yojson.Safe.t -> market_description
val yojson_of_market_description : market_description -> Yojson.Safe.t
val image_optimization_of_yojson : Yojson.Safe.t -> image_optimization
val yojson_of_image_optimization : image_optimization -> Yojson.Safe.t
val team_of_yojson : Yojson.Safe.t -> team
val yojson_of_team : team -> Yojson.Safe.t
val tag_of_yojson : Yojson.Safe.t -> tag
val yojson_of_tag : tag -> Yojson.Safe.t
val related_tag_of_yojson : Yojson.Safe.t -> related_tag
val yojson_of_related_tag : related_tag -> Yojson.Safe.t
val category_of_yojson : Yojson.Safe.t -> category
val yojson_of_category : category -> Yojson.Safe.t
val event_creator_of_yojson : Yojson.Safe.t -> event_creator
val yojson_of_event_creator : event_creator -> Yojson.Safe.t
val chat_of_yojson : Yojson.Safe.t -> chat
val yojson_of_chat : chat -> Yojson.Safe.t
val template_of_yojson : Yojson.Safe.t -> template
val yojson_of_template : template -> Yojson.Safe.t
val search_tag_of_yojson : Yojson.Safe.t -> search_tag
val yojson_of_search_tag : search_tag -> Yojson.Safe.t
val comment_position_of_yojson : Yojson.Safe.t -> comment_position
val yojson_of_comment_position : comment_position -> Yojson.Safe.t
val comment_profile_of_yojson : Yojson.Safe.t -> comment_profile
val yojson_of_comment_profile : comment_profile -> Yojson.Safe.t
val reaction_of_yojson : Yojson.Safe.t -> reaction
val yojson_of_reaction : reaction -> Yojson.Safe.t
val comment_of_yojson : Yojson.Safe.t -> comment
val yojson_of_comment : comment -> Yojson.Safe.t
val public_profile_user_of_yojson : Yojson.Safe.t -> public_profile_user
val yojson_of_public_profile_user : public_profile_user -> Yojson.Safe.t
val public_profile_error_of_yojson : Yojson.Safe.t -> public_profile_error
val yojson_of_public_profile_error : public_profile_error -> Yojson.Safe.t
val public_profile_response_of_yojson : Yojson.Safe.t -> public_profile_response
val yojson_of_public_profile_response : public_profile_response -> Yojson.Safe.t
val profile_of_yojson : Yojson.Safe.t -> profile
val yojson_of_profile : profile -> Yojson.Safe.t
val collection_of_yojson : Yojson.Safe.t -> collection
val yojson_of_collection : collection -> Yojson.Safe.t
val series_summary_of_yojson : Yojson.Safe.t -> series_summary
val yojson_of_series_summary : series_summary -> Yojson.Safe.t
val clob_reward_of_yojson : Yojson.Safe.t -> clob_reward
val yojson_of_clob_reward : clob_reward -> Yojson.Safe.t
val market_of_yojson : Yojson.Safe.t -> market
val yojson_of_market : market -> Yojson.Safe.t
val event_of_yojson : Yojson.Safe.t -> event
val yojson_of_event : event -> Yojson.Safe.t
val series_of_yojson : Yojson.Safe.t -> series
val yojson_of_series : series -> Yojson.Safe.t
val events_pagination_of_yojson : Yojson.Safe.t -> events_pagination
val yojson_of_events_pagination : events_pagination -> Yojson.Safe.t
val search_of_yojson : Yojson.Safe.t -> search
val yojson_of_search : search -> Yojson.Safe.t
val sports_metadata_of_yojson : Yojson.Safe.t -> sports_metadata
val yojson_of_sports_metadata : sports_metadata -> Yojson.Safe.t

val sports_market_types_response_of_yojson :
  Yojson.Safe.t -> sports_market_types_response

val yojson_of_sports_market_types_response :
  sports_market_types_response -> Yojson.Safe.t

val markets_information_body_of_yojson :
  Yojson.Safe.t -> markets_information_body

val yojson_of_markets_information_body :
  markets_information_body -> Yojson.Safe.t

(** {1 Pretty Printing Functions} *)

val pp_pagination : Format.formatter -> pagination -> unit
val show_pagination : pagination -> string
val pp_count : Format.formatter -> count -> unit
val show_count : count -> string
val pp_event_tweet_count : Format.formatter -> event_tweet_count -> unit
val show_event_tweet_count : event_tweet_count -> string
val pp_market_description : Format.formatter -> market_description -> unit
val show_market_description : market_description -> string
val pp_image_optimization : Format.formatter -> image_optimization -> unit
val show_image_optimization : image_optimization -> string
val pp_team : Format.formatter -> team -> unit
val show_team : team -> string
val pp_tag : Format.formatter -> tag -> unit
val show_tag : tag -> string
val pp_related_tag : Format.formatter -> related_tag -> unit
val show_related_tag : related_tag -> string
val pp_category : Format.formatter -> category -> unit
val show_category : category -> string
val pp_event_creator : Format.formatter -> event_creator -> unit
val show_event_creator : event_creator -> string
val pp_chat : Format.formatter -> chat -> unit
val show_chat : chat -> string
val pp_template : Format.formatter -> template -> unit
val show_template : template -> string
val pp_search_tag : Format.formatter -> search_tag -> unit
val show_search_tag : search_tag -> string
val pp_comment_position : Format.formatter -> comment_position -> unit
val show_comment_position : comment_position -> string
val pp_comment_profile : Format.formatter -> comment_profile -> unit
val show_comment_profile : comment_profile -> string
val pp_reaction : Format.formatter -> reaction -> unit
val show_reaction : reaction -> string
val pp_comment : Format.formatter -> comment -> unit
val show_comment : comment -> string
val pp_public_profile_user : Format.formatter -> public_profile_user -> unit
val show_public_profile_user : public_profile_user -> string
val pp_public_profile_error : Format.formatter -> public_profile_error -> unit
val show_public_profile_error : public_profile_error -> string

val pp_public_profile_response :
  Format.formatter -> public_profile_response -> unit

val show_public_profile_response : public_profile_response -> string
val pp_profile : Format.formatter -> profile -> unit
val show_profile : profile -> string
val pp_collection : Format.formatter -> collection -> unit
val show_collection : collection -> string
val pp_series_summary : Format.formatter -> series_summary -> unit
val show_series_summary : series_summary -> string
val pp_clob_reward : Format.formatter -> clob_reward -> unit
val show_clob_reward : clob_reward -> string
val pp_market : Format.formatter -> market -> unit
val show_market : market -> string
val pp_event : Format.formatter -> event -> unit
val show_event : event -> string
val pp_series : Format.formatter -> series -> unit
val show_series : series -> string
val pp_events_pagination : Format.formatter -> events_pagination -> unit
val show_events_pagination : events_pagination -> string
val pp_search : Format.formatter -> search -> unit
val show_search : search -> string
val pp_sports_metadata : Format.formatter -> sports_metadata -> unit
val show_sports_metadata : sports_metadata -> string

val pp_sports_market_types_response :
  Format.formatter -> sports_market_types_response -> unit

val show_sports_market_types_response : sports_market_types_response -> string

val pp_markets_information_body :
  Format.formatter -> markets_information_body -> unit

val show_markets_information_body : markets_information_body -> string

(** {1 Equality Functions} *)

val equal_pagination : pagination -> pagination -> bool
val equal_count : count -> count -> bool
val equal_event_tweet_count : event_tweet_count -> event_tweet_count -> bool
val equal_market_description : market_description -> market_description -> bool
val equal_image_optimization : image_optimization -> image_optimization -> bool
val equal_team : team -> team -> bool
val equal_tag : tag -> tag -> bool
val equal_related_tag : related_tag -> related_tag -> bool
val equal_category : category -> category -> bool
val equal_event_creator : event_creator -> event_creator -> bool
val equal_chat : chat -> chat -> bool
val equal_template : template -> template -> bool
val equal_search_tag : search_tag -> search_tag -> bool
val equal_comment_position : comment_position -> comment_position -> bool
val equal_comment_profile : comment_profile -> comment_profile -> bool
val equal_reaction : reaction -> reaction -> bool
val equal_comment : comment -> comment -> bool

val equal_public_profile_user :
  public_profile_user -> public_profile_user -> bool

val equal_public_profile_error :
  public_profile_error -> public_profile_error -> bool

val equal_public_profile_response :
  public_profile_response -> public_profile_response -> bool

val equal_profile : profile -> profile -> bool
val equal_collection : collection -> collection -> bool
val equal_series_summary : series_summary -> series_summary -> bool
val equal_clob_reward : clob_reward -> clob_reward -> bool
val equal_market : market -> market -> bool
val equal_event : event -> event -> bool
val equal_series : series -> series -> bool
val equal_events_pagination : events_pagination -> events_pagination -> bool
val equal_search : search -> search -> bool
val equal_sports_metadata : sports_metadata -> sports_metadata -> bool

val equal_sports_market_types_response :
  sports_market_types_response -> sports_market_types_response -> bool

val equal_markets_information_body :
  markets_information_body -> markets_information_body -> bool

(** {1 Empty Constructors}

    These provide convenient defaults for testing and creating fixtures. *)

val empty_pagination : pagination
val empty_count : count
val empty_event_tweet_count : event_tweet_count
val empty_market_description : market_description
val empty_image_optimization : image_optimization
val empty_team : team
val empty_tag : tag
val empty_related_tag : related_tag
val empty_category : category
val empty_event_creator : event_creator
val empty_chat : chat
val empty_template : template
val empty_search_tag : search_tag
val empty_comment_position : comment_position
val empty_comment_profile : comment_profile
val empty_reaction : reaction
val empty_comment : comment
val empty_public_profile_user : public_profile_user
val empty_public_profile_error : public_profile_error
val empty_public_profile_response : public_profile_response
val empty_profile : profile
val empty_collection : collection
val empty_series_summary : series_summary
val empty_clob_reward : clob_reward
val empty_market : market
val empty_event : event
val empty_series : series
val empty_events_pagination : events_pagination
val empty_search : search
val empty_sports_metadata : sports_metadata
val empty_sports_market_types_response : sports_market_types_response
val empty_markets_information_body : markets_information_body
