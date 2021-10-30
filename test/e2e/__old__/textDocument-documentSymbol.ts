/******************************************************************************/
/*  The following parts of CN LSP Server contain new code released under the  */
/*  BSD 2-Clause License:                                                     */
/*  * `src/cn.ml`                                                             */
/*                                                                            */
/*  Copyright (c) 2021 Dhruv Makwana                                          */
/*  All rights reserved.                                                      */
/*                                                                            */
/*  This software was developed by the University of Cambridge Computer       */
/*  Laboratory as part of the Rigorous Engineering of Mainstream Systems      */
/*  (REMS) project. This project has been partly funded by an EPSRC           */
/*  Doctoral Training studentship. This project has been partly funded by     */
/*  Google. This project has received funding from the European Research      */
/*  Council (ERC) under the European Union's Horizon 2020 research and        */
/*  innovation programme (grant agreement No 789108, Advanced Grant           */
/*  ELVER).                                                                   */
/*                                                                            */
/*  BSD 2-Clause License                                                      */
/*                                                                            */
/*  Redistribution and use in source and binary forms, with or without        */
/*  modification, are permitted provided that the following conditions        */
/*  are met:                                                                  */
/*  1. Redistributions of source code must retain the above copyright         */
/*     notice, this list of conditions and the following disclaimer.          */
/*  2. Redistributions in binary form must reproduce the above copyright      */
/*     notice, this list of conditions and the following disclaimer in        */
/*     the documentation and/or other materials provided with the             */
/*     distribution.                                                          */
/*                                                                            */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''        */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED         */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A           */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR       */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,              */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT          */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF          */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND       */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,        */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT        */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF        */
/*  SUCH DAMAGE.                                                              */
/*                                                                            */
/*  All other parts involve adapted code, with the new code subject to the    */
/*  above BSD 2-Clause licence and the original code subject to its ISC       */
/*  licence.                                                                  */
/*                                                                            */
/*  ISC License                                                               */
/*                                                                            */
/*  Copyright (X) 2018-2019, the [ocaml-lsp                                   */
/*  contributors](https://github.com/ocaml/ocaml-lsp/graphs/contributors)     */
/*                                                                            */
/*  Permission to use, copy, modify, and distribute this software for any     */
/*  purpose with or without fee is hereby granted, provided that the above    */
/*  copyright notice and this permission notice appear in all copies.         */
/*                                                                            */
/*  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  */
/*  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          */
/*  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   */
/*  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    */
/*  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     */
/*  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   */
/*  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            */
/******************************************************************************/

import outdent from "outdent";
import * as LanguageServer from "../src/LanguageServer";

import * as Types from "vscode-languageserver-types";

describe("textDocument/documentSymbol", () => {
  let languageServer = null;

  async function openDocument(source: string) {
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        source,
      ),
    });
  }

  async function query() {
    return await languageServer.sendRequest("textDocument/documentSymbol", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
    });
  }

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("returns a list of symbol infos", async () => {
    languageServer = await LanguageServer.startAndInitialize();
    await openDocument(outdent`
      let num = 42
      let string = "Hello"

      module M = struct
        let m a b = a + b
        let n = 32
      end
    `);

    let result = await query();

    expect(result).toMatchObject([
      {
        kind: 2,
        location: {
          range: {
            end: { character: 3, line: 6 },
            start: { character: 0, line: 3 },
          },
          uri: "file:///test.ml",
        },
        name: "M",
      },
      {
        containerName: "M",
        kind: 12,
        location: {
          range: {
            end: { character: 12, line: 5 },
            start: { character: 2, line: 5 },
          },
          uri: "file:///test.ml",
        },
        name: "n",
      },
      {
        containerName: "M",
        kind: 12,
        location: {
          range: {
            end: { character: 19, line: 4 },
            start: { character: 2, line: 4 },
          },
          uri: "file:///test.ml",
        },
        name: "m",
      },
      {
        kind: 12,
        location: {
          range: {
            end: { character: 20, line: 1 },
            start: { character: 0, line: 1 },
          },
          uri: "file:///test.ml",
        },
        name: "string",
      },
      {
        kind: 12,
        location: {
          range: {
            end: { character: 12, line: 0 },
            start: { character: 0, line: 0 },
          },
          uri: "file:///test.ml",
        },
        name: "num",
      },
    ]);
  });

  it("returns a hierarchy of symbols", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          documentSymbol: {
            hierarchicalDocumentSymbolSupport: true,
          },
          moniker: {},
        },
      },
    });
    await openDocument(outdent`
      let num = 42
      let string = "Hello"

      module M = struct
        let m a b = a + b
        let n = 32
      end
    `);

    let result = await query();

    expect(result).toMatchObject([
      {
        children: [
          {
            children: [],
            deprecated: false,
            detail: "int",
            kind: 12,
            name: "n",
            range: {
              end: { character: 12, line: 5 },
              start: { character: 2, line: 5 },
            },
            selectionRange: {
              end: { character: 12, line: 5 },
              start: { character: 2, line: 5 },
            },
          },
          {
            children: [],
            deprecated: false,
            detail: "int -> int -> int",
            kind: 12,
            name: "m",
            range: {
              end: { character: 19, line: 4 },
              start: { character: 2, line: 4 },
            },
            selectionRange: {
              end: { character: 19, line: 4 },
              start: { character: 2, line: 4 },
            },
          },
        ],
        deprecated: false,
        kind: 2,
        name: "M",
        range: {
          end: { character: 3, line: 6 },
          start: { character: 0, line: 3 },
        },
        selectionRange: {
          end: { character: 3, line: 6 },
          start: { character: 0, line: 3 },
        },
      },
      {
        children: [],
        deprecated: false,
        detail: "string",
        kind: 12,
        name: "string",
        range: {
          end: { character: 20, line: 1 },
          start: { character: 0, line: 1 },
        },
        selectionRange: {
          end: { character: 20, line: 1 },
          start: { character: 0, line: 1 },
        },
      },
      {
        children: [],
        deprecated: false,
        detail: "int",
        kind: 12,
        name: "num",
        range: {
          end: { character: 12, line: 0 },
          start: { character: 0, line: 0 },
        },
        selectionRange: {
          end: { character: 12, line: 0 },
          start: { character: 0, line: 0 },
        },
      },
    ]);
  });
});
