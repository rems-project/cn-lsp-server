(lang dune 2.8)
(using menhir 2.0)
(using cinaps 1.0)
(name cn-lsp-server)

(implicit_transitive_deps false)

(license BSD)
(maintainers "Dhruv Makwana <dcm41@cam.ac.uk>")
(authors
 "Dhruv Makwana <dcm41@cam.ac.uk>")

(source (github rems-project/cn-lsp-server))

(generate_opam_files true)

(package
 (name cn-lsp-server)
 (synopsis "LSP Server for CN")
 (description "An LSP server for CN.")
 (depends
  yojson
  re
  menhir
  uutf
  dune-build-info
  (ppx_yojson_conv_lib (>= "v0.14"))
  (pp (>= 1.1.2))
  (csexp (>= 1.4))
  (result (>= 1.5))
  (ocaml (and (>= 4.12) (< 4.13)))))

