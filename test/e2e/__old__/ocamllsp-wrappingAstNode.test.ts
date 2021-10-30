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
