(** High-level WebSocket client for Polymarket.

    Provides typed streaming access to Market and User channels.

    {1 Usage Example}

    {[
      Eio_main.run @@ fun env ->
      Eio.Switch.run @@ fun sw ->
      let net = Eio.Stdenv.net env in

      (* Connect to market channel *)
      let market =
        Wss.Market.connect ~sw ~net ~asset_ids:[ "109681959945973..." ] ()
      in

      (* Consume messages *)
      let rec loop () =
        match Eio.Stream.take (Wss.Market.stream market) with
        | Types.Market (Book book) ->
            Printf.printf "Book for %s: %d bids, %d asks\n" book.asset_id
              (List.length book.bids) (List.length book.asks);
            loop ()
        | Types.Market (Price_change pc) ->
            Printf.printf "Price change in %s\n" pc.market;
            loop ()
        | _ -> loop ()
      in
      loop ()
    ]} *)

(** {1 Market Channel Client}

    Public channel for order book updates and price changes. *)

module Market : sig
  type t
  (** Market channel connection handle. *)

  val connect :
    sw:Eio.Switch.t -> net:Eio_unix.Net.t -> asset_ids:string list -> unit -> t
  (** Connect to the market channel and subscribe to the given asset IDs.

      The connection runs in background fibers and automatically reconnects on
      disconnection. Messages are parsed and delivered to the stream.

      @param sw Eio switch for managing connection lifecycle
      @param net Network capability
      @param asset_ids List of token IDs to subscribe to *)

  val stream : t -> Types.message Eio.Stream.t
  (** Get the stream of parsed messages.

      Messages are of type [Types.Market] containing:
      - [Book] - Full orderbook snapshot
      - [Price_change] - Incremental price updates
      - [Tick_size_change] - Tick size changes
      - [Last_trade_price] - Trade price updates *)

  val subscribe : t -> asset_ids:string list -> unit
  (** Subscribe to additional asset IDs. *)

  val unsubscribe : t -> asset_ids:string list -> unit
  (** Unsubscribe from asset IDs. *)

  val close : t -> unit
  (** Close the connection. *)
end

(** {1 User Channel Client}

    Authenticated channel for user-specific order and trade updates. *)

module User : sig
  type t
  (** User channel connection handle. *)

  val connect :
    sw:Eio.Switch.t ->
    net:Eio_unix.Net.t ->
    credentials:Polymarket_clob.Auth_types.credentials ->
    markets:string list ->
    unit ->
    t
  (** Connect to the user channel with authentication.

      The connection runs in background fibers and automatically reconnects on
      disconnection. Messages are parsed and delivered to the stream.

      @param sw Eio switch for managing connection lifecycle
      @param net Network capability
      @param credentials API credentials (api_key, secret, passphrase)
      @param markets List of market (condition) IDs to filter events *)

  val stream : t -> Types.message Eio.Stream.t
  (** Get the stream of parsed messages.

      Messages are of type [Types.User] containing:
      - [Trade] - Trade events (MATCHED, MINED, CONFIRMED, etc.)
      - [Order] - Order events (PLACEMENT, UPDATE, CANCELLATION) *)

  val close : t -> unit
  (** Close the connection. *)
end
