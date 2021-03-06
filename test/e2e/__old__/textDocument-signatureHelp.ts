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

const describe_opt = LanguageServer.ocamlVersionGEq("4.08.0")
  ? describe
  : xdescribe;

describe_opt("textDocument/completion", () => {
  let languageServer = null;

  async function openDocument(source) {
    await languageServer.sendNotification("textDocument/didOpen", {
      textDocument: Types.TextDocumentItem.create(
        "file:///test.ml",
        "ocaml",
        0,
        source,
      ),
    });
  }

  async function querySignatureHelp(position) {
    return await languageServer.sendRequest("textDocument/signatureHelp", {
      textDocument: Types.TextDocumentIdentifier.create("file:///test.ml"),
      position,
    });
  }

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize({
      capabilities: {
        textDocument: {
          moniker: {},
          signatureHelp: {
            dynamicRegistration: true,
            signatureInformation: {
              documentationFormat: ["markdown", "plaintext"],
              parameterInformation: {
                labelOffsetSupport: true,
              },
            },
          },
        },
      },
    });
  });

  afterEach(async () => {
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  it("can provide signature help after a function-type value", async () => {
    openDocument(outdent`
      let map = ListLabels.map

      let _ = map
    `);

    let items = await querySignatureHelp(Types.Position.create(2, 11));
    expect(items).toMatchObject({
      signatures: [
        {
          label: "map : f:('a -> 'b) -> 'a list -> 'b list",
          parameters: [
            {
              label: [6, 18],
            },
            {
              label: [22, 29],
            },
          ],
        },
      ],
      activeSignature: 0,
      activeParameter: 1,
    });
  });

  it("can provide signature help for an operator", async () => {
    openDocument(outdent`
      let (+) = (+)

      let _ = 1 + 2
    `);

    let items = await querySignatureHelp(Types.Position.create(2, 13));
    expect(items).toMatchObject({
      signatures: [
        {
          label: "(+) : int -> int -> int",
          parameters: [
            {
              label: [6, 9],
            },
            {
              label: [13, 16],
            },
          ],
        },
      ],
      activeSignature: 0,
      activeParameter: 1,
    });
  });

  it("can provide signature help for an anonymous function", async () => {
    openDocument(outdent`
      let _ = (fun x -> x + 1)
    `);

    let items = await querySignatureHelp(Types.Position.create(0, 26));
    expect(items).toMatchObject({
      signatures: [
        {
          label: "_ : int -> int",
          parameters: [
            {
              label: [4, 7],
            },
          ],
        },
      ],
      activeSignature: 0,
      activeParameter: 0,
    });
  });

  it("can make the non-labelled parameter active", async () => {
    openDocument(outdent`
      let map = ListLabels.map

      let _ = map []
    `);

    let items = await querySignatureHelp(Types.Position.create(2, 14));
    expect(items).toMatchObject({
      signatures: [
        {
          label: "map : f:('a -> 'b) -> 'a list -> 'b list",
          parameters: [
            {
              label: [6, 18],
            },
            {
              label: [22, 29],
            },
          ],
        },
      ],
      activeSignature: 0,
      activeParameter: 1,
    });
  });

  it("can make the labelled parameter active", async () => {
    openDocument(outdent`
      let map = ListLabels.map

      let _ = map ~f:Int.abs
    `);

    let items = await querySignatureHelp(Types.Position.create(2, 22));
    expect(items).toMatchObject({
      signatures: [
        {
          label: "map : f:(int -> int) -> int list -> int list",
          parameters: [
            {
              label: [6, 20],
            },
            {
              label: [24, 32],
            },
          ],
        },
      ],
      activeSignature: 0,
      activeParameter: 0,
    });
  });

  it("can make a labelled parameter active by prefix", async () => {
    openDocument(outdent`
      let mem = ListLabels.mem

      let _ = mem ~se
    `);

    let items = await querySignatureHelp(Types.Position.create(2, 15));
    expect(items).toMatchObject({
      signatures: [
        {
          label: "mem : 'a -> set:'a list -> bool",
          parameters: [
            {
              label: [6, 8],
            },
            {
              label: [12, 23],
            },
          ],
        },
      ],
      activeSignature: 0,
      activeParameter: 1,
    });
  });

  it("can make an optional parameter active by prefix", async () => {
    openDocument(outdent`
      let create = Hashtbl.create

      let _ = create ?ra
    `);

    let items = await querySignatureHelp(Types.Position.create(2, 18));
    expect(items).toMatchObject({
      signatures: [
        {
          label: "create : ?random:bool -> int -> ('a, 'b) Hashtbl.t",
          parameters: [
            {
              label: [9, 21],
            },
            {
              label: [25, 28],
            },
          ],
        },
      ],
      activeSignature: 0,
      activeParameter: 0,
    });
  });

  it("can return documentation for the function being applied", async () => {
    openDocument(
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

      let _ = div 1
    `,
    );

    let items = await querySignatureHelp(Types.Position.create(23, 13));
    expect(items).toMatchObject({
      activeSignature: 0,
      activeParameter: 0,
      signatures: [
        {
          label: "div : int -> int -> int",
          parameters: [
            {
              label: [6, 9],
            },
            {
              label: [13, 16],
            },
          ],
          documentation: {
            kind: "markdown",
            value: outdent`
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
        },
      ],
    });
  });
});
