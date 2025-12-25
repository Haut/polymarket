(** Authentication types for the CLOB API.

    This module defines types for API credentials and authentication endpoint
    request/response types. *)

(** {1 Credentials} *)

type credentials = {
  api_key : string;
  secret : string;  (** Base64-encoded secret *)
  passphrase : string;
}
(** API credentials for L2 authentication. *)

val pp_credentials : Format.formatter -> credentials -> unit
val show_credentials : credentials -> string
val equal_credentials : credentials -> credentials -> bool

(** {1 API Key Creation} *)

type api_key_response = {
  api_key : string;
  secret : string;
  passphrase : string;
}
(** Response from POST /auth/api-key (create new credentials). *)

val api_key_response_of_yojson : Yojson.Safe.t -> api_key_response
val yojson_of_api_key_response : api_key_response -> Yojson.Safe.t
val pp_api_key_response : Format.formatter -> api_key_response -> unit
val show_api_key_response : api_key_response -> string
val equal_api_key_response : api_key_response -> api_key_response -> bool

(** {1 API Key Derivation} *)

type derive_api_key_response = {
  api_key : string;
  secret : string;
  passphrase : string;
}
(** Response from GET /auth/derive-api-key (derive existing credentials). *)

val derive_api_key_response_of_yojson : Yojson.Safe.t -> derive_api_key_response
val yojson_of_derive_api_key_response : derive_api_key_response -> Yojson.Safe.t

val pp_derive_api_key_response :
  Format.formatter -> derive_api_key_response -> unit

val show_derive_api_key_response : derive_api_key_response -> string

val equal_derive_api_key_response :
  derive_api_key_response -> derive_api_key_response -> bool

(** {1 Conversion} *)

val credentials_of_api_key_response : api_key_response -> credentials
(** Convert API key response to credentials. *)

val credentials_of_derive_response : derive_api_key_response -> credentials
(** Convert derive response to credentials. *)
