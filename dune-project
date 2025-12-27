(lang dune 3.16)

(name polymarket)

(version 0.1.0)

(generate_opam_files true)

(source
 (github haut/polymarket))

(authors "Richard <rkhaut1@gmail.com>")

(maintainers "Richard <rkhaut1@gmail.com>")

(license MIT)

(documentation https://haut.github.io/polymarket)

(package
 (name polymarket)
 (synopsis "OCaml client library for the Polymarket prediction market API")
 (description
  "A comprehensive OCaml client for interacting with Polymarket's CLOB (Central Limit Order Book) and Gamma APIs. Supports market data retrieval, order management, and real-time WebSocket subscriptions.")
 (depends
  (ocaml (>= 5.1))
  (dune (>= 3.16))
  (yojson (>= 2.0))
  (ppx_yojson_conv (>= 0.16))
  (ppx_deriving (>= 5.2))
  (eio_main (>= 1.0))
  (uri (>= 4.0))
  (piaf (>= 0.2))
  (digestif (>= 1.2))
  (secp256k1-internal (>= 0.4))
  (base64 (>= 3.5))
  (hex (>= 1.5))
  (logs (>= 0.7))
  (fmt (>= 0.9))
  (ptime (>= 1.0))
  (alcotest (and (>= 1.7) :with-test)))
 (tags
  (polymarket prediction-market blockchain polygon api-client trading)))
