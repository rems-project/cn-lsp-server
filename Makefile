##############################################################################
#  The following parts of CN LSP Server contain new code released under the  #
#  BSD 2-Clause License:                                                     #
#  * `src/cn.ml`                                                             #
#                                                                            #
#  Copyright (c) 2021 Dhruv Makwana                                          #
#  All rights reserved.                                                      #
#                                                                            #
#  This software was developed by the University of Cambridge Computer       #
#  Laboratory as part of the Rigorous Engineering of Mainstream Systems      #
#  (REMS) project. This project has been partly funded by an EPSRC           #
#  Doctoral Training studentship. This project has been partly funded by     #
#  Google. This project has received funding from the European Research      #
#  Council (ERC) under the European Union's Horizon 2020 research and        #
#  innovation programme (grant agreement No 789108, Advanced Grant           #
#  ELVER).                                                                   #
#                                                                            #
#  BSD 2-Clause License                                                      #
#                                                                            #
#  Redistribution and use in source and binary forms, with or without        #
#  modification, are permitted provided that the following conditions        #
#  are met:                                                                  #
#  1. Redistributions of source code must retain the above copyright         #
#     notice, this list of conditions and the following disclaimer.          #
#  2. Redistributions in binary form must reproduce the above copyright      #
#     notice, this list of conditions and the following disclaimer in        #
#     the documentation and/or other materials provided with the             #
#     distribution.                                                          #
#                                                                            #
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''        #
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED         #
#  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A           #
#  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR       #
#  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,              #
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT          #
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF          #
#  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND       #
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,        #
#  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT        #
#  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF        #
#  SUCH DAMAGE.                                                              #
#                                                                            #
#  All other parts involve adapted code, with the new code subject to the    #
#  above BSD 2-Clause licence and the original code subject to its ISC       #
#  licence.                                                                  #
#                                                                            #
#  ISC License                                                               #
#                                                                            #
#  Copyright (X) 2018-2019, the [ocaml-lsp                                   #
#  contributors](https://github.com/ocaml/ocaml-lsp/graphs/contributors)     #
#                                                                            #
#  Permission to use, copy, modify, and distribute this software for any     #
#  purpose with or without fee is hereby granted, provided that the above    #
#  copyright notice and this permission notice appear in all copies.         #
#                                                                            #
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  #
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          #
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   #
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    #
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     #
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   #
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            #
##############################################################################

.DEFAULT_GOAL := all

TEST_E2E_DIR = test/e2e

$(TEST_E2E_DIR)/node_modules:
	cd $(TEST_E2E_DIR) && yarn install

-include Makefile.dev

.PHONY: all
all:
	dune build @all

.PHONY: install
install: ## Install the packages on the system
	dune build @install && dune install

.PHONY: lock
lock: ## Generate the lock files
	opam lock -y .

.PHONY: promote
promote:
	dune promote

.PHONY: check
check:
	dune build @check

.PHONY: test-e2e
test-e2e: $(TEST_E2E_DIR)/node_modules ## Run the template integration tests
	dune build @install && cd $(TEST_E2E_DIR) && dune exec -- yarn test --testTimeout 15000

.PHONY: promote-e2e
promote-e2e: $(TEST_E2E_DIR)/node_modules
	dune build @install && cd $(TEST_E2E_DIR) && dune exec -- yarn run promote

.PHONY: test
test: test-e2e

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	dune clean

.PHONY: fmt
fmt: ## Format the codebase with ocamlformat
	dune build @fmt --auto-promote
	cd $(TEST_E2E_DIR) && yarn fmt

.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	dune build --watch

.PHONY: utop
utop: ## Run a REPL and link with the project's libraries
	dune utop . -- -implicit-bindings

.PHONY: release
release: ## Release on Opam
	dune-release distrib --skip-build --skip-lint --skip-tests --include-submodules
	# See https://github.com/ocamllabs/dune-release/issues/206
	DUNE_RELEASE_DELEGATE=github-dune-release-delegate dune-release publish distrib --verbose
	dune-release opam pkg
	dune-release opam submit

.PHONY: clear-header

clear-header:
	headache -c etc/headache_config -r \
	    `find src -name '*.ml' ! -path 'src/cn.ml'` \
	    `find src -name '*.ml*'` \
	    Makefile .github/workflows/build-and-test.yml .editorconfig .gitignore .gitmodules README.md \
	    `find . -name 'dune' ! -path './_build/*' ! -path './submodules/*' ! -path './.git/*'` \
	    `find test -name '*.js' ! -path 'test/e2e/node_modules/*'` \
	    `find test -name '*.ts' ! -path 'test/e2e/node_modules/*'` \
	    src/cn.ml

.PHONY: apply-header

apply-header:
	headache -c etc/headache_config -h LICENCE \
	    `find src -name '*.ml' ! -path 'src/cn.ml'` \
	    `find src -name '*.ml*'` \
	    Makefile .github/workflows/build-and-test.yml .editorconfig .gitignore .gitmodules README.md \
	    `find . -name 'dune' ! -path './_build/*' ! -path './submodules/*' ! -path './.git/*'` \
	    `find test -name '*.js' ! -path 'test/e2e/node_modules/*'` \
	    `find test -name '*.ts' ! -path 'test/e2e/node_modules/*'`
	headache -c etc/headache_config -h etc/BSD-2-Clause src/cn.ml

