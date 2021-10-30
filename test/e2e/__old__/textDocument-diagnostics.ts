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

import * as Types from "vscode-languageserver-types";

describe("textDocument/diagnostics", () => {
  let languageServer: rpc.MessageConnection = null;

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

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize();
  });

  afterEach(async () => {
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
                "message": "This comment contains an unterminated string literal",
                "range": Object {
                  "end": Object {
                    "character": 2,
                    "line": 0,
                  },
                  "start": Object {
                    "character": 0,
                    "line": 0,
                  },
                },
                "relatedInformation": Array [
                  Object {
                    "location": Object {
                      "range": Object {
                        "end": Object {
                          "character": 4,
                          "line": 0,
                        },
                        "start": Object {
                          "character": 3,
                          "line": 0,
                        },
                      },
                      "uri": "file:///test.ml",
                    },
                    "message": "String literal begins here",
                  },
                ],
                "severity": 1,
                "source": "ocamllsp",
              },
            ],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );
    await openDocument(outdent`
(* " *)
    `);
    await receivedDiganostics;
  });

  it("unused values have diagnostic tags", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [
              Object {
                "message": "Warning 26: unused variable x.",
                "range": Object {
                  "end": Object {
                    "character": 7,
                    "line": 1,
                  },
                  "start": Object {
                    "character": 6,
                    "line": 1,
                  },
                },
                "severity": 2,
                "source": "ocamllsp",
              },
            ],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );
    await openDocument(outdent`
      let () =
        let x = 123 in
        ()
    `);
    await receivedDiganostics;
  });

  it("deprecated values have diganostic tags", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [
              Object {
                "message": "Alert deprecated: X.x
          do not use",
                "range": Object {
                  "end": Object {
                    "character": 19,
                    "line": 6,
                  },
                  "start": Object {
                    "character": 16,
                    "line": 6,
                  },
                },
                "severity": 2,
                "source": "ocamllsp",
              },
            ],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );
    await openDocument(outdent`
      module X : sig
        val x : unit
        [@@ocaml.deprecated "do not use"]
      end = struct
        let x = ()
      end
      let () = ignore X.x
    `);
    await receivedDiganostics;
  });

  it("related diagnostics for mismatched signatures", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [
              Object {
                "message": "Signature mismatch:
          Modules do not match:
            sig val x : int end
          is not included in
            sig val x : unit end
          Values do not match: val x : int is not included in val x : unit",
                "range": Object {
                  "end": Object {
                    "character": 3,
                    "line": 4,
                  },
                  "start": Object {
                    "character": 6,
                    "line": 2,
                  },
                },
                "relatedInformation": Array [
                  Object {
                    "location": Object {
                      "range": Object {
                        "end": Object {
                          "character": 14,
                          "line": 2,
                        },
                        "start": Object {
                          "character": 2,
                          "line": 2,
                        },
                      },
                      "uri": "file:///test.ml",
                    },
                    "message": "Expected declaration",
                  },
                  Object {
                    "location": Object {
                      "range": Object {
                        "end": Object {
                          "character": 7,
                          "line": 4,
                        },
                        "start": Object {
                          "character": 6,
                          "line": 4,
                        },
                      },
                      "uri": "file:///test.ml",
                    },
                    "message": "Actual declaration",
                  },
                ],
                "severity": 1,
                "source": "ocamllsp",
              },
            ],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );
    await openDocument(outdent`
      module X : sig
        val x : unit
      end = struct
        let x = 123
      end
    `);
    await receivedDiganostics;
  });

  it("no diagnostics for valid files", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );

    await openDocument(outdent`
      let num = 42
    `);

    await receivedDiganostics;
  });

  it("should have diagnostics for a hole only", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [
              Object {
                "code": "hole",
                "message": "This typed hole should be replaced with an expression of type int",
                "range": Object {
                  "end": Object {
                    "character": 15,
                    "line": 0,
                  },
                  "start": Object {
                    "character": 14,
                    "line": 0,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
            ],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );

    await openDocument(outdent`
      let a : int = _
    `);

    await receivedDiganostics;
  });

  it("should have diagnostics for holes only", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [
              Object {
                "code": "hole",
                "message": "This typed hole should be replaced with an expression of type int",
                "range": Object {
                  "end": Object {
                    "character": 16,
                    "line": 0,
                  },
                  "start": Object {
                    "character": 15,
                    "line": 0,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
              Object {
                "message": "Warning 26: unused variable b.",
                "range": Object {
                  "end": Object {
                    "character": 5,
                    "line": 1,
                  },
                  "start": Object {
                    "character": 4,
                    "line": 1,
                  },
                },
                "severity": 2,
                "source": "ocamllsp",
              },
              Object {
                "code": "hole",
                "message": "This typed hole should be replaced with an expression of type string",
                "range": Object {
                  "end": Object {
                    "character": 44,
                    "line": 1,
                  },
                  "start": Object {
                    "character": 43,
                    "line": 1,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
              Object {
                "code": "hole",
                "message": "This typed hole should be replaced with an expression of type string",
                "range": Object {
                  "end": Object {
                    "character": 58,
                    "line": 1,
                  },
                  "start": Object {
                    "character": 57,
                    "line": 1,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
            ],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );

    await openDocument(outdent`
      let _a : int = _ in
      let b : string = match Some 1 with None -> _ | Some _ -> _ in
      ()
    `);

    await receivedDiganostics;
  });

  it("different diagnostics, including holes, sorted by range", async () => {
    let receivedDiganostics = new Promise((resolve, _reject) =>
      languageServer.onNotification((method, params) => {
        expect(method).toMatchInlineSnapshot(
          `"textDocument/publishDiagnostics"`,
        );
        expect(params).toMatchInlineSnapshot(`
          Object {
            "diagnostics": Array [
              Object {
                "message": "This expression has type unit but an expression was expected of type int",
                "range": Object {
                  "end": Object {
                    "character": 42,
                    "line": 1,
                  },
                  "start": Object {
                    "character": 40,
                    "line": 1,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
              Object {
                "code": "hole",
                "message": "This typed hole should be replaced with an expression of type 'a",
                "range": Object {
                  "end": Object {
                    "character": 12,
                    "line": 3,
                  },
                  "start": Object {
                    "character": 11,
                    "line": 3,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
              Object {
                "code": "hole",
                "message": "This typed hole should be replaced with an expression of type 'a",
                "range": Object {
                  "end": Object {
                    "character": 12,
                    "line": 4,
                  },
                  "start": Object {
                    "character": 11,
                    "line": 4,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
              Object {
                "message": "This expression has type string but an expression was expected of type int",
                "range": Object {
                  "end": Object {
                    "character": 9,
                    "line": 5,
                  },
                  "start": Object {
                    "character": 6,
                    "line": 5,
                  },
                },
                "severity": 1,
                "source": "ocamllsp",
              },
            ],
            "uri": "file:///test.ml",
          }
        `);
        resolve(null);
      }),
    );

    await openDocument(outdent`
      let _u =
        let _i = List.map (fun i -> i) [1; 2; ()] in
        let b = 234 in
        let _k = _ in
        let _c = _ in
        b + "a"
    `);

    await receivedDiganostics;
  });
});
