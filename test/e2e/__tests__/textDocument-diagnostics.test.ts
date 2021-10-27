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
                  "href": "file:///tmp/cn-lsp-server-diagnostic-test.c",
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
