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

import { promises as fs } from "fs";
import * as path from "path";
import * as child_process from "child_process";
import * as LanguageServer from "./../src/LanguageServer";
import * as Types from "vscode-languageserver-types";
import { testUri, toEqualUri } from "./../src/LanguageServer";

expect.extend({
  toEqualUri: toEqualUri(this),
});

declare global {
  namespace jest {
    interface Matchers<R> {
      toEqualUri(uri: string): R;
    }
  }
}

describe("textDocument/declaration", () => {
  let languageServer = null;

  let testWorkspacePath = path.join(__dirname, "declaration_files/");

  let createPathForFile = (filename: string) =>
    path.join(testWorkspacePath, filename);

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize();
  });

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  async function openDocument(filepath) {
    let source = await fs.readFile(filepath);
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        testUri(filepath),
        "ocaml",
        0,
        source.toString(),
      ),
    });
  }

  async function queryDeclaration(filepath, position) {
    return await languageServer.sendRequest("textDocument/declaration", {
      textDocument: Types.TextDocumentIdentifier.create(testUri(filepath)),
      position,
    });
  }

  it("returns location of a declaration", async () => {
    child_process.execSync("dune build", { cwd: testWorkspacePath });

    await openDocument(createPathForFile("main.ml"));

    let result = await queryDeclaration(
      createPathForFile("main.ml"),
      Types.Position.create(0, 13),
    );

    expect(result.length).toBe(1);
    expect(result[0].range).toMatchObject({
      end: { character: 0, line: 0 },
      start: { character: 0, line: 0 },
    });
    expect(result[0].uri).toEqualUri(testUri(createPathForFile("lib.ml")));
  });
});
