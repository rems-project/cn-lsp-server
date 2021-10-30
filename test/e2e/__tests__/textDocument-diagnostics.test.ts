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
/*  All other parts on CN LSP Server are released under a mixed BSD-2-Clause  */
/*  and ISC license.                                                          */
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
import * as rpc from "vscode-jsonrpc/node";
import * as LanguageServer from "../src/LanguageServer";
import { writeFileSync, unlinkSync } from "fs";
import * as path from "path";
import * as os from "os";

import * as Types from "vscode-languageserver-types";

describe("textDocument/diagnostics", () => {
  let languageServer: rpc.MessageConnection = null;
  let tmpFile = path.join(os.tmpdir(), "cn-lsp-server-diagnostic-test.c");

  async function openDocument(source: string) {
    writeFileSync(tmpFile, source);
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        LanguageServer.toURI(tmpFile),
        "c",
        0,
        source,
      ),
    });
  }

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize();
  });

  afterEach(async () => {
    unlinkSync(tmpFile);
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("has related diagnostics", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [
              Object {
                "code": "View Program State",
                "codeDescription": Object {
                  "href": "file:///tmp/cn-lsp-server-diagnostic-test.c.cn-state",
                },
                "message": "Undefined behaviour (§6.5#2) an exceptional condition occurred during the evaluation of an expression.",
                "range": Object {
                  "end": Object {
                    "character": 25,
                    "line": 7,
                  },
                  "start": Object {
                    "character": 13,
                    "line": 7,
                  },
                },
              },
            ],
            "uri": "file:///tmp/cn-lsp-server-diagnostic-test.c",
          }
        `);
        resolve(null);
      }),
    );
    await openDocument(outdent`
struct s2 { signed int x; };
struct s1 { struct s2 inner; };


[[cn::requires("Owned(inner)")]]
[[cn::ensures("Owned((inner)@start)")]]
void g (struct s2* inner) {
  inner->x = inner->x + 2 - 1;
}


[[cn::requires("Owned(outer)")]]
[[cn::ensures("Owned(outer)")]]
void f (struct s1* outer) {
  g(&outer->inner);
  }

/* should fail: we don't know that s2.x isn't initially the maximum
 *    representable value */
    `);
    await receivedDiganostics;
  });
});
