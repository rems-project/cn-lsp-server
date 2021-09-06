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
import { Position } from "vscode-languageserver-types";

describe("ocamllsp/wrappingAstNode", () => {
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

  async function sendWrappingAstNodeRequest({
    line,
    character,
  }: {
    line: number;
    character: number;
  }) {
    return languageServer.sendRequest("ocamllsp/wrappingAstNode", {
      uri: "file:///test.ml",
      position: Position.create(line, character),
    });
  }

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize();
  });

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("empty document", async () => {
    await openDocument(
      outdent`
`,
    );

    let r = await sendWrappingAstNodeRequest({ line: 0, character: 0 });
    expect(r).toMatchInlineSnapshot(`null`);
  });

  let code_snippet_0 = outdent`
let k = 1

module M = struct
  let a =
    let b = 1 in
    b + 1

  let c = 2
end
  `;

  it("when on a toplevel let binding", async () => {
    await openDocument(code_snippet_0);

    let r = await sendWrappingAstNodeRequest({ line: 0, character: 5 });

    /* given range corresponds to:
        let k = 1
    */
    expect(r).toMatchInlineSnapshot(`
      Object {
        "end": Object {
          "character": 9,
          "line": 0,
        },
        "start": Object {
          "character": 0,
          "line": 0,
        },
      }
    `);
  });

  it("in between toplevel bindings (let and module def)", async () => {
    await openDocument(code_snippet_0);

    let r = await sendWrappingAstNodeRequest({ line: 1, character: 0 });

    /* given range corresponds to:
        whole `code_snippet_0`
    */
    expect(r).toMatchInlineSnapshot(`
      Object {
        "end": Object {
          "character": 3,
          "line": 8,
        },
        "start": Object {
          "character": 0,
          "line": 0,
        },
      }
    `);
  });

  it("on keyword struct", async () => {
    await openDocument(code_snippet_0);

    let r = await sendWrappingAstNodeRequest({ line: 2, character: 14 });

    /* given range corresponds to: the whole module definition M
        module M = struct
          let a =
            let b = 1 in
            b + 1

          let c = 2
        end
    */
    expect(r).toMatchInlineSnapshot(`
      Object {
        "end": Object {
          "character": 3,
          "line": 8,
        },
        "start": Object {
          "character": 0,
          "line": 2,
        },
      }
    `);
  });

  it("on `b`'s let-binding (nested let-binding in a module def)", async () => {
    await openDocument(code_snippet_0);
    let r = await sendWrappingAstNodeRequest({ line: 4, character: 10 });

    /* given range corresponds to:
        let a =
          let b = 1 in
          b + 1
    */
    expect(r).toMatchInlineSnapshot(`
      Object {
        "end": Object {
          "character": 9,
          "line": 5,
        },
        "start": Object {
          "character": 2,
          "line": 3,
        },
      }
    `);
  });

  it("between `a`'s and `c`'s let-bindings in a module def", async () => {
    await openDocument(code_snippet_0);

    let r = await sendWrappingAstNodeRequest({ line: 6, character: 0 });

    /* given range corresponds to: values in M, but not module binding itself
        let a =
          let b = 1 in
          b + 1

        let c = 2
    */
    expect(r).toMatchInlineSnapshot(`
      Object {
        "end": Object {
          "character": 11,
          "line": 7,
        },
        "start": Object {
          "character": 2,
          "line": 3,
        },
      }
    `);
  });
});
