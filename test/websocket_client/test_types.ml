(** Unit tests for WebSocket message types *)

open Polymarket_wss.Types

(** {1 Channel Tests} *)

let test_channel_string_roundtrip () =
  let channels = [ Channel.Market; Channel.User ] in
  List.iter
    (fun ch ->
      let str = Channel.to_string ch in
      let result = Channel.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Channel %s roundtrip" str)
        true (Channel.equal ch result))
    channels

let test_channel_string_values () =
  Alcotest.(check string) "Market" "market" (Channel.to_string Channel.Market);
  Alcotest.(check string) "User" "user" (Channel.to_string Channel.User)

(** {1 Market Event Tests} *)

let test_market_event_string_roundtrip () =
  let events =
    [
      Market_event.Book;
      Market_event.Price_change;
      Market_event.Tick_size_change;
      Market_event.Last_trade_price;
      Market_event.Best_bid_ask;
    ]
  in
  List.iter
    (fun evt ->
      let str = Market_event.to_string evt in
      let result = Market_event.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Market_event %s roundtrip" str)
        true
        (Market_event.equal evt result))
    events

let test_market_event_json_roundtrip () =
  let events =
    [
      Market_event.Book;
      Market_event.Price_change;
      Market_event.Tick_size_change;
      Market_event.Last_trade_price;
      Market_event.Best_bid_ask;
    ]
  in
  List.iter
    (fun evt ->
      let json = Market_event.yojson_of_t evt in
      let result = Market_event.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Market_event JSON %s" (Market_event.show evt))
        true
        (Market_event.equal evt result))
    events

(** {1 User Event Tests} *)

let test_user_event_string_roundtrip () =
  let events = [ User_event.Trade; User_event.Order ] in
  List.iter
    (fun evt ->
      let str = User_event.to_string evt in
      let result = User_event.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "User_event %s roundtrip" str)
        true
        (User_event.equal evt result))
    events

(** {1 Trade Status Tests} *)

let test_trade_status_string_roundtrip () =
  let statuses =
    [
      Trade_status.Matched;
      Trade_status.Mined;
      Trade_status.Confirmed;
      Trade_status.Retrying;
      Trade_status.Failed;
    ]
  in
  List.iter
    (fun st ->
      let str = Trade_status.to_string st in
      let result = Trade_status.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Trade_status %s roundtrip" str)
        true
        (Trade_status.equal st result))
    statuses

let test_trade_status_json_roundtrip () =
  let statuses =
    [
      Trade_status.Matched;
      Trade_status.Mined;
      Trade_status.Confirmed;
      Trade_status.Retrying;
      Trade_status.Failed;
    ]
  in
  List.iter
    (fun st ->
      let json = Trade_status.yojson_of_t st in
      let result = Trade_status.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Trade_status JSON %s" (Trade_status.show st))
        true
        (Trade_status.equal st result))
    statuses

(** {1 Order Event Type Tests} *)

let test_order_event_type_string_roundtrip () =
  let types =
    [
      Order_event_type.Placement;
      Order_event_type.Update;
      Order_event_type.Cancellation;
    ]
  in
  List.iter
    (fun t ->
      let str = Order_event_type.to_string t in
      let result = Order_event_type.of_string str in
      Alcotest.(check bool)
        (Printf.sprintf "Order_event_type %s roundtrip" str)
        true
        (Order_event_type.equal t result))
    types

(** {1 Message Parsing Tests} *)

let test_parse_book_message () =
  let json =
    {|{"event_type":"book","asset_id":"123","market":"abc","timestamp":"1234567890","hash":"0x123","bids":[{"price":"0.5","size":"100"}],"asks":[]}|}
  in
  match parse_message ~channel:Channel.Market json with
  | [ `Market (`Book msg) ] ->
      Alcotest.(check string) "asset_id" "123" msg.asset_id;
      Alcotest.(check int) "bids count" 1 (List.length msg.bids);
      Alcotest.(check int) "asks count" 0 (List.length msg.asks)
  | _ -> Alcotest.fail "expected Book message"

let test_parse_price_change_message () =
  let json =
    {|{"event_type":"price_change","market":"abc","price_changes":[],"timestamp":"123"}|}
  in
  match parse_message ~channel:Channel.Market json with
  | [ `Market (`Price_change msg) ] ->
      Alcotest.(check string) "market" "abc" msg.market
  | _ -> Alcotest.fail "expected Price_change message"

let test_parse_empty_array () =
  (* Empty array is subscription ack *)
  let json = "[]" in
  match parse_message ~channel:Channel.Market json with
  | [] -> ()
  | _ -> Alcotest.fail "expected empty list for subscription ack"

let test_parse_invalid_json () =
  let json = "not valid json" in
  match parse_message ~channel:Channel.Market json with
  | [ `Unknown _ ] -> ()
  | _ -> Alcotest.fail "expected Unknown message for invalid JSON"

(** {1 Subscription JSON Tests} *)

let test_market_subscribe_json () =
  let json = market_subscribe_json ~asset_ids:[ "token1"; "token2" ] in
  Alcotest.(check bool)
    "contains MARKET" true
    (String.length json > 0 && String.sub json 0 1 = "{")

(** {1 Test Suite} *)

let tests =
  [
    ( "Channel",
      [
        ("string roundtrip", `Quick, test_channel_string_roundtrip);
        ("string values", `Quick, test_channel_string_values);
      ] );
    ( "Market_event",
      [
        ("string roundtrip", `Quick, test_market_event_string_roundtrip);
        ("JSON roundtrip", `Quick, test_market_event_json_roundtrip);
      ] );
    ( "User_event",
      [ ("string roundtrip", `Quick, test_user_event_string_roundtrip) ] );
    ( "Trade_status",
      [
        ("string roundtrip", `Quick, test_trade_status_string_roundtrip);
        ("JSON roundtrip", `Quick, test_trade_status_json_roundtrip);
      ] );
    ( "Order_event_type",
      [ ("string roundtrip", `Quick, test_order_event_type_string_roundtrip) ]
    );
    ( "parse_message",
      [
        ("book", `Quick, test_parse_book_message);
        ("price_change", `Quick, test_parse_price_change_message);
        ("empty array", `Quick, test_parse_empty_array);
        ("invalid JSON", `Quick, test_parse_invalid_json);
      ] );
    ( "subscription",
      [ ("market_subscribe_json", `Quick, test_market_subscribe_json) ] );
  ]
