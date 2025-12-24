(** Gamma API types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    gamma-openapi.json for the Polymarket Gamma API
    (https://gamma-api.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Simple Types} *)

type pagination = {
  has_more : bool option; [@yojson.option] [@key "hasMore"]
  total_results : int option; [@yojson.option] [@key "totalResults"]
}
[@@deriving yojson, show, eq]
(** Pagination information *)

type count = { count : int option [@yojson.option] }
[@@deriving yojson, show, eq]
(** Generic count response *)

type event_tweet_count = { tweet_count : int option [@yojson.option] [@key "tweetCount"] }
[@@deriving yojson, show, eq]
(** Event tweet count response *)

type market_description = { description : string option [@yojson.option] }
[@@deriving yojson, show, eq]
(** Market description response *)

type image_optimization = {
  id : string option; [@yojson.option]
  image_url_source : string option; [@yojson.option] [@key "imageUrlSource"]
  image_url_optimized : string option; [@yojson.option] [@key "imageUrlOptimized"]
  image_size_kb_source : float option; [@yojson.option] [@key "imageSizeKbSource"]
  image_size_kb_optimized : float option; [@yojson.option] [@key "imageSizeKbOptimized"]
  image_optimized_complete : bool option; [@yojson.option] [@key "imageOptimizedComplete"]
  image_optimized_last_updated : string option; [@yojson.option] [@key "imageOptimizedLastUpdated"]
  rel_id : int option; [@yojson.option] [@key "relID"]
  field : string option; [@yojson.option]
  relname : string option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Image optimization data *)

(** {1 Basic Domain Types} *)

type team = {
  id : int option; [@yojson.option]
  name : string option; [@yojson.option]
  league : string option; [@yojson.option]
  record : string option; [@yojson.option]
  logo : string option; [@yojson.option]
  abbreviation : string option; [@yojson.option]
  alias : string option; [@yojson.option]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
}
[@@deriving yojson, show, eq]
(** Sports team *)

type tag = {
  id : string option; [@yojson.option]
  label : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  force_show : bool option; [@yojson.option] [@key "forceShow"]
  published_at : string option; [@yojson.option] [@key "publishedAt"]
  created_by : int option; [@yojson.option] [@key "createdBy"]
  updated_by : int option; [@yojson.option] [@key "updatedBy"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
  force_hide : bool option; [@yojson.option] [@key "forceHide"]
  is_carousel : bool option; [@yojson.option] [@key "isCarousel"]
}
[@@deriving yojson, show, eq]
(** Tag for categorization *)

type related_tag = {
  id : string option; [@yojson.option]
  tag_id : int option; [@yojson.option] [@key "tagID"]
  related_tag_id : int option; [@yojson.option] [@key "relatedTagID"]
  rank : int option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Related tag relationship *)

type category = {
  id : string option; [@yojson.option]
  label : string option; [@yojson.option]
  parent_category : string option; [@yojson.option] [@key "parentCategory"]
  slug : string option; [@yojson.option]
  published_at : string option; [@yojson.option] [@key "publishedAt"]
  created_by : string option; [@yojson.option] [@key "createdBy"]
  updated_by : string option; [@yojson.option] [@key "updatedBy"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
}
[@@deriving yojson, show, eq]
(** Market category *)

type event_creator = {
  id : string option; [@yojson.option]
  creator_name : string option; [@yojson.option] [@key "creatorName"]
  creator_handle : string option; [@yojson.option] [@key "creatorHandle"]
  creator_url : string option; [@yojson.option] [@key "creatorUrl"]
  creator_image : string option; [@yojson.option] [@key "creatorImage"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
}
[@@deriving yojson, show, eq]
(** Event creator *)

type chat = {
  id : string option; [@yojson.option]
  channel_id : string option; [@yojson.option] [@key "channelId"]
  channel_name : string option; [@yojson.option] [@key "channelName"]
  channel_image : string option; [@yojson.option] [@key "channelImage"]
  live : bool option; [@yojson.option]
  start_time : string option; [@yojson.option] [@key "startTime"]
  end_time : string option; [@yojson.option] [@key "endTime"]
}
[@@deriving yojson, show, eq]
(** Chat channel *)

type template = {
  id : string option; [@yojson.option]
  event_title : string option; [@yojson.option] [@key "eventTitle"]
  event_slug : string option; [@yojson.option] [@key "eventSlug"]
  event_image : string option; [@yojson.option] [@key "eventImage"]
  market_title : string option; [@yojson.option] [@key "marketTitle"]
  description : string option; [@yojson.option]
  resolution_source : string option; [@yojson.option] [@key "resolutionSource"]
  neg_risk : bool option; [@yojson.option] [@key "negRisk"]
  sort_by : string option; [@yojson.option] [@key "sortBy"]
  show_market_images : bool option; [@yojson.option] [@key "showMarketImages"]
  series_slug : string option; [@yojson.option] [@key "seriesSlug"]
  outcomes : string option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Event template *)

type search_tag = {
  id : string option; [@yojson.option]
  label : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  event_count : int option; [@yojson.option] [@key "event_count"]
}
[@@deriving yojson, show, eq]
(** Search result tag *)

(** {1 Comment Types} *)

type comment_position = {
  token_id : string option; [@yojson.option] [@key "tokenId"]
  position_size : string option; [@yojson.option] [@key "positionSize"]
}
[@@deriving yojson, show, eq]
(** Position held by a commenter *)

type comment_profile = {
  name : string option; [@yojson.option]
  pseudonym : string option; [@yojson.option]
  display_username_public : bool option; [@yojson.option] [@key "displayUsernamePublic"]
  bio : string option; [@yojson.option]
  is_mod : bool option; [@yojson.option] [@key "isMod"]
  is_creator : bool option; [@yojson.option] [@key "isCreator"]
  proxy_wallet : string option; [@yojson.option] [@key "proxyWallet"]
  base_address : string option; [@yojson.option] [@key "baseAddress"]
  profile_image : string option; [@yojson.option] [@key "profileImage"]
  profile_image_optimized : image_optimization option; [@yojson.option] [@key "profileImageOptimized"]
  positions : comment_position list; [@default []]
}
[@@deriving yojson, show, eq]
(** Comment author profile *)

type reaction = {
  id : string option; [@yojson.option]
  comment_id : int option; [@yojson.option] [@key "commentID"]
  reaction_type : string option; [@yojson.option] [@key "reactionType"]
  icon : string option; [@yojson.option]
  user_address : string option; [@yojson.option] [@key "userAddress"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  profile : comment_profile option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Comment reaction *)

type comment = {
  id : string option; [@yojson.option]
  body : string option; [@yojson.option]
  parent_entity_type : string option; [@yojson.option] [@key "parentEntityType"]
  parent_entity_id : int option; [@yojson.option] [@key "parentEntityID"]
  parent_comment_id : string option; [@yojson.option] [@key "parentCommentID"]
  user_address : string option; [@yojson.option] [@key "userAddress"]
  reply_address : string option; [@yojson.option] [@key "replyAddress"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
  profile : comment_profile option; [@yojson.option]
  reactions : reaction list; [@default []]
  report_count : int option; [@yojson.option] [@key "reportCount"]
  reaction_count : int option; [@yojson.option] [@key "reactionCount"]
}
[@@deriving yojson, show, eq]
(** Comment *)

(** {1 Profile Types} *)

type public_profile_user = {
  id : string option; [@yojson.option]
  creator : bool option; [@yojson.option]
  mod_ : bool option; [@yojson.option] [@key "mod"]
}
[@@deriving yojson, show, eq]
(** Public profile user *)

type public_profile_error = {
  type_ : string option; [@yojson.option] [@key "type"]
  error : string option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Public profile error response *)

type public_profile_response = {
  created_at : string option; [@yojson.option] [@key "createdAt"]
  proxy_wallet : string option; [@yojson.option] [@key "proxyWallet"]
  profile_image : string option; [@yojson.option] [@key "profileImage"]
  display_username_public : bool option; [@yojson.option] [@key "displayUsernamePublic"]
  bio : string option; [@yojson.option]
  pseudonym : string option; [@yojson.option]
  name : string option; [@yojson.option]
  users : public_profile_user list option; [@yojson.option]
  x_username : string option; [@yojson.option] [@key "xUsername"]
  verified_badge : bool option; [@yojson.option] [@key "verifiedBadge"]
}
[@@deriving yojson, show, eq]
(** Public profile response *)

type profile = {
  id : string option; [@yojson.option]
  name : string option; [@yojson.option]
  user : int option; [@yojson.option]
  referral : string option; [@yojson.option]
  created_by : int option; [@yojson.option] [@key "createdBy"]
  updated_by : int option; [@yojson.option] [@key "updatedBy"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
  utm_source : string option; [@yojson.option] [@key "utmSource"]
  utm_medium : string option; [@yojson.option] [@key "utmMedium"]
  utm_campaign : string option; [@yojson.option] [@key "utmCampaign"]
  utm_content : string option; [@yojson.option] [@key "utmContent"]
  utm_term : string option; [@yojson.option] [@key "utmTerm"]
  wallet_activated : bool option; [@yojson.option] [@key "walletActivated"]
  pseudonym : string option; [@yojson.option]
  display_username_public : bool option; [@yojson.option] [@key "displayUsernamePublic"]
  profile_image : string option; [@yojson.option] [@key "profileImage"]
  bio : string option; [@yojson.option]
  proxy_wallet : string option; [@yojson.option] [@key "proxyWallet"]
  profile_image_optimized : image_optimization option; [@yojson.option] [@key "profileImageOptimized"]
  is_close_only : bool option; [@yojson.option] [@key "isCloseOnly"]
  is_cert_req : bool option; [@yojson.option] [@key "isCertReq"]
  cert_req_date : string option; [@yojson.option] [@key "certReqDate"]
}
[@@deriving yojson, show, eq]
(** User profile *)

(** {1 Collection Type} *)

type collection = {
  id : string option; [@yojson.option]
  ticker : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  title : string option; [@yojson.option]
  subtitle : string option; [@yojson.option]
  collection_type : string option; [@yojson.option] [@key "collectionType"]
  description : string option; [@yojson.option]
  tags : string option; [@yojson.option]
  image : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  header_image : string option; [@yojson.option] [@key "headerImage"]
  layout : string option; [@yojson.option]
  active : bool option; [@yojson.option]
  closed : bool option; [@yojson.option]
  archived : bool option; [@yojson.option]
  new_ : bool option; [@yojson.option] [@key "new"]
  featured : bool option; [@yojson.option]
  restricted : bool option; [@yojson.option]
  is_template : bool option; [@yojson.option] [@key "isTemplate"]
  template_variables : string option; [@yojson.option] [@key "templateVariables"]
  published_at : string option; [@yojson.option] [@key "publishedAt"]
  created_by : string option; [@yojson.option] [@key "createdBy"]
  updated_by : string option; [@yojson.option] [@key "updatedBy"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
  comments_enabled : bool option; [@yojson.option] [@key "commentsEnabled"]
  image_optimized : image_optimization option; [@yojson.option] [@key "imageOptimized"]
  icon_optimized : image_optimization option; [@yojson.option] [@key "iconOptimized"]
  header_image_optimized : image_optimization option; [@yojson.option] [@key "headerImageOptimized"]
}
[@@deriving yojson, show, eq]
(** Collection of events/markets *)

(** {1 Series Summary Type} *)

type series_summary = {
  id : string option; [@yojson.option]
  title : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  event_dates : string list; [@default []] [@key "eventDates"]
  event_weeks : int list; [@default []] [@key "eventWeeks"]
  earliest_open_week : int option; [@yojson.option] [@key "earliest_open_week"]
  earliest_open_date : string option; [@yojson.option] [@key "earliest_open_date"]
}
[@@deriving yojson, show, eq]
(** Series summary *)

(** {1 Mutually Recursive Types: Market, Event, Series}

    These types reference each other and must be defined together. *)

type market = {
  id : string option; [@yojson.option]
  question : string option; [@yojson.option]
  condition_id : string option; [@yojson.option] [@key "conditionId"]
  slug : string option; [@yojson.option]
  twitter_card_image : string option; [@yojson.option] [@key "twitterCardImage"]
  resolution_source : string option; [@yojson.option] [@key "resolutionSource"]
  end_date : string option; [@yojson.option] [@key "endDate"]
  category : string option; [@yojson.option]
  amm_type : string option; [@yojson.option] [@key "ammType"]
  liquidity : string option; [@yojson.option]
  sponsor_name : string option; [@yojson.option] [@key "sponsorName"]
  sponsor_image : string option; [@yojson.option] [@key "sponsorImage"]
  start_date : string option; [@yojson.option] [@key "startDate"]
  x_axis_value : string option; [@yojson.option] [@key "xAxisValue"]
  y_axis_value : string option; [@yojson.option] [@key "yAxisValue"]
  denomination_token : string option; [@yojson.option] [@key "denominationToken"]
  fee : string option; [@yojson.option]
  image : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  lower_bound : string option; [@yojson.option] [@key "lowerBound"]
  upper_bound : string option; [@yojson.option] [@key "upperBound"]
  description : string option; [@yojson.option]
  outcomes : string option; [@yojson.option]
  outcome_prices : string option; [@yojson.option] [@key "outcomePrices"]
  volume : string option; [@yojson.option]
  active : bool option; [@yojson.option]
  market_type : string option; [@yojson.option] [@key "marketType"]
  format_type : string option; [@yojson.option] [@key "formatType"]
  lower_bound_date : string option; [@yojson.option] [@key "lowerBoundDate"]
  upper_bound_date : string option; [@yojson.option] [@key "upperBoundDate"]
  closed : bool option; [@yojson.option]
  market_maker_address : string option; [@yojson.option] [@key "marketMakerAddress"]
  created_by : int option; [@yojson.option] [@key "createdBy"]
  updated_by : int option; [@yojson.option] [@key "updatedBy"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
  closed_time : string option; [@yojson.option] [@key "closedTime"]
  wide_format : bool option; [@yojson.option] [@key "wideFormat"]
  new_ : bool option; [@yojson.option] [@key "new"]
  mailchimp_tag : string option; [@yojson.option] [@key "mailchimpTag"]
  featured : bool option; [@yojson.option]
  archived : bool option; [@yojson.option]
  resolved_by : string option; [@yojson.option] [@key "resolvedBy"]
  restricted : bool option; [@yojson.option]
  market_group : int option; [@yojson.option] [@key "marketGroup"]
  group_item_title : string option; [@yojson.option] [@key "groupItemTitle"]
  group_item_threshold : string option; [@yojson.option] [@key "groupItemThreshold"]
  question_id : string option; [@yojson.option] [@key "questionID"]
  uma_end_date : string option; [@yojson.option] [@key "umaEndDate"]
  enable_order_book : bool option; [@yojson.option] [@key "enableOrderBook"]
  order_price_min_tick_size : float option; [@yojson.option] [@key "orderPriceMinTickSize"]
  order_min_size : float option; [@yojson.option] [@key "orderMinSize"]
  uma_resolution_status : string option; [@yojson.option] [@key "umaResolutionStatus"]
  curation_order : int option; [@yojson.option] [@key "curationOrder"]
  volume_num : float option; [@yojson.option] [@key "volumeNum"]
  liquidity_num : float option; [@yojson.option] [@key "liquidityNum"]
  end_date_iso : string option; [@yojson.option] [@key "endDateIso"]
  start_date_iso : string option; [@yojson.option] [@key "startDateIso"]
  uma_end_date_iso : string option; [@yojson.option] [@key "umaEndDateIso"]
  has_reviewed_dates : bool option; [@yojson.option] [@key "hasReviewedDates"]
  ready_for_cron : bool option; [@yojson.option] [@key "readyForCron"]
  comments_enabled : bool option; [@yojson.option] [@key "commentsEnabled"]
  volume_24hr : float option; [@yojson.option] [@key "volume24hr"]
  volume_1wk : float option; [@yojson.option] [@key "volume1wk"]
  volume_1mo : float option; [@yojson.option] [@key "volume1mo"]
  volume_1yr : float option; [@yojson.option] [@key "volume1yr"]
  game_start_time : string option; [@yojson.option] [@key "gameStartTime"]
  seconds_delay : int option; [@yojson.option] [@key "secondsDelay"]
  clob_token_ids : string option; [@yojson.option] [@key "clobTokenIds"]
  disqus_thread : string option; [@yojson.option] [@key "disqusThread"]
  short_outcomes : string option; [@yojson.option] [@key "shortOutcomes"]
  team_a_id : string option; [@yojson.option] [@key "teamAID"]
  team_b_id : string option; [@yojson.option] [@key "teamBID"]
  uma_bond : string option; [@yojson.option] [@key "umaBond"]
  uma_reward : string option; [@yojson.option] [@key "umaReward"]
  fpmm_live : bool option; [@yojson.option] [@key "fpmmLive"]
  volume_24hr_amm : float option; [@yojson.option] [@key "volume24hrAmm"]
  volume_1wk_amm : float option; [@yojson.option] [@key "volume1wkAmm"]
  volume_1mo_amm : float option; [@yojson.option] [@key "volume1moAmm"]
  volume_1yr_amm : float option; [@yojson.option] [@key "volume1yrAmm"]
  volume_24hr_clob : float option; [@yojson.option] [@key "volume24hrClob"]
  volume_1wk_clob : float option; [@yojson.option] [@key "volume1wkClob"]
  volume_1mo_clob : float option; [@yojson.option] [@key "volume1moClob"]
  volume_1yr_clob : float option; [@yojson.option] [@key "volume1yrClob"]
  volume_amm : float option; [@yojson.option] [@key "volumeAmm"]
  volume_clob : float option; [@yojson.option] [@key "volumeClob"]
  liquidity_amm : float option; [@yojson.option] [@key "liquidityAmm"]
  liquidity_clob : float option; [@yojson.option] [@key "liquidityClob"]
  maker_base_fee : int option; [@yojson.option] [@key "makerBaseFee"]
  taker_base_fee : int option; [@yojson.option] [@key "takerBaseFee"]
  custom_liveness : int option; [@yojson.option] [@key "customLiveness"]
  accepting_orders : bool option; [@yojson.option] [@key "acceptingOrders"]
  notifications_enabled : bool option; [@yojson.option] [@key "notificationsEnabled"]
  score : int option; [@yojson.option]
  image_optimized : image_optimization option; [@yojson.option] [@key "imageOptimized"]
  icon_optimized : image_optimization option; [@yojson.option] [@key "iconOptimized"]
  events : event list; [@default []]
  categories : category list; [@default []]
  tags : tag list; [@default []]
  creator : string option; [@yojson.option]
  ready : bool option; [@yojson.option]
  funded : bool option; [@yojson.option]
  past_slugs : string option; [@yojson.option] [@key "pastSlugs"]
  ready_timestamp : string option; [@yojson.option] [@key "readyTimestamp"]
  funded_timestamp : string option; [@yojson.option] [@key "fundedTimestamp"]
  accepting_orders_timestamp : string option; [@yojson.option] [@key "acceptingOrdersTimestamp"]
  competitive : float option; [@yojson.option]
  rewards_min_size : float option; [@yojson.option] [@key "rewardsMinSize"]
  rewards_max_spread : float option; [@yojson.option] [@key "rewardsMaxSpread"]
  spread : float option; [@yojson.option]
  automatically_resolved : bool option; [@yojson.option] [@key "automaticallyResolved"]
  one_day_price_change : float option; [@yojson.option] [@key "oneDayPriceChange"]
  one_hour_price_change : float option; [@yojson.option] [@key "oneHourPriceChange"]
  one_week_price_change : float option; [@yojson.option] [@key "oneWeekPriceChange"]
  one_month_price_change : float option; [@yojson.option] [@key "oneMonthPriceChange"]
  one_year_price_change : float option; [@yojson.option] [@key "oneYearPriceChange"]
  last_trade_price : float option; [@yojson.option] [@key "lastTradePrice"]
  best_bid : float option; [@yojson.option] [@key "bestBid"]
  best_ask : float option; [@yojson.option] [@key "bestAsk"]
  automatically_active : bool option; [@yojson.option] [@key "automaticallyActive"]
  clear_book_on_start : bool option; [@yojson.option] [@key "clearBookOnStart"]
  chart_color : string option; [@yojson.option] [@key "chartColor"]
  series_color : string option; [@yojson.option] [@key "seriesColor"]
  show_gmp_series : bool option; [@yojson.option] [@key "showGmpSeries"]
  show_gmp_outcome : bool option; [@yojson.option] [@key "showGmpOutcome"]
  manual_activation : bool option; [@yojson.option] [@key "manualActivation"]
  neg_risk_other : bool option; [@yojson.option] [@key "negRiskOther"]
  game_id : string option; [@yojson.option] [@key "gameId"]
  group_item_range : string option; [@yojson.option] [@key "groupItemRange"]
  sports_market_type : string option; [@yojson.option] [@key "sportsMarketType"]
  line : float option; [@yojson.option]
  uma_resolution_statuses : string option; [@yojson.option] [@key "umaResolutionStatuses"]
  pending_deployment : bool option; [@yojson.option] [@key "pendingDeployment"]
  deploying : bool option; [@yojson.option]
  deploying_timestamp : string option; [@yojson.option] [@key "deployingTimestamp"]
  scheduled_deployment_timestamp : string option; [@yojson.option] [@key "scheduledDeploymentTimestamp"]
  rfq_enabled : bool option; [@yojson.option] [@key "rfqEnabled"]
  event_start_time : string option; [@yojson.option] [@key "eventStartTime"]
}

and event = {
  id : string option; [@yojson.option]
  ticker : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  title : string option; [@yojson.option]
  subtitle : string option; [@yojson.option]
  description : string option; [@yojson.option]
  resolution_source : string option; [@yojson.option] [@key "resolutionSource"]
  start_date : string option; [@yojson.option] [@key "startDate"]
  creation_date : string option; [@yojson.option] [@key "creationDate"]
  end_date : string option; [@yojson.option] [@key "endDate"]
  image : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  active : bool option; [@yojson.option]
  closed : bool option; [@yojson.option]
  archived : bool option; [@yojson.option]
  new_ : bool option; [@yojson.option] [@key "new"]
  featured : bool option; [@yojson.option]
  restricted : bool option; [@yojson.option]
  liquidity : float option; [@yojson.option]
  volume : float option; [@yojson.option]
  open_interest : float option; [@yojson.option] [@key "openInterest"]
  sort_by : string option; [@yojson.option] [@key "sortBy"]
  category : string option; [@yojson.option]
  subcategory : string option; [@yojson.option]
  is_template : bool option; [@yojson.option] [@key "isTemplate"]
  template_variables : string option; [@yojson.option] [@key "templateVariables"]
  published_at : string option; [@yojson.option] [@key "published_at"]
  created_by : string option; [@yojson.option] [@key "createdBy"]
  updated_by : string option; [@yojson.option] [@key "updatedBy"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
  comments_enabled : bool option; [@yojson.option] [@key "commentsEnabled"]
  competitive : float option; [@yojson.option]
  volume_24hr : float option; [@yojson.option] [@key "volume24hr"]
  volume_1wk : float option; [@yojson.option] [@key "volume1wk"]
  volume_1mo : float option; [@yojson.option] [@key "volume1mo"]
  volume_1yr : float option; [@yojson.option] [@key "volume1yr"]
  featured_image : string option; [@yojson.option] [@key "featuredImage"]
  disqus_thread : string option; [@yojson.option] [@key "disqusThread"]
  parent_event : string option; [@yojson.option] [@key "parentEvent"]
  enable_order_book : bool option; [@yojson.option] [@key "enableOrderBook"]
  liquidity_amm : float option; [@yojson.option] [@key "liquidityAmm"]
  liquidity_clob : float option; [@yojson.option] [@key "liquidityClob"]
  neg_risk : bool option; [@yojson.option] [@key "negRisk"]
  neg_risk_market_id : string option; [@yojson.option] [@key "negRiskMarketID"]
  neg_risk_fee_bips : int option; [@yojson.option] [@key "negRiskFeeBips"]
  comment_count : int option; [@yojson.option] [@key "commentCount"]
  image_optimized : image_optimization option; [@yojson.option] [@key "imageOptimized"]
  icon_optimized : image_optimization option; [@yojson.option] [@key "iconOptimized"]
  featured_image_optimized : image_optimization option; [@yojson.option] [@key "featuredImageOptimized"]
  sub_events : string list option; [@yojson.option] [@key "subEvents"]
  markets : market list; [@default []]
  series : series list; [@default []]
  categories : category list; [@default []]
  collections : collection list; [@default []]
  tags : tag list; [@default []]
  cyom : bool option; [@yojson.option]
  closed_time : string option; [@yojson.option] [@key "closedTime"]
  show_all_outcomes : bool option; [@yojson.option] [@key "showAllOutcomes"]
  show_market_images : bool option; [@yojson.option] [@key "showMarketImages"]
  automatically_resolved : bool option; [@yojson.option] [@key "automaticallyResolved"]
  enable_neg_risk : bool option; [@yojson.option] [@key "enableNegRisk"]
  automatically_active : bool option; [@yojson.option] [@key "automaticallyActive"]
  event_date : string option; [@yojson.option] [@key "eventDate"]
  start_time : string option; [@yojson.option] [@key "startTime"]
  event_week : int option; [@yojson.option] [@key "eventWeek"]
  series_slug : string option; [@yojson.option] [@key "seriesSlug"]
  score : string option; [@yojson.option]
  elapsed : string option; [@yojson.option]
  period : string option; [@yojson.option]
  live : bool option; [@yojson.option]
  ended : bool option; [@yojson.option]
  finished_timestamp : string option; [@yojson.option] [@key "finishedTimestamp"]
  gmp_chart_mode : string option; [@yojson.option] [@key "gmpChartMode"]
  event_creators : event_creator list; [@default []] [@key "eventCreators"]
  tweet_count : int option; [@yojson.option] [@key "tweetCount"]
  chats : chat list; [@default []]
  featured_order : int option; [@yojson.option] [@key "featuredOrder"]
  estimate_value : bool option; [@yojson.option] [@key "estimateValue"]
  cant_estimate : bool option; [@yojson.option] [@key "cantEstimate"]
  estimated_value : string option; [@yojson.option] [@key "estimatedValue"]
  templates : template list; [@default []]
  spreads_main_line : float option; [@yojson.option] [@key "spreadsMainLine"]
  totals_main_line : float option; [@yojson.option] [@key "totalsMainLine"]
  carousel_map : string option; [@yojson.option] [@key "carouselMap"]
  pending_deployment : bool option; [@yojson.option] [@key "pendingDeployment"]
  deploying : bool option; [@yojson.option]
  deploying_timestamp : string option; [@yojson.option] [@key "deployingTimestamp"]
  scheduled_deployment_timestamp : string option; [@yojson.option] [@key "scheduledDeploymentTimestamp"]
  game_status : string option; [@yojson.option] [@key "gameStatus"]
}

and series = {
  id : string option; [@yojson.option]
  ticker : string option; [@yojson.option]
  slug : string option; [@yojson.option]
  title : string option; [@yojson.option]
  subtitle : string option; [@yojson.option]
  series_type : string option; [@yojson.option] [@key "seriesType"]
  recurrence : string option; [@yojson.option]
  description : string option; [@yojson.option]
  image : string option; [@yojson.option]
  icon : string option; [@yojson.option]
  layout : string option; [@yojson.option]
  active : bool option; [@yojson.option]
  closed : bool option; [@yojson.option]
  archived : bool option; [@yojson.option]
  new_ : bool option; [@yojson.option] [@key "new"]
  featured : bool option; [@yojson.option]
  restricted : bool option; [@yojson.option]
  is_template : bool option; [@yojson.option] [@key "isTemplate"]
  template_variables : bool option; [@yojson.option] [@key "templateVariables"]
  published_at : string option; [@yojson.option] [@key "publishedAt"]
  created_by : string option; [@yojson.option] [@key "createdBy"]
  updated_by : string option; [@yojson.option] [@key "updatedBy"]
  created_at : string option; [@yojson.option] [@key "createdAt"]
  updated_at : string option; [@yojson.option] [@key "updatedAt"]
  comments_enabled : bool option; [@yojson.option] [@key "commentsEnabled"]
  competitive : string option; [@yojson.option]
  volume_24hr : float option; [@yojson.option] [@key "volume24hr"]
  volume : float option; [@yojson.option]
  liquidity : float option; [@yojson.option]
  start_date : string option; [@yojson.option] [@key "startDate"]
  pyth_token_id : string option; [@yojson.option] [@key "pythTokenID"]
  cg_asset_name : string option; [@yojson.option] [@key "cgAssetName"]
  score : int option; [@yojson.option]
  events : event list; [@default []]
  collections : collection list; [@default []]
  categories : category list; [@default []]
  tags : tag list; [@default []]
  comment_count : int option; [@yojson.option] [@key "commentCount"]
  chats : chat list; [@default []]
}
[@@deriving yojson, show, eq]

(** {1 Pagination Response Types} *)

type events_pagination = {
  data : event list; [@default []]
  pagination : pagination option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Paginated events response *)

type search = {
  events : event list option; [@yojson.option]
  tags : search_tag list option; [@yojson.option]
  profiles : profile list option; [@yojson.option]
  pagination : pagination option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Search results *)

(** {1 Sports Types} *)

type sports_metadata = {
  sport : string option; [@yojson.option]
  image : string option; [@yojson.option]
  resolution : string option; [@yojson.option]
  ordering : string option; [@yojson.option]
  tags : string option; [@yojson.option]
  series : string option; [@yojson.option]
}
[@@deriving yojson, show, eq]
(** Sports metadata *)

type sports_market_types_response = {
  market_types : string list; [@default []] [@key "marketTypes"]
}
[@@deriving yojson, show, eq]
(** Sports market types response *)

(** {1 Request Body Types} *)

type markets_information_body = {
  id : int list option; [@yojson.option]
  slug : string list option; [@yojson.option]
  closed : bool option; [@yojson.option]
  clob_token_ids : string list option; [@yojson.option] [@key "clobTokenIds"]
  condition_ids : string list option; [@yojson.option] [@key "conditionIds"]
  market_maker_address : string list option; [@yojson.option] [@key "marketMakerAddress"]
  liquidity_num_min : float option; [@yojson.option] [@key "liquidityNumMin"]
  liquidity_num_max : float option; [@yojson.option] [@key "liquidityNumMax"]
  volume_num_min : float option; [@yojson.option] [@key "volumeNumMin"]
  volume_num_max : float option; [@yojson.option] [@key "volumeNumMax"]
  start_date_min : string option; [@yojson.option] [@key "startDateMin"]
  start_date_max : string option; [@yojson.option] [@key "startDateMax"]
  end_date_min : string option; [@yojson.option] [@key "endDateMin"]
  end_date_max : string option; [@yojson.option] [@key "endDateMax"]
}
[@@deriving yojson, show, eq]
(** Markets information request body *)
