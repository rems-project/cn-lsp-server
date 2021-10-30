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

describe("textDocument/rename", () => {
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

  async function query(position: Types.Position, newNameOpt?: string) {
    let newName = newNameOpt ? newNameOpt : "new_num";
    return await languageServer.sendRequest("textDocument/rename", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position,
      newName,
    });
  }

  async function query_prepare(position: Types.Position) {
    return await languageServer.sendRequest("textDocument/prepareRename", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position,
    });
  }

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("can reject invalid rename request", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        workspace: { workspaceEdit: { documentChanges: false } },
      },
    });

    await openDocument(outdent`
      let num = 42
      let num = num + 13
      let num2 = num
    `);

    let result = await query_prepare(Types.Position.create(0, 1));
    expect(result).toBeNull();
  });

  it("allows valid rename request", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        workspace: { workspaceEdit: { documentChanges: false } },
      },
    });

    await openDocument(outdent`
      let num = 42
      let num = num + 13
      let num2 = num
    `);

    let result = await query_prepare(Types.Position.create(0, 4));
    expect(result).toMatchObject({
      start: { line: 0, character: 4 },
      end: { line: 0, character: 7 },
    });
  });

  it("rename value in a file without documentChanges capability", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        workspace: { workspaceEdit: { documentChanges: false } },
      },
    });

    await openDocument(outdent`
      let num = 42
      let num = num + 13
      let num2 = num
    `);

    let result = await query(Types.Position.create(0, 4));

    expect(result).toMatchObject({
      changes: {
        "file:///test.ml": [
          {
            range: {
              start: {
                line: 0,
                character: 4,
              },
              end: {
                line: 0,
                character: 7,
              },
            },
            newText: "new_num",
          },
          {
            range: {
              start: {
                line: 1,
                character: 10,
              },
              end: {
                line: 1,
                character: 13,
              },
            },
            newText: "new_num",
          },
        ],
      },
    });
  });

  it("rename value in a file with documentChanges capability", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        workspace: { workspaceEdit: { documentChanges: true } },
      },
    });

    await openDocument(outdent`
      let num = 42
      let num = num + 13
      let num2 = num
    `);

    let result = await query(Types.Position.create(0, 4));

    expect(result).toMatchObject({
      documentChanges: [
        {
          textDocument: {
            version: 0,
            uri: "file:///test.ml",
          },
          edits: [
            {
              range: {
                start: {
                  line: 0,
                  character: 4,
                },
                end: {
                  line: 0,
                  character: 7,
                },
              },
              newText: "new_num",
            },
            {
              range: {
                start: {
                  line: 1,
                  character: 10,
                },
                end: {
                  line: 1,
                  character: 13,
                },
              },
              newText: "new_num",
            },
          ],
        },
      ],
    });
  });

  it("rename a var used as a named argument", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        workspace: { workspaceEdit: { documentChanges: false } },
      },
    });

    await openDocument(outdent`
let foo x = x

let bar ~foo = foo ()

let () = bar ~foo
    `);

    let result = await query(Types.Position.create(0, 4), "ident");

    expect(result).toMatchInlineSnapshot(`
      Object {
        "changes": Object {
          "file:///test.ml": Array [
            Object {
              "newText": "ident",
              "range": Object {
                "end": Object {
                  "character": 7,
                  "line": 0,
                },
                "start": Object {
                  "character": 4,
                  "line": 0,
                },
              },
            },
            Object {
              "newText": ":ident",
              "range": Object {
                "end": Object {
                  "character": 17,
                  "line": 4,
                },
                "start": Object {
                  "character": 17,
                  "line": 4,
                },
              },
            },
          ],
        },
      }
    `);
  });

  it("rename a var used as a named argument", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        workspace: { workspaceEdit: { documentChanges: false } },
      },
    });

    await openDocument(outdent`
let foo = Some ()

let bar ?foo () = foo

;;
ignore (bar ?foo ())
    `);

    let result = await query(Types.Position.create(0, 4), "sunit");

    expect(result).toMatchInlineSnapshot(`
      Object {
        "changes": Object {
          "file:///test.ml": Array [
            Object {
              "newText": "sunit",
              "range": Object {
                "end": Object {
                  "character": 7,
                  "line": 0,
                },
                "start": Object {
                  "character": 4,
                  "line": 0,
                },
              },
            },
            Object {
              "newText": ":sunit",
              "range": Object {
                "end": Object {
                  "character": 16,
                  "line": 5,
                },
                "start": Object {
                  "character": 16,
                  "line": 5,
                },
              },
            },
          ],
        },
      }
    `);
  });
});
