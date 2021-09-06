/******************************************************************************/
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

import * as Protocol from "vscode-languageserver-protocol";

import * as LanguageServer from "./../src/LanguageServer";

test("basic", async () => {
  let languageServer = LanguageServer.start();
  await LanguageServer.exit(languageServer);
});

test("initialize with empty capabilities", async () => {
  let languageServer = LanguageServer.start();

  let capabilities: Protocol.ClientCapabilities = {};

  let initializeParameters: Protocol.InitializeParams = {
    processId: process.pid,
    rootUri: LanguageServer.toURI(__dirname),
    capabilities: capabilities,
    workspaceFolders: [],
  };

  let result = await languageServer.sendRequest(
    Protocol.InitializeRequest.type,
    initializeParameters,
  );

  expect(result.capabilities).toBeTruthy();
  await LanguageServer.exit(languageServer);
});
