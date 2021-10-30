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

import { assert } from "console";
import { promises as fs } from "fs";
import * as path from "path";
import { DocumentUri, TextDocumentItem } from "vscode-languageserver-types";
import { URI } from "vscode-uri";
import * as LanguageServer from "./../src/LanguageServer";

describe("ocamllsp/switchImplIntf", () => {
  let languageServer: LanguageServer.LanguageServer = null;

  async function openDocument(documentUri: DocumentUri) {
    languageServer.sendNotification("textDocument/didOpen", {
      textDocument: TextDocumentItem.create(documentUri, "ocaml", 0, ""),
    });
  }

  /* sends request "ocamllsp/switchImplIntf" */
  async function ocamllspSwitchImplIntf(
    documentUri: DocumentUri,
  ): Promise<Array<DocumentUri>> {
    return languageServer.sendRequest("ocamllsp/switchImplIntf", documentUri);
  }

  let testWorkspacePath = path.join(__dirname, "..", "test_files/");

  beforeEach(async () => {
    languageServer = await LanguageServer.startAndInitialize();
    await fs.rmdir(testWorkspacePath, { recursive: true });
    await fs.mkdir(testWorkspacePath);
  });

  afterEach(async () => {
    await fs.rmdir(testWorkspacePath, { recursive: true });
    await LanguageServer.exit(languageServer);
    languageServer = null;
  });

  let createPathForFile = (filename: string) =>
    path.join(testWorkspacePath, filename);

  let createFileAtPath = (path: string) =>
    fs.writeFile(path, "", { flag: "a+" });

  let pathToDocumentUri = (path: string): DocumentUri =>
    URI.file(path).toString();

  let [mli, ml, mll, mly, rei, re] = ["mli", "ml", "mll", "mly", "rei", "re"];

  let testRequest = async (
    requestParam: DocumentUri,
    expectedResponse: DocumentUri[],
  ) => {
    let response = await ocamllspSwitchImplIntf(requestParam);
    expect(response).toEqual(expectedResponse);
  };

  /**
   * For testing 'ocamllsp/switchImplIntf'
   *
   * @param extsForCreation file name extension for files to be created in
   *    (test) workspace folder. The first file created (even if only one file
   *    is created) is treated as the file a user wants to switch from.
   * @param extExpected file name extensions that are expected to be returned as
   *    a reponse to 'ocamllsp/switchImplIntf'
   */
  let testingPipeline = async (
    extsForCreation: string[],
    extExpected: string[],
  ) => {
    assert(
      extsForCreation.length > 0,
      "extensions for creation should not be empty",
    );
    assert(
      extExpected.length > 0,
      "expected response extensions should not be empty",
    );

    let filePathsForCreation = extsForCreation.map((ext) => {
      let filename = "test.".concat(ext);
      return createPathForFile(filename);
    });

    await Promise.all(filePathsForCreation.map(createFileAtPath));

    let filePathToSwitchFrom = filePathsForCreation[0];
    let fileURIToSwitchFrom = pathToDocumentUri(filePathToSwitchFrom);
    await openDocument(fileURIToSwitchFrom);

    let expectedFileURIs = extExpected.map((ext) => {
      let filename = "test.".concat(ext);
      let filePath = createPathForFile(filename);
      return pathToDocumentUri(filePath);
    });

    await testRequest(fileURIToSwitchFrom, expectedFileURIs);
  };

  /* `create`, `expect`, and `test_case` are for declarativeness */
  let varargFn = <T>(...args: T[]): T[] => args;
  let createFiles = varargFn;
  let expectSwitchTo = varargFn;
  let testCase = (filesToCreate: string[], filesToExpect: string[]) => [
    filesToCreate,
    filesToExpect,
  ];

  test.each([
    testCase(createFiles(mli), expectSwitchTo(ml)),
    testCase(createFiles(mli, ml), expectSwitchTo(ml)),
    testCase(createFiles(ml), expectSwitchTo(mli)),
    testCase(createFiles(ml, mli), expectSwitchTo(mli)),
    testCase(createFiles(mli, mll), expectSwitchTo(mll)),
    testCase(createFiles(mli, ml, mll), expectSwitchTo(ml, mll)),
  ])("test switches (%s => %s)", testingPipeline);

  it("can switch from file URI with non-file scheme", async () => {
    let mlFpath = createPathForFile("test.ml");
    await createFileAtPath(mlFpath);
    let mlUri = pathToDocumentUri(mlFpath);

    let newMliFpath = createPathForFile("test.mli");
    await createFileAtPath(newMliFpath);
    let mliUriUntitledScheme: DocumentUri = URI.file(newMliFpath)
      .with({
        scheme: "untitled",
      })
      .toString();

    testRequest(mliUriUntitledScheme, [mlUri]);
  });
});
