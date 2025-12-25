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
  id : string option; [@default None] [@yojson_drop_default_if_none]
  body : string option; [@default None] [@yojson_drop_default_if_none]
  parent_entity_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "parentEntityType"]
  parent_entity_id : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "parentEntityID"]
  parent_comment_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "parentCommentID"]
  user_address : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "userAddress"]
  reply_address : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "replyAddress"]
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  updated_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedAt"]
  profile : comment_profile option;
      [@default None] [@yojson_drop_default_if_none]
  reactions : reaction list; [@default []]
  report_count : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "reportCount"]
  reaction_count : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "reactionCount"]
}
[@@deriving yojson, show, eq]
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
  id : string option; [@default None] [@yojson_drop_default_if_none]
  question : string option; [@default None] [@yojson_drop_default_if_none]
  condition_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "conditionId"]
  slug : string option; [@default None] [@yojson_drop_default_if_none]
  twitter_card_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "twitterCardImage"]
  resolution_source : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "resolutionSource"]
  end_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "endDate"]
  category : string option; [@default None] [@yojson_drop_default_if_none]
  amm_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "ammType"]
  liquidity : string option; [@default None] [@yojson_drop_default_if_none]
  sponsor_name : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "sponsorName"]
  sponsor_image : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "sponsorImage"]
  start_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "startDate"]
  x_axis_value : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "xAxisValue"]
  y_axis_value : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "yAxisValue"]
  denomination_token : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "denominationToken"]
  fee : string option; [@default None] [@yojson_drop_default_if_none]
  image : string option; [@default None] [@yojson_drop_default_if_none]
  icon : string option; [@default None] [@yojson_drop_default_if_none]
  lower_bound : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "lowerBound"]
  upper_bound : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "upperBound"]
  description : string option; [@default None] [@yojson_drop_default_if_none]
  outcomes : string option; [@default None] [@yojson_drop_default_if_none]
  outcome_prices : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "outcomePrices"]
  volume : string option; [@default None] [@yojson_drop_default_if_none]
  active : bool option; [@default None] [@yojson_drop_default_if_none]
  market_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "marketType"]
  format_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "formatType"]
  lower_bound_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "lowerBoundDate"]
  upper_bound_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "upperBoundDate"]
  closed : bool option; [@default None] [@yojson_drop_default_if_none]
  market_maker_address : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "marketMakerAddress"]
  created_by : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdBy"]
  updated_by : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedBy"]
  created_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "createdAt"]
  updated_at : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "updatedAt"]
  closed_time : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "closedTime"]
  wide_format : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "wideFormat"]
  new_ : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "new"]
  mailchimp_tag : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "mailchimpTag"]
  featured : bool option; [@default None] [@yojson_drop_default_if_none]
  archived : bool option; [@default None] [@yojson_drop_default_if_none]
  resolved_by : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "resolvedBy"]
  restricted : bool option; [@default None] [@yojson_drop_default_if_none]
  market_group : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "marketGroup"]
  group_item_title : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "groupItemTitle"]
  group_item_threshold : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "groupItemThreshold"]
  question_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "questionID"]
  uma_end_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "umaEndDate"]
  enable_order_book : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "enableOrderBook"]
  order_price_min_tick_size : float option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "orderPriceMinTickSize"]
  order_min_size : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "orderMinSize"]
  uma_resolution_status : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "umaResolutionStatus"]
  curation_order : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "curationOrder"]
  volume_num : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "volumeNum"]
  liquidity_num : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "liquidityNum"]
  end_date_iso : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "endDateIso"]
  start_date_iso : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "startDateIso"]
  uma_end_date_iso : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "umaEndDateIso"]
  has_reviewed_dates : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "hasReviewedDates"]
  ready_for_cron : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "readyForCron"]
  comments_enabled : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "commentsEnabled"]
  volume_24hr : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "volume24hr"]
  volume_1wk : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "volume1wk"]
  volume_1mo : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "volume1mo"]
  volume_1yr : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "volume1yr"]
  game_start_time : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "gameStartTime"]
  seconds_delay : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "secondsDelay"]
  clob_token_ids : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "clobTokenIds"]
  disqus_thread : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "disqusThread"]
  short_outcomes : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "shortOutcomes"]
  team_a_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "teamAID"]
  team_b_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "teamBID"]
  uma_bond : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "umaBond"]
  uma_reward : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "umaReward"]
  fpmm_live : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "fpmmLive"]
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
  maker_base_fee : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "makerBaseFee"]
  taker_base_fee : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "takerBaseFee"]
  custom_liveness : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "customLiveness"]
  accepting_orders : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "acceptingOrders"]
  notifications_enabled : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "notificationsEnabled"]
  score : int option; [@default None] [@yojson_drop_default_if_none]
  image_optimized : image_optimization option;
      [@default None] [@yojson_drop_default_if_none] [@key "imageOptimized"]
  icon_optimized : image_optimization option;
      [@default None] [@yojson_drop_default_if_none] [@key "iconOptimized"]
  events : event list; [@default []]
  categories : category list; [@default []]
  tags : tag list; [@default []]
  creator : string option; [@default None] [@yojson_drop_default_if_none]
  ready : bool option; [@default None] [@yojson_drop_default_if_none]
  funded : bool option; [@default None] [@yojson_drop_default_if_none]
  past_slugs : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "pastSlugs"]
  ready_timestamp : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "readyTimestamp"]
  funded_timestamp : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "fundedTimestamp"]
  accepting_orders_timestamp : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "acceptingOrdersTimestamp"]
  competitive : float option; [@default None] [@yojson_drop_default_if_none]
  rewards_min_size : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "rewardsMinSize"]
  rewards_max_spread : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "rewardsMaxSpread"]
  spread : float option; [@default None] [@yojson_drop_default_if_none]
  automatically_resolved : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "automaticallyResolved"]
  one_day_price_change : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "oneDayPriceChange"]
  one_hour_price_change : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "oneHourPriceChange"]
  one_week_price_change : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "oneWeekPriceChange"]
  one_month_price_change : float option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "oneMonthPriceChange"]
  one_year_price_change : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "oneYearPriceChange"]
  last_trade_price : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "lastTradePrice"]
  best_bid : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "bestBid"]
  best_ask : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "bestAsk"]
  automatically_active : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "automaticallyActive"]
  clear_book_on_start : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "clearBookOnStart"]
  chart_color : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "chartColor"]
  series_color : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "seriesColor"]
  show_gmp_series : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "showGmpSeries"]
  show_gmp_outcome : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "showGmpOutcome"]
  manual_activation : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "manualActivation"]
  neg_risk_other : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "negRiskOther"]
  game_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "gameId"]
  group_item_range : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "groupItemRange"]
  sports_market_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "sportsMarketType"]
  line : float option; [@default None] [@yojson_drop_default_if_none]
  uma_resolution_statuses : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "umaResolutionStatuses"]
  pending_deployment : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "pendingDeployment"]
  deploying : bool option; [@default None] [@yojson_drop_default_if_none]
  deploying_timestamp : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "deployingTimestamp"]
  scheduled_deployment_timestamp : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "scheduledDeploymentTimestamp"]
  rfq_enabled : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "rfqEnabled"]
  event_start_time : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "eventStartTime"]
  submitted_by : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "submitted_by"]
  cyom : bool option; [@default None] [@yojson_drop_default_if_none]
  pager_duty_notification_enabled : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "pagerDutyNotificationEnabled"]
  approved : bool option; [@default None] [@yojson_drop_default_if_none]
  holding_rewards_enabled : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "holdingRewardsEnabled"]
  fees_enabled : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "feesEnabled"]
  requires_translation : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "requiresTranslation"]
  neg_risk : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "negRisk"]
  neg_risk_market_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "negRiskMarketID"]
  neg_risk_request_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "negRiskRequestID"]
  clob_rewards : clob_reward list; [@default []] [@key "clobRewards"]
  sent_discord : bool option;
      [@default None] [@yojson_drop_default_if_none] [@key "sentDiscord"]
  twitter_card_location : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "twitterCardLocation"]
  twitter_card_last_refreshed : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "twitterCardLastRefreshed"]
  twitter_card_last_validated : string option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "twitterCardLastValidated"]
}
[@@yojson.allow_extra_fields]

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
  id : string option; [@default None] [@yojson_drop_default_if_none]
  ticker : string option; [@default None] [@yojson_drop_default_if_none]
  slug : string option; [@default None] [@yojson_drop_default_if_none]
  title : string option; [@default None] [@yojson_drop_default_if_none]
  subtitle : string option; [@default None] [@yojson_drop_default_if_none]
  series_type : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "seriesType"]
  recurrence : string option; [@default None] [@yojson_drop_default_if_none]
  description : string option; [@default None] [@yojson_drop_default_if_none]
  image : string option; [@default None] [@yojson_drop_default_if_none]
  icon : string option; [@default None] [@yojson_drop_default_if_none]
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
  template_variables : bool option;
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
  competitive : string option; [@default None] [@yojson_drop_default_if_none]
  volume_24hr : float option;
      [@default None] [@yojson_drop_default_if_none] [@key "volume24hr"]
  volume : float option; [@default None] [@yojson_drop_default_if_none]
  liquidity : float option; [@default None] [@yojson_drop_default_if_none]
  start_date : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "startDate"]
  pyth_token_id : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "pythTokenID"]
  cg_asset_name : string option;
      [@default None] [@yojson_drop_default_if_none] [@key "cgAssetName"]
  score : int option; [@default None] [@yojson_drop_default_if_none]
  events : event list; [@default []]
  collections : collection list; [@default []]
  categories : category list; [@default []]
  tags : tag list; [@default []]
  comment_count : int option;
      [@default None] [@yojson_drop_default_if_none] [@key "commentCount"]
  chats : chat list; [@default []]
  requires_translation : bool option;
      [@default None]
      [@yojson_drop_default_if_none]
      [@key "requiresTranslation"]
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
