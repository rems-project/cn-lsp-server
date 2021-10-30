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
import * as LanguageServer from "./../src/LanguageServer";

import * as Types from "vscode-languageserver-types";

describe("textDocument/hover", () => {
  let languageServer: LanguageServer.LanguageServer;

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
  });

  it("returns type inferred under cursor", async () => {
    languageServer = await LanguageServer.startAndInitialize();
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        "let x = 1\n",
      ),
    });

    let result = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(0, 4),
    });

    expect(result).toMatchObject({
      contents: { kind: "plaintext", value: "int" },
      range: {
        end: { character: 5, line: 0 },
        start: { character: 4, line: 0 },
      },
    });
  });

  it("returns type inferred under cursor (markdown formatting)", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          hover: {
            dynamicRegistration: true,
            contentFormat: ["markdown", "plaintext"],
          },
          moniker: {},
        },
      },
    });
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        "let x = 1\n",
      ),
    });

    let result = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(0, 4),
    });

    expect(result).toMatchObject({
      contents: { kind: "markdown", value: "```ocaml\nint\n```" },
      range: {
        end: { character: 5, line: 0 },
        start: { character: 4, line: 0 },
      },
    });
  });

  it("returns type inferred under cursor with documentation", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          hover: {
            dynamicRegistration: true,
            contentFormat: ["markdown", "plaintext"],
          },
          moniker: {},
        },
      },
    });
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        outdent`
        (** This function has a nice documentation *)
        let id x = x

        `,
      ),
    });

    let result = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(1, 4),
    });

    expect(result).toMatchObject({
      contents: {
        kind: "markdown",
        value: outdent`
          \`\`\`ocaml
          'a -> 'a
          \`\`\`
          ---
          This function has a nice documentation
          `,
      },
    });
  });

  it("returns type inferred under cursor with documentation with tags (markdown formatting)", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          hover: {
            dynamicRegistration: true,
            contentFormat: ["markdown", "plaintext"],
          },
          moniker: {},
        },
      },
    });
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        outdent`
        (** This function has a nice documentation.

            It performs division of two integer numbers.

            @param x dividend
            @param divisor

            @return {i quotient}, i.e. result of division
            @raise Division_by_zero raised when divided by zero

            @see <https://en.wikipedia.org/wiki/Arithmetic#Division_(%C3%B7,_or_/)> article
            @see 'arithmetic.ml' for more context

            @since 4.0.0
            @before 4.4.0

            @deprecated use [(/)]

            @version 1.0.0
            @author John Doe *)
        let div x y =
          x / y

        `,
      ),
    });

    let result = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(20, 4),
    });

    expect(result).toMatchObject({
      contents: {
        kind: "markdown",
        value: outdent`
          \`\`\`ocaml
          int -> int -> int
          \`\`\`
          ---
          This function has a nice documentation.

          It performs division of two integer numbers.
          * * *
          ***@param*** \`x\` dividend

          ***@param*** divisor

          ***@return*** *quotient*, i.e. result of division

          ***@raise*** \`Division_by_zero\` raised when divided by zero

          ***@see*** [link](https://en.wikipedia.org/wiki/Arithmetic#Division_(%C3%B7,_or_/)) article

          ***@see*** \`arithmetic.ml\` for more context

          ***@since*** \`4.0.0\`

          ***@before*** \`4.4.0\`

          ***@deprecated*** use \`(/)\`

          ***@version*** \`1.0.0\`

          ***@author*** John Doe
          `,
      },
    });
  });

  it("returns good type when cursor is between values", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          hover: {
            dynamicRegistration: true,
            contentFormat: ["markdown", "plaintext"],
          },
          moniker: {},
        },
      },
    });
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        outdent`
          let f i f = float_of_int i +. f
          let i = 10
          let f = 10.
          let sum = f i f
       `,
      ),
    });

    let result = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(3, 13),
    });

    expect(result).toMatchObject({
      contents: {
        kind: "markdown",
        value: "```ocaml\nint\n```",
      },
      range: {
        start: { character: 12, line: 3 },
        end: { character: 13, line: 3 },
      },
    });
  });

  it("regression test for #343", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          hover: {
            dynamicRegistration: true,
            contentFormat: ["markdown", "plaintext"],
          },
          moniker: {},
        },
      },
    });
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        outdent`
          type t = s
          and s = string
          type 'a fib = ('a -> unit) -> unit
       `,
      ),
    });

    let hover1 = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(1, 4),
    });

    expect(hover1).toMatchInlineSnapshot(`
      Object {
        "contents": Object {
          "kind": "markdown",
          "value": "\`\`\`ocaml
      type s = t
      \`\`\`",
        },
        "range": Object {
          "end": Object {
            "character": 14,
            "line": 1,
          },
          "start": Object {
            "character": 0,
            "line": 1,
          },
        },
      }
    `);

    let hover2 = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(2, 9),
    });

    expect(hover2).toMatchInlineSnapshot(`
      Object {
        "contents": Object {
          "kind": "markdown",
          "value": "\`\`\`ocaml
      type 'a fib = ('a -> unit) -> unit
      \`\`\`",
        },
        "range": Object {
          "end": Object {
            "character": 34,
            "line": 2,
          },
          "start": Object {
            "character": 0,
            "line": 2,
          },
        },
      }
    `);
  });

  it("regression test for #403", async () => {
    languageServer = await LanguageServer.startAndInitialize();
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        outdent`
type foo = int

let x : foo = 1
`,
      ),
    });

    let result = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(2, 4),
    });

    expect(result).toMatchInlineSnapshot(`
      Object {
        "contents": Object {
          "kind": "plaintext",
          "value": "foo",
        },
        "range": Object {
          "end": Object {
            "character": 5,
            "line": 2,
          },
          "start": Object {
            "character": 4,
            "line": 2,
          },
        },
      }
    `);
  });

  it("FIXME: reproduce [#344](https://github.com/ocaml/ocaml-lsp/issues/344)", async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          hover: {
            dynamicRegistration: true,
            contentFormat: ["markdown", "plaintext"],
          },
          moniker: {},
        },
      },
    });

    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        // the empty space below is necessary to reproduce the bug
        outdent`
























        let k = ()
        let m = List.map
        `,
      ),
    });

    // here we see that all is ok
    let hoverOverK = await languageServer.sendRequest("textDocument/hover", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position: Types.Position.create(24, 4),
    });

    expect(hoverOverK).toMatchInlineSnapshot(`
      Object {
        "contents": Object {
          "kind": "markdown",
          "value": "\`\`\`ocaml
      unit
      \`\`\`",
        },
        "range": Object {
          "end": Object {
            "character": 5,
            "line": 24,
          },
          "start": Object {
            "character": 4,
            "line": 24,
          },
        },
      }
    `);

    // we trigger the bug
    let autocompleteForListm = await languageServer.sendRequest(
      "textDocument/hover",
      {
        textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
        position: Types.Position.create(25, 15),
      },
    );

    let buggedHoverOverK = await languageServer.sendRequest(
      "textDocument/hover",
      {
        textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
        position: Types.Position.create(24, 4),
      },
    );

    // now the same hover as before comes with unrelated documentation
    expect(buggedHoverOverK).toMatchInlineSnapshot(`
      Object {
        "contents": Object {
          "kind": "markdown",
          "value": "\`\`\`ocaml
      unit
      \`\`\`",
        },
        "range": Object {
          "end": Object {
            "character": 5,
            "line": 24,
          },
          "start": Object {
            "character": 4,
            "line": 24,
          },
        },
      }
    `);
  });
});
