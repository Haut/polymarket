(** Gamma API types for Polymarket.

    These types correspond to the Polymarket Gamma API
    (https://gamma-api.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Enum Modules} *)

(** Status filter for events and markets *)
module Status = struct
  type t =
    | Active [@value "active"]  (** Only active/open items *)
    | Closed [@value "closed"]  (** Only closed/resolved items *)
    | All [@value "all"]  (** All items regardless of status *)
  [@@deriving enum]
end

(** Parent entity type for comments *)
module Parent_entity_type = struct
  type t =
    | Event [@value "Event"]  (** Event entity *)
    | Series [@value "Series"]  (** Series entity *)
    | Market [@value "market"]  (** Market entity *)
  [@@deriving enum]
end

(** Slug size for URL slugs *)
module Slug_size = struct
  type t =
    | Sm [@value "sm"]  (** Small slug *)
    | Md [@value "md"]  (** Medium slug *)
    | Lg [@value "lg"]  (** Large slug *)
  [@@deriving enum]
end

(** {1 Response Types} *)

type pagination = {
  has_more : bool; [@key "hasMore"]
  total_results : int; [@key "totalResults"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Pagination information *)

type image_optimization = {
  id : string;
  image_url_source : string option; [@default None] [@key "imageUrlSource"]
  image_url_optimized : string option;
      [@default None] [@key "imageUrlOptimized"]
  image_size_kb_source : float option;
      [@default None] [@key "imageSizeKbSource"]
  image_size_kb_optimized : float option;
      [@default None] [@key "imageSizeKbOptimized"]
  image_optimized_complete : bool option;
      [@default None] [@key "imageOptimizedComplete"]
  image_optimized_last_updated : string option;
      [@default None] [@key "imageOptimizedLastUpdated"]
  rel_id : int option; [@default None] [@key "relID"]
  field : string option; [@default None]
  relname : string option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Image optimization data *)

(** {1 Basic Domain Types} *)

type team = {
  id : int;
  name : string option; [@default None]
  league : string option; [@default None]
  record : string option; [@default None]
  logo : string option; [@default None]
  abbreviation : string option; [@default None]
  alias : string option; [@default None]
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "updatedAt"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Sports team *)

type tag = {
  id : string;
  label : string option; [@default None]
  slug : string option; [@default None]
  force_show : bool option; [@default None] [@key "forceShow"]
  published_at : string option; [@default None] [@key "publishedAt"]
  created_by : int option; [@default None] [@key "createdBy"]
  updated_by : int option; [@default None] [@key "updatedBy"]
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "updatedAt"]
  force_hide : bool option; [@default None] [@key "forceHide"]
  is_carousel : bool option; [@default None] [@key "isCarousel"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Tag for categorization *)

type related_tag = {
  id : string;
  tag_id : int option; [@default None] [@key "tagID"]
  related_tag_id : int option; [@default None] [@key "relatedTagID"]
  rank : int option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Related tag relationship *)

type category = {
  id : string option; [@default None]
  label : string option; [@default None]
  parent_category : string option; [@default None] [@key "parentCategory"]
  slug : string option; [@default None]
  published_at : string option; [@default None] [@key "publishedAt"]
  created_by : string option; [@default None] [@key "createdBy"]
  updated_by : string option; [@default None] [@key "updatedBy"]
  created_at : string option; [@default None] [@key "createdAt"]
  updated_at : string option; [@default None] [@key "updatedAt"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Market category *)

type event_creator = {
  id : string;
  creator_name : string option; [@default None]
  creator_handle : string option; [@default None] [@key "creatorHandle"]
  creator_url : string option; [@default None] [@key "creatorUrl"]
  creator_image : string option; [@default None] [@key "creatorImage"]
  created_at : string option; [@default None] [@key "createdAt"]
  updated_at : string option; [@default None] [@key "updatedAt"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Event creator *)

type chat = {
  id : string;
  channel_id : string option; [@default None] [@key "channelID"]
  channel_name : string option; [@default None] [@key "channelName"]
  channel_image : string option; [@default None] [@key "channelImage"]
  live : bool option; [@default None]
  start_time : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "startTime"]
  end_time : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "endTime"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Chat channel *)

type template = {
  id : string;
  event_title : string option; [@default None] [@key "eventTitle"]
  event_slug : string option; [@default None] [@key "eventSlug"]
  event_image : string option; [@default None] [@key "eventImage"]
  market_title : string option; [@default None] [@key "marketTitle"]
  description : string option; [@default None]
  resolution_source : string option; [@default None] [@key "resolutionSource"]
  neg_risk : bool option; [@default None] [@key "negRisk"]
  sort_by : string option; [@default None] [@key "sortBy"]
  show_market_images : bool option; [@default None] [@key "showMarketImages"]
  series_slug : string option; [@default None] [@key "seriesSlug"]
  outcomes : string option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Event template *)

type search_tag = {
  id : string option; [@default None]
  label : string option; [@default None]
  slug : string option; [@default None]
  event_count : int option; [@default None] [@key "event_count"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Search result tag *)

(** {1 Comment Types} *)

type comment_position = {
  token_id : string option; [@default None] [@key "tokenId"]
  position_size : string option; [@default None] [@key "positionSize"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Position held by a commenter *)

type comment_profile = {
  name : string option; [@default None]
  pseudonym : string option; [@default None]
  display_username_public : bool option;
      [@default None] [@key "displayUsernamePublic"]
  bio : string option; [@default None]
  is_mod : bool option; [@default None] [@key "isMod"]
  is_creator : bool option; [@default None] [@key "isCreator"]
  proxy_wallet : string option; [@default None] [@key "proxyWallet"]
  base_address : string option; [@default None] [@key "baseAddress"]
  profile_image : string option; [@default None] [@key "profileImage"]
  profile_image_optimized : image_optimization option;
      [@default None] [@key "profileImageOptimized"]
  positions : comment_position list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Comment author profile *)

type reaction = {
  id : string;
  comment_id : int option; [@default None] [@key "commentID"]
  reaction_type : string option; [@default None] [@key "reactionType"]
  icon : string option; [@default None]
  user_address : string option; [@default None] [@key "userAddress"]
  created_at : string option; [@default None] [@key "createdAt"]
  profile : comment_profile option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Comment reaction *)

type comment = {
  id : string;
  body : string option; [@default None]
  parent_entity_type : string option; [@default None] [@key "parentEntityType"]
  parent_entity_id : int option; [@default None] [@key "parentEntityID"]
  parent_comment_id : string option; [@default None] [@key "parentCommentID"]
  user_address : string option; [@default None] [@key "userAddress"]
  reply_address : string option; [@default None] [@key "replyAddress"]
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "updatedAt"]
  profile : comment_profile option; [@default None]
  reactions : reaction list; [@default []]
  report_count : int option; [@default None] [@key "reportCount"]
  reaction_count : int option; [@default None] [@key "reactionCount"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Comment *)

(** {1 Profile Types} *)

type public_profile_user = {
  id : string;
  creator : bool;
  is_mod : bool; [@key "mod"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Public profile user *)

type public_profile_response = {
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  proxy_wallet : string option; [@default None] [@key "proxyWallet"]
  profile_image : string option; [@default None] [@key "profileImage"]
  display_username_public : bool option;
      [@default None] [@key "displayUsernamePublic"]
  bio : string option; [@default None]
  pseudonym : string option; [@default None]
  name : string option; [@default None]
  users : public_profile_user list option; [@default None]
  x_username : string option; [@default None] [@key "xUsername"]
  verified_badge : bool option; [@default None] [@key "verifiedBadge"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Public profile response *)

type profile = {
  id : string;
  name : string option; [@default None]
  user : int option; [@default None]
  referral : string option; [@default None]
  created_by : int option; [@default None] [@key "createdBy"]
  updated_by : int option; [@default None] [@key "updatedBy"]
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "updatedAt"]
  utm_source : string option; [@default None] [@key "utmSource"]
  utm_medium : string option; [@default None] [@key "utmMedium"]
  utm_campaign : string option; [@default None] [@key "utmCampaign"]
  utm_content : string option; [@default None] [@key "utmContent"]
  utm_term : string option; [@default None] [@key "utmTerm"]
  wallet_activated : bool option; [@default None] [@key "walletActivated"]
  pseudonym : string option; [@default None]
  display_username_public : bool option;
      [@default None] [@key "displayUsernamePublic"]
  profile_image : string option; [@default None] [@key "profileImage"]
  bio : string option; [@default None]
  proxy_wallet : string option; [@default None] [@key "proxyWallet"]
  profile_image_optimized : image_optimization option;
      [@default None] [@key "profileImageOptimized"]
  is_close_only : bool option; [@default None] [@key "isCloseOnly"]
  is_cert_req : bool option; [@default None] [@key "isCertReq"]
  cert_req_date : string option; [@default None] [@key "certReqDate"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** User profile *)

(** {1 Collection Type} *)

type collection = {
  id : string;
  ticker : string option; [@default None]
  slug : string option; [@default None]
  title : string option; [@default None]
  subtitle : string option; [@default None]
  collection_type : string option; [@default None] [@key "collectionType"]
  description : string option; [@default None]
  tags : string option; [@default None]
  image : string option; [@default None]
  icon : string option; [@default None]
  header_image : string option; [@default None] [@key "headerImage"]
  layout : string option; [@default None]
  active : bool option; [@default None]
  closed : bool option; [@default None]
  archived : bool option; [@default None]
  is_new : bool option; [@default None]
  featured : bool option; [@default None]
  restricted : bool option; [@default None]
  is_template : bool option; [@default None] [@key "isTemplate"]
  template_variables : string option; [@default None] [@key "templateVariables"]
  published_at : string option; [@default None] [@key "publishedAt"]
  created_by : string option; [@default None] [@key "createdBy"]
  updated_by : string option; [@default None] [@key "updatedBy"]
  created_at : string option; [@default None] [@key "createdAt"]
  updated_at : string option; [@default None] [@key "updatedAt"]
  comments_enabled : bool option; [@default None] [@key "commentsEnabled"]
  image_optimized : image_optimization option;
      [@default None] [@key "imageOptimized"]
  icon_optimized : image_optimization option;
      [@default None] [@key "iconOptimized"]
  header_image_optimized : image_optimization option;
      [@default None] [@key "headerImageOptimized"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Collection of events/markets *)

(** {1 Mutually Recursive Types: Market, Event, Series}

    These types reference each other and must be defined together. *)

type market = {
  id : string;
  question : string option; [@default None]
  condition_id : string option; [@default None] [@key "conditionId"]
  slug : string option; [@default None]
  twitter_card_image : string option; [@default None] [@key "twitterCardImage"]
  resolution_source : string option; [@default None] [@key "resolutionSource"]
  end_date : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "endDate"]
  category : string option; [@default None]
  amm_type : string option; [@default None] [@key "ammType"]
  liquidity : string option; [@default None]
  sponsor_name : string option; [@default None] [@key "sponsorName"]
  sponsor_image : string option; [@default None] [@key "sponsorImage"]
  start_date : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "startDate"]
  x_axis_value : string option; [@default None] [@key "xAxisValue"]
  y_axis_value : string option; [@default None] [@key "yAxisValue"]
  denomination_token : string option; [@default None] [@key "denominationToken"]
  fee : string option; [@default None]
  image : string option; [@default None]
  icon : string option; [@default None]
  lower_bound : string option; [@default None] [@key "lowerBound"]
  upper_bound : string option; [@default None] [@key "upperBound"]
  description : string option; [@default None]
  outcomes : string option; [@default None]
  outcome_prices : string option; [@default None] [@key "outcomePrices"]
  volume : string option; [@default None]
  active : bool option; [@default None]
  market_type : string option; [@default None] [@key "marketType"]
  format_type : string option; [@default None] [@key "formatType"]
  lower_bound_date : string option; [@default None] [@key "lowerBoundDate"]
  upper_bound_date : string option; [@default None] [@key "upperBoundDate"]
  closed : bool option; [@default None]
  market_maker_address : string option;
      [@default None] [@key "marketMakerAddress"]
  created_by : int option; [@default None] [@key "createdBy"]
  updated_by : int option; [@default None] [@key "updatedBy"]
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "updatedAt"]
  closed_time : string option; [@default None] [@key "closedTime"]
  wide_format : bool option; [@default None] [@key "wideFormat"]
  is_new : bool option; [@default None] [@key "new"]
  mailchimp_tag : string option; [@default None] [@key "mailchimpTag"]
  featured : bool option; [@default None]
  archived : bool option; [@default None]
  resolved_by : string option; [@default None] [@key "resolvedBy"]
  restricted : bool option; [@default None]
  market_group : int option; [@default None] [@key "marketGroup"]
  group_item_title : string option; [@default None] [@key "groupItemTitle"]
  group_item_threshold : string option;
      [@default None] [@key "groupItemThreshold"]
  question_id : string option; [@default None] [@key "questionID"]
  uma_end_date : string option; [@default None] [@key "umaEndDate"]
  enable_order_book : bool option; [@default None] [@key "enableOrderBook"]
  order_price_min_tick_size : float option;
      [@default None] [@key "orderPriceMinTickSize"]
  order_min_size : float option; [@default None] [@key "orderMinSize"]
  uma_resolution_status : string option;
      [@default None] [@key "umaResolutionStatus"]
  curation_order : int option; [@default None] [@key "curationOrder"]
  volume_num : float option; [@default None] [@key "volumeNum"]
  liquidity_num : float option; [@default None] [@key "liquidityNum"]
  end_date_iso : string option; [@default None] [@key "endDateIso"]
  start_date_iso : string option; [@default None] [@key "startDateIso"]
  uma_end_date_iso : string option; [@default None] [@key "umaEndDateIso"]
  has_reviewed_dates : bool option; [@default None] [@key "hasReviewedDates"]
  ready_for_cron : bool option; [@default None] [@key "readyForCron"]
  comments_enabled : bool option; [@default None] [@key "commentsEnabled"]
  volume_24hr : float option; [@default None] [@key "volume24hr"]
  volume_1wk : float option; [@default None] [@key "volume1wk"]
  volume_1mo : float option; [@default None] [@key "volume1mo"]
  volume_1yr : float option; [@default None] [@key "volume1yr"]
  game_start_time : string option; [@default None] [@key "gameStartTime"]
  seconds_delay : int option; [@default None] [@key "secondsDelay"]
  clob_token_ids : string option; [@default None] [@key "clobTokenIds"]
  disqus_thread : string option; [@default None] [@key "disqusThread"]
  short_outcomes : string option; [@default None] [@key "shortOutcomes"]
  team_a_id : string option; [@default None] [@key "teamAID"]
  team_b_id : string option; [@default None] [@key "teamBID"]
  uma_bond : string option; [@default None] [@key "umaBond"]
  uma_reward : string option; [@default None] [@key "umaReward"]
  fpmm_live : bool option; [@default None] [@key "fpmmLive"]
  volume_24hr_amm : float option; [@default None] [@key "volume24hrAmm"]
  volume_1wk_amm : float option; [@default None] [@key "volume1wkAmm"]
  volume_1mo_amm : float option; [@default None] [@key "volume1moAmm"]
  volume_1yr_amm : float option; [@default None] [@key "volume1yrAmm"]
  volume_24hr_clob : float option; [@default None] [@key "volume24hrClob"]
  volume_1wk_clob : float option; [@default None] [@key "volume1wkClob"]
  volume_1mo_clob : float option; [@default None] [@key "volume1moClob"]
  volume_1yr_clob : float option; [@default None] [@key "volume1yrClob"]
  volume_amm : float option; [@default None] [@key "volumeAmm"]
  volume_clob : float option; [@default None] [@key "volumeClob"]
  liquidity_amm : float option; [@default None] [@key "liquidityAmm"]
  liquidity_clob : float option; [@default None] [@key "liquidityClob"]
  maker_base_fee : int option; [@default None] [@key "makerBaseFee"]
  taker_base_fee : int option; [@default None] [@key "takerBaseFee"]
  custom_liveness : int option; [@default None] [@key "customLiveness"]
  accepting_orders : bool option; [@default None] [@key "acceptingOrders"]
  notifications_enabled : bool option;
      [@default None] [@key "notificationsEnabled"]
  score : int option; [@default None]
  image_optimized : image_optimization option;
      [@default None] [@key "imageOptimized"]
  icon_optimized : image_optimization option;
      [@default None] [@key "iconOptimized"]
  events : event list; [@default []]
  categories : category list; [@default []]
  tags : tag list; [@default []]
  creator : string option; [@default None]
  ready : bool option; [@default None]
  funded : bool option; [@default None]
  past_slugs : string option; [@default None] [@key "pastSlugs"]
  ready_timestamp : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "readyTimestamp"]
  funded_timestamp : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "fundedTimestamp"]
  accepting_orders_timestamp : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "acceptingOrdersTimestamp"]
  competitive : float option; [@default None]
  rewards_min_size : float option; [@default None] [@key "rewardsMinSize"]
  rewards_max_spread : float option; [@default None] [@key "rewardsMaxSpread"]
  spread : float option; [@default None]
  automatically_resolved : bool option;
      [@default None] [@key "automaticallyResolved"]
  one_day_price_change : float option;
      [@default None] [@key "oneDayPriceChange"]
  one_hour_price_change : float option;
      [@default None] [@key "oneHourPriceChange"]
  one_week_price_change : float option;
      [@default None] [@key "oneWeekPriceChange"]
  one_month_price_change : float option;
      [@default None] [@key "oneMonthPriceChange"]
  one_year_price_change : float option;
      [@default None] [@key "oneYearPriceChange"]
  last_trade_price : float option; [@default None] [@key "lastTradePrice"]
  best_bid : float option; [@default None] [@key "bestBid"]
  best_ask : float option; [@default None] [@key "bestAsk"]
  automatically_active : bool option;
      [@default None] [@key "automaticallyActive"]
  clear_book_on_start : bool option; [@default None] [@key "clearBookOnStart"]
  chart_color : string option; [@default None] [@key "chartColor"]
  series_color : string option; [@default None] [@key "seriesColor"]
  show_gmp_series : bool option; [@default None] [@key "showGmpSeries"]
  show_gmp_outcome : bool option; [@default None] [@key "showGmpOutcome"]
  manual_activation : bool option; [@default None] [@key "manualActivation"]
  neg_risk_other : bool option; [@default None] [@key "negRiskOther"]
  game_id : string option; [@default None] [@key "gameId"]
  group_item_range : string option; [@default None] [@key "groupItemRange"]
  sports_market_type : string option; [@default None] [@key "sportsMarketType"]
  line : float option; [@default None]
  uma_resolution_statuses : string option;
      [@default None] [@key "umaResolutionStatuses"]
  pending_deployment : bool option; [@default None] [@key "pendingDeployment"]
  deploying : bool option; [@default None]
  deploying_timestamp : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "deployingTimestamp"]
  scheduled_deployment_timestamp :
    Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "scheduledDeploymentTimestamp"]
  rfq_enabled : bool option; [@default None] [@key "rfqEnabled"]
  event_start_time : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "eventStartTime"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]

and event = {
  id : string;
  ticker : string option; [@default None]
  slug : string option; [@default None]
  title : string option; [@default None]
  subtitle : string option; [@default None]
  description : string option; [@default None]
  resolution_source : string option; [@default None] [@key "resolutionSource"]
  start_date : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "startDate"]
  creation_date : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "creationDate"]
  end_date : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "endDate"]
  image : string option; [@default None]
  icon : string option; [@default None]
  active : bool option; [@default None]
  closed : bool option; [@default None]
  archived : bool option; [@default None]
  is_new : bool option; [@default None] [@key "new"]
  featured : bool option; [@default None]
  restricted : bool option; [@default None]
  liquidity : float option; [@default None]
  volume : float option; [@default None]
  open_interest : float option; [@default None] [@key "openInterest"]
  sort_by : string option; [@default None] [@key "sortBy"]
  category : string option; [@default None]
  subcategory : string option; [@default None]
  is_template : bool option; [@default None] [@key "isTemplate"]
  template_variables : string option; [@default None] [@key "templateVariables"]
  published_at : string option; [@default None] [@key "published_at"]
  created_by : string option; [@default None] [@key "createdBy"]
  updated_by : string option; [@default None] [@key "updatedBy"]
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "updatedAt"]
  comments_enabled : bool option; [@default None] [@key "commentsEnabled"]
  competitive : float option; [@default None]
  volume_24hr : float option; [@default None] [@key "volume24hr"]
  volume_1wk : float option; [@default None] [@key "volume1wk"]
  volume_1mo : float option; [@default None] [@key "volume1mo"]
  volume_1yr : float option; [@default None] [@key "volume1yr"]
  featured_image : string option; [@default None] [@key "featuredImage"]
  disqus_thread : string option; [@default None] [@key "disqusThread"]
  parent_event : string option; [@default None] [@key "parentEvent"]
  enable_order_book : bool option; [@default None] [@key "enableOrderBook"]
  liquidity_amm : float option; [@default None] [@key "liquidityAmm"]
  liquidity_clob : float option; [@default None] [@key "liquidityClob"]
  neg_risk : bool option; [@default None] [@key "negRisk"]
  neg_risk_market_id : string option; [@default None] [@key "negRiskMarketID"]
  neg_risk_fee_bips : int option; [@default None] [@key "negRiskFeeBips"]
  comment_count : int option; [@default None] [@key "commentCount"]
  image_optimized : image_optimization option;
      [@default None] [@key "imageOptimized"]
  icon_optimized : image_optimization option;
      [@default None] [@key "iconOptimized"]
  featured_image_optimized : image_optimization option;
      [@default None] [@key "featuredImageOptimized"]
  sub_events : string list option; [@default None] [@key "subEvents"]
  markets : market list; [@default []]
  series : series list; [@default []]
  categories : category list; [@default []]
  collections : collection list; [@default []]
  tags : tag list; [@default []]
  cyom : bool option; [@default None]
  closed_time : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "closedTime"]
  show_all_outcomes : bool option; [@default None] [@key "showAllOutcomes"]
  show_market_images : bool option; [@default None] [@key "showMarketImages"]
  automatically_resolved : bool option;
      [@default None] [@key "automaticallyResolved"]
  enable_neg_risk : bool option; [@default None] [@key "enableNegRisk"]
  automatically_active : bool option;
      [@default None] [@key "automaticallyActive"]
  event_date : string option; [@default None] [@key "eventDate"]
  start_time : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "startTime"]
  event_week : int option; [@default None] [@key "eventWeek"]
  series_slug : string option; [@default None] [@key "seriesSlug"]
  score : string option; [@default None]
  elapsed : string option; [@default None]
  period : string option; [@default None]
  live : bool option; [@default None]
  ended : bool option; [@default None]
  finished_timestamp : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "finishedTimestamp"]
  gmp_chart_mode : string option; [@default None] [@key "gmpChartMode"]
  event_creators : event_creator list; [@default []] [@key "eventCreators"]
  tweet_count : int option; [@default None] [@key "tweetCount"]
  chats : chat list; [@default []]
  featured_order : int option; [@default None] [@key "featuredOrder"]
  estimate_value : bool option; [@default None] [@key "estimateValue"]
  cant_estimate : bool option; [@default None] [@key "cantEstimate"]
  estimated_value : string option; [@default None] [@key "estimatedValue"]
  templates : template list; [@default []]
  spreads_main_line : float option; [@default None] [@key "spreadsMainLine"]
  totals_main_line : float option; [@default None] [@key "totalsMainLine"]
  carousel_map : string option; [@default None] [@key "carouselMap"]
  pending_deployment : bool option; [@default None] [@key "pendingDeployment"]
  deploying : bool option; [@default None] [@key "deploying"]
  deploying_timestamp : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "deployingTimestamp"]
  scheduled_deployment_timestamp :
    Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "scheduledDeploymentTimestamp"]
  game_status : string option; [@default None] [@key "gameStatus"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]

and series = {
  id : string;
  ticker : string option; [@default None]
  slug : string option; [@default None]
  title : string option; [@default None]
  subtitle : string option; [@default None]
  series_type : string option; [@default None] [@key "seriesType"]
  recurrence : string option; [@default None]
  description : string option; [@default None]
  image : string option; [@default None]
  icon : string option; [@default None]
  layout : string option; [@default None]
  active : bool option; [@default None]
  closed : bool option; [@default None]
  archived : bool option; [@default None]
  is_new : bool option; [@default None] [@key "new"]
  featured : bool option; [@default None]
  restricted : bool option; [@default None]
  is_template : bool option; [@default None] [@key "isTemplate"]
  template_variables : bool option; [@default None] [@key "templateVariables"]
  published_at : string option; [@default None] [@key "publishedAt"]
  created_by : string option; [@default None] [@key "createdBy"]
  updated_by : string option; [@default None] [@key "updatedBy"]
  created_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "updatedAt"]
  comments_enabled : bool option; [@default None] [@key "commentsEnabled"]
  competitive : string option; [@default None]
  volume_24hr : float option; [@default None] [@key "volume24hr"]
  volume : float option; [@default None]
  liquidity : float option; [@default None]
  start_date : Polymarket_common.Primitives.Timestamp.t option;
      [@default None] [@key "startDate"]
  pyth_token_id : string option; [@default None] [@key "pythTokenID"]
  cg_asset_name : string option; [@default None] [@key "cgAssetName"]
  score : int option; [@default None]
  events : event list; [@default []]
  collections : collection list; [@default []]
  categories : category list; [@default []]
  tags : tag list; [@default []]
  comment_count : int option; [@default None] [@key "commentCount"]
  chats : chat list; [@default []]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]

(** {1 Pagination Response Types} *)

type events_pagination = {
  data : event list; [@default []]
  pagination : pagination option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Paginated events response *)

type search = {
  events : event list option; [@default None]
  tags : search_tag list option; [@default None]
  profiles : profile list option; [@default None]
  pagination : pagination option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Search results *)

(** {1 Sports Types} *)

type sports_metadata = {
  sport : string;
  image : string option; [@default None]
  resolution : string option; [@default None]
  ordering : string;
  tags : string;
  series : string;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Sports metadata *)

type sports_market_types_response = {
  market_types : string list; [@default []] [@key "marketTypes"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq, yojson_fields]
(** Sports market types response *)
