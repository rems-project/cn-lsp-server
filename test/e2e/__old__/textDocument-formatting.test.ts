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
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

const ocamlFormat = `
break-cases=all
break-separators=before
break-sequences=true
cases-exp-indent=2
doc-comments=before
dock-collection-brackets=false
field-space=loose
if-then-else=k-r
indicate-nested-or-patterns=unsafe-no
let-and=sparse
sequence-style=terminator
space-around-arrays
space-around-lists
space-around-records
type-decl=sparse
wrap-comments=true
`;

function setupOcamlFormat(ocamlFormat: string) {
  let tmpdir = fs.mkdtempSync(path.join(os.tmpdir(), "ocamllsp-test-"));
  fs.writeFileSync(path.join(tmpdir, ".ocamlformat"), ocamlFormat);
  return tmpdir;
}

async function openDocument(languageServer, source, name) {
  await languageServer.sendNotification("textDocument/didOpen", {
    textDocument: Types.TextDocumentItem.create(name, "ocaml", 0, source),
  });
}

async function query(languageServer, name) {
  return await languageServer.sendRequest("textDocument/formatting", {
    textDocument: Types.TextDocumentIdentifier.create(name),
    options: Types.FormattingOptions.create(2, true),
  });
}

const maybeDescribe = os.type() === "Windows_NT" ? describe.skip : describe;

maybeDescribe("textDocument/formatting", () => {
  maybeDescribe("reformatter binary present", () => {
    let languageServer = null;

    afterEach(async () => {
      await LanguageServer.exit(languageServer);
      languageServer = null;
    });

    it("can format an ocaml impl file", async () => {
      languageServer = await LanguageServer.startAndInitialize();

      let name = path.join(setupOcamlFormat(ocamlFormat), "test.ml");

      await openDocument(
        languageServer,
        "let rec gcd a b =\n" +
          "  match (a, b) with\n" +
          "    | 0, n\n" +
          "  | n, 0 ->\n" +
          "    n\n" +
          "  | _, _ -> gcd a (b mod a)\n",
        name,
      );

      let result = await query(languageServer, name);
      expect(result).toMatchObject([
        {
          range: {
            start: { character: 0, line: 2 },
            end: { character: 0, line: 3 },
          },
          newText: "  | 0, n\n",
        },
      ]);
    });

    it("leaves unchanged files alone", async () => {
      languageServer = await LanguageServer.startAndInitialize();

      let name = path.join(setupOcamlFormat(ocamlFormat), "test.ml");

      await openDocument(
        languageServer,
        "let rec gcd a b =\n" +
          "  match (a, b) with\n" +
          "  | 0, n\n" +
          "  | n, 0 ->\n" +
          "    n\n" +
          "  | _, _ -> gcd a (b mod a)\n",
        name,
      );

      let result = await query(languageServer, name);
      expect(result).toMatchObject([]);
    });

    it("can format an ocaml intf file", async () => {
      languageServer = await LanguageServer.startAndInitialize();

      let name = path.join(setupOcamlFormat(ocamlFormat), "test.mli");

      await openDocument(
        languageServer,
        "module Test :           sig\n  type t =\n    | Foo\n    | Bar\n    | Baz\nend\n",
        name,
      );

      let result = await query(languageServer, name);

      expect(result).toMatchObject([
        {
          range: {
            start: { character: 0, line: 0 },
            end: { character: 0, line: 1 },
          },
          newText: "module Test : sig\n",
        },
      ]);
    });

    it("does not format ignored files", async () => {
      languageServer = await LanguageServer.startAndInitialize();

      let tmpdir = setupOcamlFormat(ocamlFormat);

      let ocamlFormatIgnore = path.join(tmpdir, ".ocamlformat-ignore");
      fs.writeFileSync(ocamlFormatIgnore, "test.ml\n");

      let name = path.join(tmpdir, "test.ml");

      await openDocument(
        languageServer,
        "let rec gcd a b = match (a, b) with\n" +
          "  | 0, n\n" +
          "  | n, 0 ->\n" +
          "    n\n" +
          "  | _, _ -> gcd a (b mod a)\n",
        name,
      );

      let result = await query(languageServer, name);
      expect(result).toMatchObject([]);
    });
  });
});
