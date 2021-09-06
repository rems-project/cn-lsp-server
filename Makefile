##############################################################################
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

.PHONY: nix/opam-selection.nix
nix/opam-selection.nix:
	nix-shell -A resolve default.nix

.PHONY: clear-header

clear-header:
	headache -c etc/headache_config -r \
	    `find src -name '*.ml'` \
	    `find src -name '*.ml*'` \
	    Makefile \
	    dune \
	    `find test -name '*.js' ! -path 'test/e2e/node_modules/*'` \
	    `find test -name '*.ts' ! -path 'test/e2e/node_modules/*'`

.PHONY: apply-header

apply-header:
	headache -c etc/headache_config -h etc/ISC \
	    `find src -name '*.ml' ! -path 'src/cn.ml'` \
	    `find src -name '*.ml*'` \
	    Makefile \
	    dune \
	    `find test -name '*.js' ! -path 'test/e2e/node_modules/*'` \
	    `find test -name '*.ts' ! -path 'test/e2e/node_modules/*'`
	headache -c etc/headache_config -h etc/BSD-2-Clause src/cn.ml

