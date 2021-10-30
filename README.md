<!--                                                                            -->
<!--  The following parts of CN LSP Server contain new code released under the  -->
<!--  BSD 2-Clause License:                                                     -->
<!--  * `src/cn.ml`                                                             -->
<!--                                                                            -->
<!--  Copyright (c) 2021 Dhruv Makwana                                          -->
<!--  All rights reserved.                                                      -->
<!--                                                                            -->
<!--  This software was developed by the University of Cambridge Computer       -->
<!--  Laboratory as part of the Rigorous Engineering of Mainstream Systems      -->
<!--  (REMS) project. This project has been partly funded by an EPSRC           -->
<!--  Doctoral Training studentship. This project has been partly funded by     -->
<!--  Google. This project has received funding from the European Research      -->
<!--  Council (ERC) under the European Union's Horizon 2020 research and        -->
<!--  innovation programme (grant agreement No 789108, Advanced Grant           -->
<!--  ELVER).                                                                   -->
<!--                                                                            -->
<!--  BSD 2-Clause License                                                      -->
<!--                                                                            -->
<!--  Redistribution and use in source and binary forms, with or without        -->
<!--  modification, are permitted provided that the following conditions        -->
<!--  are met:                                                                  -->
<!--  1. Redistributions of source code must retain the above copyright         -->
<!--     notice, this list of conditions and the following disclaimer.          -->
<!--  2. Redistributions in binary form must reproduce the above copyright      -->
<!--     notice, this list of conditions and the following disclaimer in        -->
<!--     the documentation and/or other materials provided with the             -->
<!--     distribution.                                                          -->
<!--                                                                            -->
<!--  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''        -->
<!--  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED         -->
<!--  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A           -->
<!--  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR       -->
<!--  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,              -->
<!--  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT          -->
<!--  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF          -->
<!--  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND       -->
<!--  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,        -->
<!--  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT        -->
<!--  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF        -->
<!--  SUCH DAMAGE.                                                              -->
<!--                                                                            -->
<!--  All other parts involve adapted code, with the new code subject to the    -->
<!--  above BSD 2-Clause licence and the original code subject to its ISC       -->
<!--  licence.                                                                  -->
<!--                                                                            -->
<!--  ISC License                                                               -->
<!--                                                                            -->
<!--  Copyright (X) 2018-2019, the [ocaml-lsp                                   -->
<!--  contributors](https://github.com/ocaml/ocaml-lsp/graphs/contributors)     -->
<!--                                                                            -->
<!--  Permission to use, copy, modify, and distribute this software for any     -->
<!--  purpose with or without fee is hereby granted, provided that the above    -->
<!--  copyright notice and this permission notice appear in all copies.         -->
<!--                                                                            -->
<!--  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  -->
<!--  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          -->
<!--  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   -->
<!--  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    -->
<!--  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     -->
<!--  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   -->
<!--  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            -->
<!--                                                                            -->

# CN LSP Server

CN LSP Server is a language server for the CN type system for the C programming language.

[![Build](https://github.com/rems-project/cn-lsp-server/workflows/Build%20and%20Test/badge.svg)](https://github.com/rems-project/cn-lsp-server/actions)

## Installation

We recommend to install the language server by cloning the repo and typing:

```sh
$ git clone --recurse-submodules http://github.com/rems-project/cn-lsp-server.git
$ cd cn-lsp-server
$ make all
```

<!--
We recommend to install the language server via a package manager such as
[opam](http://github.com/ocaml/opam) or [esy](https://github.com/esy/esy).

### Opam

To install the language server in the currently used opam [switch](https://opam.ocaml.org/doc/Manual.html#Switches):

```sh
$ opam install cn-lsp-server
```

*Note:* you will need to install `cn-lsp-server` in every switch where you would like
to use it.

### Esy

To add the language server to an esy project, run in terminal:

```
$ esy add @opam/cn-lsp-server
```
-->

## Usage

Once `cn-lsp-server` is installed, the executable is called `cnlsp`. For now,
the server can only be used through the standard input (`stdin`) and output
(`stdout`) file descriptors.

For an example of usage of the server in a reference LSP client, see the VS Code extension
[cn-lsp-client](https://github.com/rems-project/cn-lsp-client).

## Features

The server supports the following LSP requests:

- [ ] `textDocument/completion`
- [ ] `completionItem/resolve`
- [ ] `textdocument/hover`
- [ ] `textDocument/signatureHelp`
- [ ] `textDocument/declaration`
- [ ] `textDocument/definition`
- [ ] `textDocument/typeDefinition`
- [ ] `textDocument/implementation`
- [ ] `textDocument/codeLens`
- [ ] `textDocument/documentHighlight`
- [ ] `textDocument/documentSymbol`
- [ ] `textDocument/references`
- [ ] `textDocument/documentColor`
- [ ] `textDocument/colorPresentation`
- [ ] `textDocument/formatting`
- [ ] `textDocument/rangeFormatting`
- [ ] `textDocument/onTypeFormatting`
- [ ] `textDocument/prepareRename`
- [ ] `textDocument/foldingRange`
- [ ] `textDocument/selectionRange`
- [ ] `workspace/symbol`

Note that degrees of support for each LSP request are varying.

## Contributing to project

```bash
# clone repo with submodules
git clone --recursive git@github.com:rems-project/cn-lsp-server.git

# if you already cloned, pull submodules
git submodule update --init --recursive

# create local switch (or use global one) and install dependencies
opam switch create . ocaml-base-compiler.4.12.0 --with-test

# don't forget to set your environment to use the local switch
eval $(opam env)

# build
make all

# the cnlsp executable can be found at _build/default/cn-lsp-server/src/main.exe
```

## Tests

To run tests execute:

```sh
$ make test
```

Note that tests require [Node.js](https://nodejs.org/en/) and
[Yarn](https://yarnpkg.com/lang/en/) installed.

## Funding


This software was developed by the University of Cambridge Computer
Laboratory as part of the Rigorous Engineering of Mainstream Systems
(REMS) project. This project has been partly funded by an EPSRC
Doctoral Training studentship. This project has been partly funded by
Google. This project has received funding from the European Research
Council (ERC) under the European Union's Horizon 2020 research and
innovation programme (grant agreement No 789108, Advanced Grant
ELVER).

## History

The initial implementation of the Language Server source and end-to-end tests
was taken from the [OCaml LSP server implementation](https://github.com/ocaml/ocaml-lsp).

