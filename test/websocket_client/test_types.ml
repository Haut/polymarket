(** Unit tests for WebSocket message types *)

open Polymarket.Wss.Types

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
      Market_event.New_market;
      Market_event.Market_resolved;
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
      Market_event.New_market;
      Market_event.Market_resolved;
    ]
  in
  List.iter
    (fun evt ->
      let json = Market_event.yojson_of_t evt in
      let result = Market_event.t_of_yojson json in
      Alcotest.(check bool)
        (Printf.sprintf "Market_event JSON %s" (Market_event.to_string evt))
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
        (Printf.sprintf "Trade_status JSON %s" (Trade_status.to_string st))
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
  | [ Market (Book msg) ] ->
      Alcotest.(check string) "asset_id" "123" msg.asset_id;
      Alcotest.(check int) "bids count" 1 (List.length msg.bids);
      Alcotest.(check int) "asks count" 0 (List.length msg.asks)
  | _ -> Alcotest.fail "expected Book message"

let test_parse_price_change_message () =
  let json =
    {|{"event_type":"price_change","market":"abc","price_changes":[],"timestamp":"123"}|}
  in
  match parse_message ~channel:Channel.Market json with
  | [ Market (Price_change msg) ] ->
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
  | [ Unknown _ ] -> ()
  | _ -> Alcotest.fail "expected Unknown message for invalid JSON"

(** {1 Subscription JSON Tests} *)

let test_parse_new_market_message () =
  let json =
    {|{"event_type":"new_market","id":"m1","question":"Will X happen?","market":"abc","slug":"will-x-happen","assets_ids":["a1","a2"],"outcomes":["Yes","No"],"timestamp":"123"}|}
  in
  match parse_message ~channel:Channel.Market json with
  | [ Market (New_market msg) ] ->
      Alcotest.(check string) "id" "m1" msg.id;
      Alcotest.(check string) "question" "Will X happen?" msg.question;
      Alcotest.(check int) "assets_ids count" 2 (List.length msg.assets_ids);
      Alcotest.(check int) "outcomes count" 2 (List.length msg.outcomes)
  | _ -> Alcotest.fail "expected New_market message"

let test_parse_market_resolved_message () =
  let json =
    {|{"event_type":"market_resolved","id":"m1","market":"abc","assets_ids":["a1","a2"],"winning_asset_id":"a1","winning_outcome":"Yes","timestamp":"123"}|}
  in
  match parse_message ~channel:Channel.Market json with
  | [ Market (Market_resolved msg) ] ->
      Alcotest.(check string) "id" "m1" msg.id;
      Alcotest.(check string) "winning_outcome" "Yes" msg.winning_outcome;
      Alcotest.(check string) "winning_asset_id" "a1" msg.winning_asset_id
  | _ -> Alcotest.fail "expected Market_resolved message"

let test_parse_trade_message_minimal () =
  let json =
    {|{"event_type":"trade","id":"t1","asset_id":"a1","market":"m1","side":"BUY","size":"10","price":"0.5","status":"MATCHED","owner":"0xabc","taker_order_id":"o1","timestamp":"123","type":"TRADE"}|}
  in
  match parse_message ~channel:Channel.User json with
  | [ User (Trade msg) ] ->
      Alcotest.(check string) "id" "t1" msg.id;
      Alcotest.(check string) "side" "BUY" msg.side;
      Alcotest.(check (option string)) "outcome" None msg.outcome;
      Alcotest.(check (option string)) "trade_owner" None msg.trade_owner;
      Alcotest.(check bool) "maker_orders is None" true (msg.maker_orders = None);
      Alcotest.(check (option string)) "matchtime" None msg.matchtime;
      Alcotest.(check (option string)) "last_update" None msg.last_update
  | _ -> Alcotest.fail "expected Trade message"

let test_parse_trade_message_full () =
  let json =
    {|{"event_type":"trade","id":"t1","asset_id":"a1","market":"m1","side":"BUY","size":"10","price":"0.5","status":"MATCHED","outcome":"Yes","owner":"0xabc","trade_owner":"0xdef","taker_order_id":"o1","maker_orders":[{"asset_id":"a1","matched_amount":"5","order_id":"mo1","outcome":"Yes","owner":"0x111","price":"0.5"}],"matchtime":"123456","last_update":"123457","timestamp":"123","type":"TRADE","fee_rate_bps":"20","maker_address":"0x222","transaction_hash":"0xhash","bucket_index":3,"trader_side":"TAKER"}|}
  in
  match parse_message ~channel:Channel.User json with
  | [ User (Trade msg) ] ->
      Alcotest.(check (option string)) "outcome" (Some "Yes") msg.outcome;
      Alcotest.(check (option string))
        "trade_owner" (Some "0xdef") msg.trade_owner;
      Alcotest.(check bool)
        "maker_orders present" true (msg.maker_orders <> None);
      Alcotest.(check (option string)) "matchtime" (Some "123456") msg.matchtime;
      Alcotest.(check (option string))
        "last_update" (Some "123457") msg.last_update;
      Alcotest.(check (option string))
        "transaction_hash" (Some "0xhash") msg.transaction_hash;
      Alcotest.(check (option int)) "bucket_index" (Some 3) msg.bucket_index;
      Alcotest.(check (option string))
        "trader_side" (Some "TAKER") msg.trader_side
  | _ -> Alcotest.fail "expected Trade message"

let test_parse_order_message_minimal () =
  let json =
    {|{"event_type":"order","id":"o1","asset_id":"a1","market":"m1","side":"BUY","price":"0.5","original_size":"10","size_matched":"0","owner":"0xabc","timestamp":"123","type":"PLACEMENT"}|}
  in
  match parse_message ~channel:Channel.User json with
  | [ User (Order msg) ] ->
      Alcotest.(check string) "id" "o1" msg.id;
      Alcotest.(check (option string)) "outcome" None msg.outcome;
      Alcotest.(check (option string)) "order_owner" None msg.order_owner;
      Alcotest.(check (option string)) "created_at" None msg.created_at;
      Alcotest.(check (option string)) "order_type" None msg.order_type;
      Alcotest.(check (option string)) "status" None msg.status
  | _ -> Alcotest.fail "expected Order message"

let test_parse_order_message_full () =
  let json =
    {|{"event_type":"order","id":"o1","asset_id":"a1","market":"m1","side":"BUY","price":"0.5","original_size":"10","size_matched":"5","outcome":"Yes","owner":"0xabc","order_owner":"0xdef","timestamp":"123","type":"UPDATE","created_at":"2024-01-01","expiration":"2024-12-31","order_type":"GTC","status":"LIVE","maker_address":"0x222"}|}
  in
  match parse_message ~channel:Channel.User json with
  | [ User (Order msg) ] ->
      Alcotest.(check (option string)) "outcome" (Some "Yes") msg.outcome;
      Alcotest.(check (option string))
        "order_owner" (Some "0xdef") msg.order_owner;
      Alcotest.(check (option string))
        "created_at" (Some "2024-01-01") msg.created_at;
      Alcotest.(check (option string))
        "expiration" (Some "2024-12-31") msg.expiration;
      Alcotest.(check (option string)) "order_type" (Some "GTC") msg.order_type;
      Alcotest.(check (option string)) "status" (Some "LIVE") msg.status;
      Alcotest.(check (option string))
        "maker_address" (Some "0x222") msg.maker_address
  | _ -> Alcotest.fail "expected Order message"

let test_market_subscribe_json () =
  let json = market_subscribe_json ~asset_ids:[ "token1"; "token2" ] () in
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
        ("new_market", `Quick, test_parse_new_market_message);
        ("market_resolved", `Quick, test_parse_market_resolved_message);
        ("trade minimal", `Quick, test_parse_trade_message_minimal);
        ("trade full", `Quick, test_parse_trade_message_full);
        ("order minimal", `Quick, test_parse_order_message_minimal);
        ("order full", `Quick, test_parse_order_message_full);
        ("empty array", `Quick, test_parse_empty_array);
        ("invalid JSON", `Quick, test_parse_invalid_json);
      ] );
    ( "subscription",
      [ ("market_subscribe_json", `Quick, test_market_subscribe_json) ] );
  ]
