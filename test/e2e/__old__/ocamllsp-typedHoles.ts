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

describe("ocamllsp/typedHoles", () => {
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

  async function sendTypedHolesReq() {
    return languageServer.sendRequest("ocamllsp/typedHoles", {
      uri: "file:///test.ml",
    });
  }

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize();
  });

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("empty when no holes in file", async () => {
    await openDocument(
      outdent`
let u = 1
`,
    );

    let r = await sendTypedHolesReq();
    expect(r).toMatchInlineSnapshot(`Array []`);
  });

  it("one hole", async () => {
    await openDocument(
      outdent`
let k = match () with () -> _
`,
    );

    let r = await sendTypedHolesReq();
    expect(r).toMatchInlineSnapshot(`
      Array [
        Object {
          "end": Object {
            "character": 29,
            "line": 0,
          },
          "start": Object {
            "character": 28,
            "line": 0,
          },
        },
      ]
    `);
  });

  it("several holes", async () => {
    await openDocument(
      outdent`
let u =
  let i = match Some 1 with None -> _ | Some -> _ in
  let b = match () with () -> _ in
  ()
      `,
    );
    let r = await sendTypedHolesReq();
    expect(r).toMatchInlineSnapshot(`
      Array [
        Object {
          "end": Object {
            "character": 31,
            "line": 2,
          },
          "start": Object {
            "character": 30,
            "line": 2,
          },
        },
        Object {
          "end": Object {
            "character": 37,
            "line": 1,
          },
          "start": Object {
            "character": 36,
            "line": 1,
          },
        },
        Object {
          "end": Object {
            "character": 49,
            "line": 1,
          },
          "start": Object {
            "character": 48,
            "line": 1,
          },
        },
      ]
    `);
  });
});
