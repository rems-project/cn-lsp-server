/******************************************************************************/
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
