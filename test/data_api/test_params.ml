(** Unit tests for Data_api.Params module *)

open Polymarket.Data_api.Params

(** {1 Sort Direction Tests} *)

let test_sort_direction_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_sort_direction
    [ (ASC, "ASC"); (DESC, "DESC") ]

let test_sort_direction_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_sort_direction
    ~of_json:sort_direction_of_yojson ~equal:equal_sort_direction
    ~to_string:string_of_sort_direction [ ASC; DESC ]

(** {1 Position Sort By Tests} *)

let test_position_sort_by_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_position_sort_by
    [
      (CURRENT, "CURRENT");
      (INITIAL, "INITIAL");
      (TOKENS, "TOKENS");
      (CASHPNL, "CASHPNL");
      (PERCENTPNL, "PERCENTPNL");
      (TITLE, "TITLE");
      (RESOLVING, "RESOLVING");
      (PRICE, "PRICE");
      (AVGPRICE, "AVGPRICE");
    ]

let test_position_sort_by_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_position_sort_by
    ~of_json:position_sort_by_of_yojson ~equal:equal_position_sort_by
    ~to_string:string_of_position_sort_by
    [
      CURRENT;
      INITIAL;
      TOKENS;
      CASHPNL;
      PERCENTPNL;
      TITLE;
      RESOLVING;
      PRICE;
      AVGPRICE;
    ]

(** {1 Filter Type Tests} *)

let test_filter_type_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_filter_type
    [ (CASH, "CASH"); (TOKENS_FILTER, "TOKENS") ]

let test_filter_type_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_filter_type
    ~of_json:filter_type_of_yojson ~equal:equal_filter_type
    ~to_string:string_of_filter_type [ CASH; TOKENS_FILTER ]

(** {1 Activity Sort By Tests} *)

let test_activity_sort_by_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_activity_sort_by
    [ (TIMESTAMP, "TIMESTAMP"); (TOKENS_SORT, "TOKENS"); (CASH_SORT, "CASH") ]

let test_activity_sort_by_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_activity_sort_by
    ~of_json:activity_sort_by_of_yojson ~equal:equal_activity_sort_by
    ~to_string:string_of_activity_sort_by
    [ TIMESTAMP; TOKENS_SORT; CASH_SORT ]

(** {1 Closed Position Sort By Tests} *)

let test_closed_position_sort_by_to_string () =
  Test_utils.test_string_conversions
    ~to_string:string_of_closed_position_sort_by
    [
      (REALIZEDPNL, "REALIZEDPNL");
      (TITLE_SORT, "TITLE");
      (PRICE_SORT, "PRICE");
      (AVGPRICE_SORT, "AVGPRICE");
      (TIMESTAMP_SORT, "TIMESTAMP");
    ]

let test_closed_position_sort_by_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_closed_position_sort_by
    ~of_json:closed_position_sort_by_of_yojson
    ~equal:equal_closed_position_sort_by
    ~to_string:string_of_closed_position_sort_by
    [ REALIZEDPNL; TITLE_SORT; PRICE_SORT; AVGPRICE_SORT; TIMESTAMP_SORT ]

(** {1 Time Period Tests} *)

let test_time_period_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_time_period
    [ (DAY, "DAY"); (WEEK, "WEEK"); (MONTH, "MONTH"); (ALL, "ALL") ]

let test_time_period_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_time_period
    ~of_json:time_period_of_yojson ~equal:equal_time_period
    ~to_string:string_of_time_period [ DAY; WEEK; MONTH; ALL ]

(** {1 Leaderboard Category Tests} *)

let test_leaderboard_category_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_leaderboard_category
    [
      (OVERALL, "OVERALL");
      (POLITICS, "POLITICS");
      (SPORTS, "SPORTS");
      (CRYPTO, "CRYPTO");
      (CULTURE, "CULTURE");
      (MENTIONS, "MENTIONS");
      (WEATHER, "WEATHER");
      (ECONOMICS, "ECONOMICS");
      (TECH, "TECH");
      (FINANCE, "FINANCE");
    ]

let test_leaderboard_category_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_leaderboard_category
    ~of_json:leaderboard_category_of_yojson ~equal:equal_leaderboard_category
    ~to_string:string_of_leaderboard_category
    [
      OVERALL;
      POLITICS;
      SPORTS;
      CRYPTO;
      CULTURE;
      MENTIONS;
      WEATHER;
      ECONOMICS;
      TECH;
      FINANCE;
    ]

(** {1 Leaderboard Order By Tests} *)

let test_leaderboard_order_by_to_string () =
  Test_utils.test_string_conversions ~to_string:string_of_leaderboard_order_by
    [ (PNL, "PNL"); (VOL, "VOL") ]

let test_leaderboard_order_by_roundtrip () =
  Test_utils.test_roundtrip ~to_json:yojson_of_leaderboard_order_by
    ~of_json:leaderboard_order_by_of_yojson ~equal:equal_leaderboard_order_by
    ~to_string:string_of_leaderboard_order_by [ PNL; VOL ]

(** {1 Test Suite} *)

let tests =
  [
    ( "sort_direction",
      [
        ("to_string", `Quick, test_sort_direction_to_string);
        ("roundtrip", `Quick, test_sort_direction_roundtrip);
      ] );
    ( "position_sort_by",
      [
        ("to_string", `Quick, test_position_sort_by_to_string);
        ("roundtrip", `Quick, test_position_sort_by_roundtrip);
      ] );
    ( "filter_type",
      [
        ("to_string", `Quick, test_filter_type_to_string);
        ("roundtrip", `Quick, test_filter_type_roundtrip);
      ] );
    ( "activity_sort_by",
      [
        ("to_string", `Quick, test_activity_sort_by_to_string);
        ("roundtrip", `Quick, test_activity_sort_by_roundtrip);
      ] );
    ( "closed_position_sort_by",
      [
        ("to_string", `Quick, test_closed_position_sort_by_to_string);
        ("roundtrip", `Quick, test_closed_position_sort_by_roundtrip);
      ] );
    ( "time_period",
      [
        ("to_string", `Quick, test_time_period_to_string);
        ("roundtrip", `Quick, test_time_period_roundtrip);
      ] );
    ( "leaderboard_category",
      [
        ("to_string", `Quick, test_leaderboard_category_to_string);
        ("roundtrip", `Quick, test_leaderboard_category_roundtrip);
      ] );
    ( "leaderboard_order_by",
      [
        ("to_string", `Quick, test_leaderboard_order_by_to_string);
        ("roundtrip", `Quick, test_leaderboard_order_by_roundtrip);
      ] );
  ]
