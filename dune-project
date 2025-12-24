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
  (cohttp-eio (>= 6.0))
  (eio_main (>= 1.0))
  (uri (>= 4.0))
  (tls (>= 1.0))
  (tls-eio (>= 1.0))
  (ca-certs (>= 1.0))
  (mirage-crypto-rng-eio (>= 1.0))
  (logs (>= 0.7))
  (fmt (>= 0.9))
  (alcotest (and (>= 1.7) :with-test)))
 (tags
  (polymarket prediction-market blockchain polygon api-client trading)))
