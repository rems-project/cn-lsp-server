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

describe("textDocument/references", () => {
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

  async function query(position: Types.Position) {
    return await languageServer.sendRequest("textDocument/documentHighlight", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position,
    });
  }

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize();
  });

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("highlight references in a file", async () => {
    await openDocument(outdent`
      let num = 42
      let sum = num + 13
      let sum2 = sum + num
    `);

    let result = await query(Types.Position.create(0, 4));

    expect(result).toMatchObject([
      {
        range: {
          end: {
            character: 7,
            line: 0,
          },
          start: {
            character: 4,
            line: 0,
          },
        },
        kind: 1,
      },
      {
        range: {
          end: {
            character: 13,
            line: 1,
          },
          start: {
            character: 10,
            line: 1,
          },
        },
        kind: 1,
      },
      {
        range: {
          end: {
            character: 20,
            line: 2,
          },
          start: {
            character: 17,
            line: 2,
          },
        },
        kind: 1,
      },
    ]);
  });
});
