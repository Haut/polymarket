(** Gamma API response types for Polymarket.

    These types correspond to the OpenAPI 3.0.3 schema defined in
    gamma-openapi.json for the Polymarket Gamma API
    (https://gamma-api.polymarket.com). *)

open Ppx_yojson_conv_lib.Yojson_conv.Primitives

(** {1 Response Types} *)

type pagination = {
  has_more : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "hasMore"]
  total_results : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "totalResults"]
}
[@@deriving yojson, show, eq]
(** Pagination information *)

type count = {
  count : int option; [@default None] [@yojson_drop_default_if_none]
}
[@@deriving yojson, show, eq]
(** Generic count response *)

type event_tweet_count = {
  tweet_count : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "tweetCount"]
}
[@@deriving yojson, show, eq]
(** Event tweet count response *)

type market_description = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  condition_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "conditionId"]
  market_maker_address : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "marketMakerAddress"]
  description : string option; [@default None] [@yojson_drop_default_if_none]
}
[@@deriving yojson, show, eq]
(** Market description response *)

type image_optimization = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  image_url_source : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "imageUrlSource"]
  image_url_optimized : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "imageUrlOptimized"]
  image_size_kb_source : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "imageSizeKbSource"]
  image_size_kb_optimized : float option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "imageSizeKbOptimized"]
  image_optimized_complete : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "imageOptimizedComplete"]
  image_optimized_last_updated : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "imageOptimizedLastUpdated"]
  rel_id : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "relID"]
  field : string option; [@default None] [@yojson_drop_default_if_none]
  relname : string option; [@default None] [@yojson_drop_default_if_none]
}
[@@deriving yojson, show, eq]
(** Image optimization data *)

(** {1 Basic Domain Types} *)

type team = {
  id : int option; [@default None]
  name : string option; [@default None]
  league : string option; [@default None]
  record : string option; [@default None]
  logo : string option; [@default None]
  abbreviation : string option; [@default None]
  alias : string option; [@default None]
  created_at : Http_client.Client.Timestamp.t option;
      [@default None] [@key "createdAt"]
  updated_at : Http_client.Client.Timestamp.t option;
      [@default None] [@key "updatedAt"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Sports team *)

type tag = {
  id : string option;
  label : string option;
  slug : string option;
  force_show : bool option; [@key "forceShow"]
  published_at : string option; [@key "publishedAt"]
  created_by : int option; [@key "createdBy"]
  updated_by : int option; [@key "updatedBy"]
  created_at : Http_client.Client.Timestamp.t option; [@key "createdAt"]
  updated_at : Http_client.Client.Timestamp.t option; [@key "updatedAt"]
  force_hide : bool option; [@key "forceHide"]
  is_carousel : bool option; [@key "isCarousel"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Tag for categorization *)

type related_tag = {
  id : string option;
  tag_id : int option; [@key "tagID"]
  related_tag_id : int option; [@key "relatedTagID"]
  rank : int option;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Related tag relationship *)

type category = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  label : string option; [@default None] [@yojson_drop_default_if_none]
  parent_category : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "parentCategory"]
  slug : string option; [@default None] [@yojson_drop_default_if_none]
  published_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "publishedAt"]
  created_by : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdBy"]
  updated_by : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedBy"]
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  updated_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedAt"]
}
[@@deriving yojson, show, eq]
(** Market category *)

type event_creator = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  creator_name : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "creatorName"]
  creator_handle : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "creatorHandle"]
  creator_url : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "creatorUrl"]
  creator_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "creatorImage"]
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  updated_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedAt"]
}
[@@deriving yojson, show, eq]
(** Event creator *)

type chat = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  channel_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "channelId"]
  channel_name : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "channelName"]
  channel_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "channelImage"]
  live : bool option; [@default None] [@yojson_drop_default_if_none]
  start_time : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "startTime"]
  end_time : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "endTime"]
}
[@@deriving yojson, show, eq]
(** Chat channel *)

type template = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  event_title : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "eventTitle"]
  event_slug : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "eventSlug"]
  event_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "eventImage"]
  market_title : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "marketTitle"]
  description : string option; [@default None] [@yojson_drop_default_if_none]
  resolution_source : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "resolutionSource"]
  neg_risk : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "negRisk"]
  sort_by : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "sortBy"]
  show_market_images : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "showMarketImages"]
  series_slug : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "seriesSlug"]
  outcomes : string option; [@default None] [@yojson_drop_default_if_none]
}
[@@deriving yojson, show, eq]
(** Event template *)

type search_tag = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  label : string option; [@default None] [@yojson_drop_default_if_none]
  slug : string option; [@default None] [@yojson_drop_default_if_none]
  event_count : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "event_count"]
}
[@@deriving yojson, show, eq]
(** Search result tag *)

(** {1 Comment Types} *)

type comment_position = {
  token_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "tokenId"]
  position_size : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "positionSize"]
}
[@@deriving yojson, show, eq]
(** Position held by a commenter *)

type comment_profile = {
  name : string option; [@default None] [@yojson_drop_default_if_none]
  pseudonym : string option; [@default None] [@yojson_drop_default_if_none]
  display_username_public : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "displayUsernamePublic"]
  bio : string option; [@default None] [@yojson_drop_default_if_none]
  is_mod : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "isMod"]
  is_creator : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "isCreator"]
  proxy_wallet : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "proxyWallet"]
  base_address : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "baseAddress"]
  profile_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "profileImage"]
  profile_image_optimized : image_optimization option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "profileImageOptimized"]
  positions : comment_position list; [@default []]
}
[@@deriving yojson, show, eq]
(** Comment author profile *)

type reaction = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  comment_id : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "commentID"]
  reaction_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "reactionType"]
  icon : string option; [@default None] [@yojson_drop_default_if_none]
  user_address : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "userAddress"]
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  profile : comment_profile option;
      [@default None] [@yojson_drop_default_if_none]
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
  created_at : Http_client.Client.Timestamp.t option;
  updated_at : Http_client.Client.Timestamp.t option;
  profile : comment_profile option;
  reactions : reaction list;
  report_count : int option;
  reaction_count : int option;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Comment *)

(** {1 Profile Types} *)

type public_profile_user = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  creator : bool option; [@default None] [@yojson_drop_default_if_none]
  mod_ : bool option; [@default None] [@yojson_drop_default_if_none] [@key "mod"]
}
[@@deriving yojson, show, eq]
(** Public profile user *)

type public_profile_error = {
  type_ : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "type"]
  error : string option; [@default None] [@yojson_drop_default_if_none]
}
[@@deriving yojson, show, eq]
(** Public profile error response *)

type public_profile_response = {
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  proxy_wallet : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "proxyWallet"]
  profile_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "profileImage"]
  display_username_public : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "displayUsernamePublic"]
  bio : string option; [@default None] [@yojson_drop_default_if_none]
  pseudonym : string option; [@default None] [@yojson_drop_default_if_none]
  name : string option; [@default None] [@yojson_drop_default_if_none]
  users : public_profile_user list option;
      [@default None] [@yojson_drop_default_if_none]
  x_username : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "xUsername"]
  verified_badge : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "verifiedBadge"]
}
[@@deriving yojson, show, eq]
(** Public profile response *)

type profile = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  name : string option; [@default None] [@yojson_drop_default_if_none]
  user : int option; [@default None] [@yojson_drop_default_if_none]
  referral : string option; [@default None] [@yojson_drop_default_if_none]
  created_by : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdBy"]
  updated_by : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedBy"]
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  updated_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedAt"]
  utm_source : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "utmSource"]
  utm_medium : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "utmMedium"]
  utm_campaign : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "utmCampaign"]
  utm_content : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "utmContent"]
  utm_term : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "utmTerm"]
  wallet_activated : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "walletActivated"]
  pseudonym : string option; [@default None] [@yojson_drop_default_if_none]
  display_username_public : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "displayUsernamePublic"]
  profile_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "profileImage"]
  bio : string option; [@default None] [@yojson_drop_default_if_none]
  proxy_wallet : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "proxyWallet"]
  profile_image_optimized : image_optimization option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "profileImageOptimized"]
  is_close_only : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "isCloseOnly"]
  is_cert_req : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "isCertReq"]
  cert_req_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "certReqDate"]
}
[@@deriving yojson, show, eq]
(** User profile *)

(** {1 Collection Type} *)

type collection = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  ticker : string option; [@default None] [@yojson_drop_default_if_none]
  slug : string option; [@default None] [@yojson_drop_default_if_none]
  title : string option; [@default None] [@yojson_drop_default_if_none]
  subtitle : string option; [@default None] [@yojson_drop_default_if_none]
  collection_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "collectionType"]
  description : string option; [@default None] [@yojson_drop_default_if_none]
  tags : string option; [@default None] [@yojson_drop_default_if_none]
  image : string option; [@default None] [@yojson_drop_default_if_none]
  icon : string option; [@default None] [@yojson_drop_default_if_none]
  header_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "headerImage"]
  layout : string option; [@default None] [@yojson_drop_default_if_none]
  active : bool option; [@default None] [@yojson_drop_default_if_none]
  closed : bool option; [@default None] [@yojson_drop_default_if_none]
  archived : bool option; [@default None] [@yojson_drop_default_if_none]
  new_ : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "new"]
  featured : bool option; [@default None] [@yojson_drop_default_if_none]
  restricted : bool option; [@default None] [@yojson_drop_default_if_none]
  is_template : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "isTemplate"]
  template_variables : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "templateVariables"]
  published_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "publishedAt"]
  created_by : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdBy"]
  updated_by : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedBy"]
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  updated_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedAt"]
  comments_enabled : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "commentsEnabled"]
  image_optimized : image_optimization option;
      [@default None] [@yojson_drop_default_if_none] [@key "imageOptimized"]
  icon_optimized : image_optimization option;
      [@default None] [@yojson_drop_default_if_none] [@key "iconOptimized"]
  header_image_optimized : image_optimization option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "headerImageOptimized"]
}
[@@deriving yojson, show, eq]
(** Collection of events/markets *)

(** {1 Series Summary Type} *)

type series_summary = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  title : string option; [@default None] [@yojson_drop_default_if_none]
  slug : string option; [@default None] [@yojson_drop_default_if_none]
  event_dates : string list; [@default []] [@key "eventDates"]
  event_weeks : int list; [@default []] [@key "eventWeeks"]
  earliest_open_week : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "earliest_open_week"]
  earliest_open_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "earliest_open_date"]
}
[@@deriving yojson, show, eq]
(** Series summary *)

(** {1 CLOB Rewards Type} *)

type clob_reward = {
  id : string option; [@default None] [@yojson_drop_default_if_none]
  condition_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "conditionId"]
  asset_address : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "assetAddress"]
  rewards_amount : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "rewardsAmount"]
  rewards_daily_rate : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "rewardsDailyRate"]
  start_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "startDate"]
  end_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "endDate"]
}
[@@deriving yojson, show, eq]
(** CLOB reward configuration *)

(** {1 Mutually Recursive Types: Market, Event, Series}

    These types reference each other and must be defined together. *)

type market = {
  id : string option;
  question : string option;
  condition_id : string option; [@key "conditionId"]
  slug : string option;
  twitter_card_image : string option; [@key "twitterCardImage"]
  resolution_source : string option; [@key "resolutionSource"]
  end_date : Http_client.Client.Timestamp.t option; [@key "endDate"]
  category : string option;
  amm_type : string option; [@key "ammType"]
  liquidity : string option;
  sponsor_name : string option; [@key "sponsorName"]
  sponsor_image : string option; [@key "sponsorImage"]
  start_date : Http_client.Client.Timestamp.t option; [@key "startDate"]
  x_axis_value : string option; [@key "xAxisValue"]
  y_axis_value : string option; [@key "yAxisValue"]
  denomination_token : string option; [@key "denominationToken"]
  fee : string option;
  image : string option;
  icon : string option;
  lower_bound : string option; [@key "lowerBound"]
  upper_bound : string option; [@key "upperBound"]
  description : string option;
  outcomes : string option;
  outcome_prices : string option; [@key "outcomePrices"]
  volume : string option;
  active : bool option;
  market_type : string option; [@key "marketType"]
  format_type : string option; [@key "formatType"]
  lower_bound_date : string option; [@key "lowerBoundDate"]
  upper_bound_date : string option; [@key "upperBoundDate"]
  closed : bool option;
  market_maker_address : string option; [@key "marketMakerAddress"]
  created_by : int option; [@key "createdBy"]
  updated_by : int option; [@key "updatedBy"]
  created_at : Http_client.Client.Timestamp.t option; [@key "createdAt"]
  updated_at : Http_client.Client.Timestamp.t option; [@key "updatedAt"]
  closed_time : string option; [@key "closedTime"]
  wide_format : bool option; [@key "wideFormat"]
  new_ : bool option; [@key "new"]
  mailchimp_tag : string option; [@key "mailchimpTag"]
  featured : bool option;
  archived : bool option;
  resolved_by : string option; [@key "resolvedBy"]
  restricted : bool option;
  market_group : int option; [@key "marketGroup"]
  group_item_title : string option; [@key "groupItemTitle"]
  group_item_threshold : string option; [@key "groupItemThreshold"]
  question_id : string option; [@key "questionID"]
  uma_end_date : string option; [@key "umaEndDate"]
  enable_order_book : bool option; [@key "enableOrderBook"]
  order_price_min_tick_size : float option; [@key "orderPriceMinTickSize"]
  order_min_size : float option; [@key "orderMinSize"]
  uma_resolution_status : string option; [@key "umaResolutionStatus"]
  curation_order : int option; [@key "curationOrder"]
  volume_num : float option; [@key "volumeNum"]
  liquidity_num : float option; [@key "liquidityNum"]
  end_date_iso : string option; [@key "endDateIso"]
  start_date_iso : string option; [@key "startDateIso"]
  uma_end_date_iso : string option; [@key "umaEndDateIso"]
  has_reviewed_dates : bool option; [@key "hasReviewedDates"]
  ready_for_cron : bool option; [@key "readyForCron"]
  comments_enabled : bool option; [@key "commentsEnabled"]
  volume_24hr : float option; [@key "volume24hr"]
  volume_1wk : float option; [@key "volume1wk"]
  volume_1mo : float option; [@key "volume1mo"]
  volume_1yr : float option; [@key "volume1yr"]
  game_start_time : string option; [@key "gameStartTime"]
  seconds_delay : int option; [@key "secondsDelay"]
  clob_token_ids : string option; [@key "clobTokenIds"]
  disqus_thread : string option; [@key "disqusThread"]
  short_outcomes : string option; [@key "shortOutcomes"]
  team_a_id : string option; [@key "teamAID"]
  team_b_id : string option; [@key "teamBID"]
  uma_bond : string option; [@key "umaBond"]
  uma_reward : string option; [@key "umaReward"]
  fpmm_live : bool option; [@key "fpmmLive"]
  volume_24hr_amm : float option; [@key "volume24hrAmm"]
  volume_1wk_amm : float option; [@key "volume1wkAmm"]
  volume_1mo_amm : float option; [@key "volume1moAmm"]
  volume_1yr_amm : float option; [@key "volume1yrAmm"]
  volume_24hr_clob : float option; [@key "volume24hrClob"]
  volume_1wk_clob : float option; [@key "volume1wkClob"]
  volume_1mo_clob : float option; [@key "volume1moClob"]
  volume_1yr_clob : float option; [@key "volume1yrClob"]
  volume_amm : float option; [@key "volumeAmm"]
  volume_clob : float option; [@key "volumeClob"]
  liquidity_amm : float option; [@key "liquidityAmm"]
  liquidity_clob : float option; [@key "liquidityClob"]
  maker_base_fee : int option; [@key "makerBaseFee"]
  taker_base_fee : int option; [@key "takerBaseFee"]
  custom_liveness : int option; [@key "customLiveness"]
  accepting_orders : bool option; [@key "acceptingOrders"]
  notifications_enabled : bool option; [@key "notificationsEnabled"]
  score : int option;
  image_optimized : image_optimization option; [@key "imageOptimized"]
  icon_optimized : image_optimization option; [@key "iconOptimized"]
  events : event list;
  categories : category list;
  tags : tag list;
  creator : string option;
  ready : bool option;
  funded : bool option;
  past_slugs : string option; [@key "pastSlugs"]
  ready_timestamp : Http_client.Client.Timestamp.t option;
      [@key "readyTimestamp"]
  funded_timestamp : Http_client.Client.Timestamp.t option;
      [@key "fundedTimestamp"]
  accepting_orders_timestamp : Http_client.Client.Timestamp.t option;
      [@key "acceptingOrdersTimestamp"]
  competitive : float option;
  rewards_min_size : float option; [@key "rewardsMinSize"]
  rewards_max_spread : float option; [@key "rewardsMaxSpread"]
  spread : float option;
  automatically_resolved : bool option; [@key "automaticallyResolved"]
  one_day_price_change : float option; [@key "oneDayPriceChange"]
  one_hour_price_change : float option; [@key "oneHourPriceChange"]
  one_week_price_change : float option; [@key "oneWeekPriceChange"]
  one_month_price_change : float option; [@key "oneMonthPriceChange"]
  one_year_price_change : float option; [@key "oneYearPriceChange"]
  last_trade_price : float option; [@key "lastTradePrice"]
  best_bid : float option; [@key "bestBid"]
  best_ask : float option; [@key "bestAsk"]
  automatically_active : bool option; [@key "automaticallyActive"]
  clear_book_on_start : bool option; [@key "clearBookOnStart"]
  chart_color : string option; [@key "chartColor"]
  series_color : string option; [@key "seriesColor"]
  show_gmp_series : bool option; [@key "showGmpSeries"]
  show_gmp_outcome : bool option; [@key "showGmpOutcome"]
  manual_activation : bool option; [@key "manualActivation"]
  neg_risk_other : bool option; [@key "negRiskOther"]
  game_id : string option; [@key "gameId"]
  group_item_range : string option; [@key "groupItemRange"]
  sports_market_type : string option; [@key "sportsMarketType"]
  line : float option;
  uma_resolution_statuses : string option; [@key "umaResolutionStatuses"]
  pending_deployment : bool option; [@key "pendingDeployment"]
  deploying : bool option;
  deploying_timestamp : Http_client.Client.Timestamp.t option;
      [@key "deployingTimestamp"]
  scheduled_deployment_timestamp : Http_client.Client.Timestamp.t option;
      [@key "scheduledDeploymentTimestamp"]
  rfq_enabled : bool option; [@key "rfqEnabled"]
  event_start_time : Http_client.Client.Timestamp.t option;
      [@key "eventStartTime"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]

and event = {
  id : string option;
  ticker : string option;
  slug : string option;
  title : string option;
  subtitle : string option;
  description : string option;
  resolution_source : string option; [@key "resolutionSource"]
  start_date : Http_client.Client.Timestamp.t option; [@key "startDate"]
  creation_date : Http_client.Client.Timestamp.t option; [@key "creationDate"]
  end_date : Http_client.Client.Timestamp.t option; [@key "endDate"]
  image : string option;
  icon : string option;
  active : bool option;
  closed : bool option;
  archived : bool option;
  new_ : bool option; [@key "new"]
  featured : bool option;
  restricted : bool option;
  liquidity : float option;
  volume : float option;
  open_interest : float option; [@key "openInterest"]
  sort_by : string option; [@key "sortBy"]
  category : string option;
  subcategory : string option;
  is_template : bool option; [@key "isTemplate"]
  template_variables : string option; [@key "templateVariables"]
  published_at : string option; [@key "published_at"]
  created_by : string option; [@key "createdBy"]
  updated_by : string option; [@key "updatedBy"]
  created_at : Http_client.Client.Timestamp.t option; [@key "createdAt"]
  updated_at : Http_client.Client.Timestamp.t option; [@key "updatedAt"]
  comments_enabled : bool option; [@key "commentsEnabled"]
  competitive : float option;
  volume_24hr : float option; [@key "volume24hr"]
  volume_1wk : float option; [@key "volume1wk"]
  volume_1mo : float option; [@key "volume1mo"]
  volume_1yr : float option; [@key "volume1yr"]
  featured_image : string option; [@key "featuredImage"]
  disqus_thread : string option; [@key "disqusThread"]
  parent_event : string option; [@key "parentEvent"]
  enable_order_book : bool option; [@key "enableOrderBook"]
  liquidity_amm : float option; [@key "liquidityAmm"]
  liquidity_clob : float option; [@key "liquidityClob"]
  neg_risk : bool option; [@key "negRisk"]
  neg_risk_market_id : string option; [@key "negRiskMarketID"]
  neg_risk_fee_bips : int option; [@key "negRiskFeeBips"]
  comment_count : int option; [@key "commentCount"]
  image_optimized : image_optimization option; [@key "imageOptimized"]
  icon_optimized : image_optimization option; [@key "iconOptimized"]
  featured_image_optimized : image_optimization option;
      [@key "featuredImageOptimized"]
  sub_events : string list option; [@key "subEvents"]
  markets : market list;
  series : series list;
  categories : category list;
  collections : collection list;
  tags : tag list;
  cyom : bool option;
  closed_time : Http_client.Client.Timestamp.t option; [@key "closedTime"]
  show_all_outcomes : bool option; [@key "showAllOutcomes"]
  show_market_images : bool option; [@key "showMarketImages"]
  automatically_resolved : bool option; [@key "automaticallyResolved"]
  enable_neg_risk : bool option; [@key "enableNegRisk"]
  automatically_active : bool option; [@key "automaticallyActive"]
  event_date : string option; [@key "eventDate"]
  start_time : Http_client.Client.Timestamp.t option; [@key "startTime"]
  event_week : int option; [@key "eventWeek"]
  series_slug : string option; [@key "seriesSlug"]
  score : string option;
  elapsed : string option;
  period : string option;
  live : bool option;
  ended : bool option;
  finished_timestamp : Http_client.Client.Timestamp.t option;
      [@key "finishedTimestamp"]
  gmp_chart_mode : string option; [@key "gmpChartMode"]
  event_creators : event_creator list; [@key "eventCreators"]
  tweet_count : int option; [@key "tweetCount"]
  chats : chat list;
  featured_order : int option; [@key "featuredOrder"]
  estimate_value : bool option; [@key "estimateValue"]
  cant_estimate : bool option; [@key "cantEstimate"]
  estimated_value : string option; [@key "estimatedValue"]
  templates : template list;
  spreads_main_line : float option; [@key "spreadsMainLine"]
  totals_main_line : float option; [@key "totalsMainLine"]
  carousel_map : string option; [@key "carouselMap"]
  pending_deployment : bool option; [@key "pendingDeployment"]
  deploying : bool option; [@key "deploying"]
  deploying_timestamp : Http_client.Client.Timestamp.t option;
      [@key "deployingTimestamp"]
  scheduled_deployment_timestamp : Http_client.Client.Timestamp.t option;
      [@key "scheduledDeploymentTimestamp"]
  game_status : string option; [@key "gameStatus"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]

and series = {
  id : string option;
  ticker : string option;
  slug : string option;
  title : string option;
  subtitle : string option;
  series_type : string option; [@key "seriesType"]
  recurrence : string option;
  description : string option;
  image : string option;
  icon : string option;
  layout : string option;
  active : bool option;
  closed : bool option;
  archived : bool option;
  new_ : bool option; [@key "new"]
  featured : bool option;
  restricted : bool option;
  is_template : bool option; [@key "isTemplate"]
  template_variables : bool option; [@key "templateVariables"]
  published_at : string option; [@key "publishedAt"]
  created_by : string option; [@key "createdBy"]
  updated_by : string option; [@key "updatedBy"]
  created_at : Http_client.Client.Timestamp.t option; [@key "createdAt"]
  updated_at : Http_client.Client.Timestamp.t option; [@key "updatedAt"]
  comments_enabled : bool option; [@key "commentsEnabled"]
  competitive : string option;
  volume_24hr : float option; [@key "volume24hr"]
  volume : float option;
  liquidity : float option;
  start_date : Http_client.Client.Timestamp.t option; [@key "startDate"]
  pyth_token_id : string option; [@key "pythTokenID"]
  cg_asset_name : string option; [@key "cgAssetName"]
  score : int option;
  events : event list;
  collections : collection list;
  categories : category list;
  tags : tag list;
  comment_count : int option; [@key "commentCount"]
  chats : chat list;
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]

(** {1 Pagination Response Types} *)

type events_pagination = {
  data : event list; [@default []]
  pagination : pagination option; [@default None] [@yojson_drop_default_if_none]
}
[@@deriving yojson, show, eq]
(** Paginated events response *)

type search = {
  events : event list option; [@default None] [@yojson_drop_default_if_none]
  tags : search_tag list option; [@default None] [@yojson_drop_default_if_none]
  profiles : profile list option; [@default None] [@yojson_drop_default_if_none]
  pagination : pagination option; [@default None] [@yojson_drop_default_if_none]
}
[@@deriving yojson, show, eq]
(** Search results *)

(** {1 Sports Types} *)

type sports_metadata = {
  sport : string option; [@default None]
  image : string option; [@default None]
  resolution : string option; [@default None]
  ordering : string option; [@default None]
  tags : string option; [@default None]
  series : string option; [@default None]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Sports metadata *)

type sports_market_types_response = {
  market_types : string list; [@default []] [@key "marketTypes"]
}
[@@yojson.allow_extra_fields] [@@deriving yojson, show, eq]
(** Sports market types response *)
