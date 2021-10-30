(lang dune 2.8)
(using menhir 2.0)
(using cinaps 1.0)
(name cn-lsp-server)

(implicit_transitive_deps false)

(license "Mixed BSD and ISC")
(maintainers "Dhruv Makwana <dcm41@cam.ac.uk>")
(authors
 "Dhruv Makwana <dcm41@cam.ac.uk>"
 "Andrey Popp <8mayday@gmail.com>"
 "Rusty Key <iam@stfoo.ru>"
 "Louis Roché <louis@louisroche.net>"
 "Oleksiy Golovko <alexei.golovko@gmail.com>"
 "Rudi Grinberg <me@rgrinberg.com>"
 "Sacha Ayoun <sachaayoun@gmail.com>"
 "cannorin <cannorin@gmail.com>"
 "Ulugbek Abdullaev <ulugbekna@gmail.com>"
 "Thibaut Mattio <thibaut.mattio@gmail.com>"
 "Max Lantas <mnxndev@outlook.com>")

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
  cmdliner
  (ppx_yojson_conv_lib (>= "v0.14"))
  (pp (>= 1.1.2))
  (csexp (>= 1.4))
  (result (>= 1.5))
  (ocaml (and (>= 4.12) (< 4.13)))))

