(** Abstract primitive types with built-in validation.

    This module provides type-safe wrappers for Ethereum addresses and hashes.
    Values can only be created through smart constructors that validate the
    input, making it impossible to have invalid addresses or hashes in the
    system. *)

(** {1 Address Module}

    Ethereum address type (0x-prefixed, 40 hex chars, total 42 chars). Pattern:
    [^0x[a-fA-F0-9]\{40\}$] *)
module Address : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create an address with validation. Returns Error if invalid. *)

  val make_exn : string -> t
  (** Create an address with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Hash64 Module}

    64-character hex hash type (0x-prefixed, 64 hex chars, total 66 chars).
    Pattern: [^0x[a-fA-F0-9]\{64\}$] *)
module Hash64 : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create a hash64 with validation. Returns Error if invalid. *)

  val make_exn : string -> t
  (** Create a hash64 with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Hash Module}

    Variable-length hex hash type (0x-prefixed, any number of hex chars). Used
    for signatures and other variable-length hex data. *)
module Hash : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create a hash with validation. Returns Error if invalid. *)

  val make_exn : string -> t
  (** Create a hash with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Token_id Module}

    ERC1155 token ID (numeric string representing uint256). Token IDs must be
    non-empty strings containing only digits 0-9. *)
module Token_id : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create a token_id with validation. Returns Error if not numeric. *)

  val make_exn : string -> t
  (** Create a token_id with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Signature Module}

    Hex-encoded cryptographic signature (0x-prefixed, variable length). This is
    a distinct type from Hash to prevent accidentally mixing signatures with
    other hex data. *)
module Signature : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create a signature with validation. Returns Error if invalid hex. *)

  val make_exn : string -> t
  (** Create a signature with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Request_id Module}

    UUID for RFQ requests. This is a distinct type from Quote_id and Trade_id to
    prevent accidentally mixing different ID kinds. *)
module Request_id : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create a request_id with validation. Returns Error if empty. *)

  val make_exn : string -> t
  (** Create a request_id with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Quote_id Module}

    UUID for RFQ quotes. This is a distinct type from Request_id and Trade_id to
    prevent accidentally mixing different ID kinds. *)
module Quote_id : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create a quote_id with validation. Returns Error if empty. *)

  val make_exn : string -> t
  (** Create a quote_id with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Trade_id Module}

    UUID for trades. This is a distinct type from Request_id and Quote_id to
    prevent accidentally mixing different ID kinds. *)
module Trade_id : sig
  type t = private string

  val make : string -> (t, string) result
  (** Create a trade_id with validation. Returns Error if empty. *)

  val make_exn : string -> t
  (** Create a trade_id with validation. Raises on invalid input. *)

  val unsafe_of_string : string -> t
  (** Create from string without validation. Use only for trusted sources. *)

  val to_string : t -> string
  (** Convert to string. *)

  val pp : Format.formatter -> t -> unit
  (** Pretty printer for Format. *)

  val equal : t -> t -> bool
  (** Equality comparison. *)

  val of_yojson : Yojson.Safe.t -> (t, string) result
  (** JSON deserialization with validation. *)

  val of_yojson_exn : Yojson.Safe.t -> t
  (** JSON deserialization, raises on invalid. *)

  val to_yojson : t -> Yojson.Safe.t
  (** JSON serialization. *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** JSON serialization (ppx_yojson_conv compatibility). *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** JSON deserialization (ppx_yojson_conv compatibility). *)
end

(** {1 Timestamps}

    ISO 8601 timestamp type (e.g., "2023-11-07T05:31:56Z"). Used for date/time
    parameters in API requests. *)
module Timestamp : sig
  type t
  (** An ISO 8601 timestamp (e.g., "2023-11-07T05:31:56Z") *)

  val of_string : string -> t option
  (** Parse from ISO 8601 string *)

  val of_string_exn : string -> t
  (** Parse from ISO 8601 string, raises on invalid format *)

  val to_string : t -> string
  (** Convert to ISO 8601 string *)

  val to_ptime : t -> Ptime.t
  (** Get the underlying Ptime.t *)

  val of_ptime : Ptime.t -> t
  (** Create from Ptime.t *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** Parse from JSON string *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** Convert to JSON string *)

  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Side Enum}

    Trade side (Buy/Sell) shared across Data API and CLOB API. *)
module Side : sig
  type t = Buy | Sell  (** Buy or Sell side for trades and orders *)

  val to_string : t -> string
  (** Convert to string ("BUY" or "SELL") *)

  val of_string : string -> t
  (** Parse from string, raises on invalid input *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** Parse from JSON string *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** Convert to JSON string *)

  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Sort Direction Enum}

    Sort direction (Asc/Desc) shared across Data API and RFQ API. *)
module Sort_dir : sig
  type t = Asc | Desc  (** Ascending or Descending sort order *)

  val to_string : t -> string
  (** Convert to string ("ASC" or "DESC") *)

  val of_string : string -> t
  (** Parse from string, raises on invalid input *)

  val of_string_opt : string -> t option
  (** Parse from string, returns None on invalid input *)

  val t_of_yojson : Yojson.Safe.t -> t
  (** Parse from JSON string *)

  val yojson_of_t : t -> Yojson.Safe.t
  (** Convert to JSON string *)

  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
end

(** {1 Error Types}

    Structured error types for API operations. These are shared across all API
    clients (CLOB, Gamma, Data, RFQ). Re-exported from Client. *)

type http_error = Client.http_error = {
  status : int;
  body : string;
  message : string;
}
(** HTTP error with status code, raw body, and extracted message. *)

type parse_error = Client.parse_error = { context : string; message : string }
(** Parse error with context and message. *)

type network_error = Client.network_error = { message : string }
(** Network-level error (connection failed, timeout, etc.). *)

type api_error = Client.error =
  | Http_error of http_error
  | Parse_error of parse_error
  | Network_error of network_error
      (** Structured error type for all API errors. *)

val api_error_to_string : api_error -> string
(** Convert error to human-readable string. *)

val pp_api_error : Format.formatter -> api_error -> unit
(** Pretty printer for errors. *)
