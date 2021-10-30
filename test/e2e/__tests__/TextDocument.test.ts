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
import * as LanguageServer from "./../src/LanguageServer";

import * as Types from "vscode-languageserver-types";

describe("TextDocument: incremental sync", () => {
  let languageServer: LanguageServer.LanguageServer;

  async function getDoc(languageServer: LanguageServer.LanguageServer) {
    let result = await languageServer.sendRequest("debug/textDocument/get", {
      textDocument: Types.TextDocumentIdentifier.create(
        "file:///test-document.txt",
      ),
      position: Types.Position.create(0, 0),
    });
    return result;
  }

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("Manages unicode character ranges correctly", async () => {
    languageServer = await LanguageServer.startAndInitialize();
    languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test-document.txt",
        "c",
        0,
        outdent`
          let x = 4
          let y = "a𐐀b"
        `,
      ),
    });
    languageServer.sendNotification("textDocument/didChange", {
      textDocument: Types.VersionedTextDocumentIdentifier.create(
        "file:///test-document.txt",
        1,
      ),
      contentChanges: [
        {
          range: {
            start: { line: 1, character: 10 },
            end: { line: 1, character: 12 },
          },
          text: "",
        },
      ],
    });

    expect(await getDoc(languageServer)).toEqual('let x = 4\nlet y = "ab"');
  });

  it("updates in the middle of the line", async () => {
    languageServer = await LanguageServer.startAndInitialize();
    languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test-document.txt",
        "c",
        0,
        "let x = 1;\n\nlet y = 2;",
      ),
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\n\nlet y = 2;");

    languageServer.sendNotification("textDocument/didChange", {
      textDocument: Types.VersionedTextDocumentIdentifier.create(
        "file:///test-document.txt",
        1,
      ),
      contentChanges: [
        {
          range: {
            start: { line: 2, character: 5 },
            end: { line: 2, character: 5 },
          },
          rangeLength: 0,
          text: "1",
        },
      ],
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\n\nlet y1 = 2;");

    languageServer.sendNotification("textDocument/didChange", {
      textDocument: Types.VersionedTextDocumentIdentifier.create(
        "file:///test-document.txt",
        1,
      ),
      contentChanges: [
        {
          range: {
            start: { line: 2, character: 5 },
            end: { line: 2, character: 6 },
          },
          rangeLength: 1,
          text: "",
        },
      ],
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\n\nlet y = 2;");
  });

  it("updates in at the start of the line", async () => {
    languageServer = await LanguageServer.startAndInitialize();

    languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test-document.txt",
        "c",
        0,
        "let x = 1;\n\nlet y = 2;",
      ),
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\n\nlet y = 2;");

    languageServer.sendNotification("textDocument/didChange", {
      textDocument: Types.VersionedTextDocumentIdentifier.create(
        "file:///test-document.txt",
        1,
      ),
      contentChanges: [
        {
          range: {
            start: { line: 1, character: 0 },
            end: { line: 1, character: 0 },
          },
          rangeLength: 0,
          text: "s",
        },
      ],
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\ns\nlet y = 2;");
  });

  it("update when inserting a line", async () => {
    languageServer = await LanguageServer.startAndInitialize();

    languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test-document.txt",
        "c",
        0,
        "let x = 1;\n\nlet y = 2;",
      ),
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\n\nlet y = 2;");

    languageServer.sendNotification("textDocument/didChange", {
      textDocument: Types.VersionedTextDocumentIdentifier.create(
        "file:///test-document.txt",
        1,
      ),
      contentChanges: [
        {
          range: {
            start: { line: 0, character: 10 },
            end: { line: 0, character: 10 },
          },
          rangeLength: 0,
          text: "\nlet x = 1;",
        },
      ],
    });

    expect(await getDoc(languageServer)).toEqual(
      "let x = 1;\nlet x = 1;\n\nlet y = 2;",
    );
  });

  it("update when inserting a line at the end of the doc", async () => {
    languageServer = await LanguageServer.startAndInitialize();

    languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test-document.txt",
        "c",
        0,
        "let x = 1;\n\nlet y = 2;",
      ),
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\n\nlet y = 2;");

    languageServer.sendNotification("textDocument/didChange", {
      textDocument: Types.VersionedTextDocumentIdentifier.create(
        "file:///test-document.txt",
        1,
      ),
      contentChanges: [
        {
          range: {
            start: { line: 2, character: 10 },
            end: { line: 2, character: 10 },
          },
          rangeLength: 0,
          text: "\nlet y = 2;",
        },
      ],
    });

    expect(await getDoc(languageServer)).toEqual(
      "let x = 1;\n\nlet y = 2;\nlet y = 2;",
    );
  });

  it("update when deleting a line", async () => {
    languageServer = await LanguageServer.startAndInitialize();

    languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test-document.txt",
        "c",
        0,
        "let x = 1;\n\nlet y = 2;",
      ),
    });

    expect(await getDoc(languageServer)).toEqual("let x = 1;\n\nlet y = 2;");

    languageServer.sendNotification("textDocument/didChange", {
      textDocument: Types.VersionedTextDocumentIdentifier.create(
        "file:///test-document.txt",
        1,
      ),
      contentChanges: [
        {
          range: {
            start: { line: 0, character: 0 },
            end: { line: 1, character: 0 },
          },
          rangeLength: 11,
          text: "",
        },
      ],
    });

    expect(await getDoc(languageServer)).toEqual("\nlet y = 2;");
  });
});

describe("TextDocument", () => {
  let languageServer;

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  describe("didOpen", () => {
    it("stores text document", async () => {
      languageServer = await LanguageServer.startAndInitialize();
      languageServer.sendNotification("textDocument/didOpen", {
        textDocument: Types.TextDocumentItem.create(
          "file:///test-document.txt",
          "c",
          0,
          "Hello, World!",
        ),
      });

      let result = await languageServer.sendRequest("debug/textDocument/get", {
        textDocument: Types.TextDocumentIdentifier.create(
          "file:///test-document.txt",
        ),
        position: Types.Position.create(0, 0),
      });

      expect(result).toEqual("Hello, World!");
    });
  });

  describe("didChange", () => {
    it("updates text document", async () => {
      languageServer = await LanguageServer.startAndInitialize();
      languageServer.sendNotification("textDocument/didOpen", {
        textDocument: Types.TextDocumentItem.create(
          "file:///test-document.txt",
          "c",
          0,
          "Hello, World!",
        ),
      });

      languageServer.sendNotification("textDocument/didChange", {
        textDocument: Types.VersionedTextDocumentIdentifier.create(
          "file:///test-document.txt",
          1,
        ),
        contentChanges: [{ text: "Hello again!" }],
      });

      let result = await languageServer.sendRequest("debug/textDocument/get", {
        textDocument: Types.TextDocumentIdentifier.create(
          "file:///test-document.txt",
        ),
        position: Types.Position.create(0, 0),
      });

      expect(result).toEqual("Hello again!");
    });
  });
});
