(*============================================================================*)
(*  The following parts of CN LSP Server contain new code released under the  *)
(*  BSD 2-Clause License:                                                     *)
(*  * `src/cn.ml`                                                             *)
(*                                                                            *)
(*  Copyright (c) 2021 Dhruv Makwana                                          *)
(*  All rights reserved.                                                      *)
(*                                                                            *)
(*  This software was developed by the University of Cambridge Computer       *)
(*  Laboratory as part of the Rigorous Engineering of Mainstream Systems      *)
(*  (REMS) project. This project has been partly funded by an EPSRC           *)
(*  Doctoral Training studentship. This project has been partly funded by     *)
(*  Google. This project has received funding from the European Research      *)
(*  Council (ERC) under the European Union's Horizon 2020 research and        *)
(*  innovation programme (grant agreement No 789108, Advanced Grant           *)
(*  ELVER).                                                                   *)
(*                                                                            *)
(*  BSD 2-Clause License                                                      *)
(*                                                                            *)
(*  Redistribution and use in source and binary forms, with or without        *)
(*  modification, are permitted provided that the following conditions        *)
(*  are met:                                                                  *)
(*  1. Redistributions of source code must retain the above copyright         *)
(*     notice, this list of conditions and the following disclaimer.          *)
(*  2. Redistributions in binary form must reproduce the above copyright      *)
(*     notice, this list of conditions and the following disclaimer in        *)
(*     the documentation and/or other materials provided with the             *)
(*     distribution.                                                          *)
(*                                                                            *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''        *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED         *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A           *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR       *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,              *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT          *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF          *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND       *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,        *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT        *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF        *)
(*  SUCH DAMAGE.                                                              *)
(*                                                                            *)
(*  All other parts on CN LSP Server are released under a mixed BSD-2-Clause  *)
(*  and ISC license.                                                          *)
(*                                                                            *)
(*  ISC License                                                               *)
(*                                                                            *)
(*  Copyright (X) 2018-2019, the [ocaml-lsp                                   *)
(*  contributors](https://github.com/ocaml/ocaml-lsp/graphs/contributors)     *)
(*                                                                            *)
(*  Permission to use, copy, modify, and distribute this software for any     *)
(*  purpose with or without fee is hereby granted, provided that the above    *)
(*  copyright notice and this permission notice appear in all copies.         *)
(*                                                                            *)
(*  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  *)
(*  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF          *)
(*  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR   *)
(*  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    *)
(*  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN     *)
(*  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF   *)
(*  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.            *)
(*============================================================================*)

open Import

let infer_intf_for_impl _doc = failwith "Inference.infer_intf_for_impl"

let language_id_of_fname s =
  match Filename.extension s with
  | ".c"
  | ".h" ->
    "c"
  | ext ->
    Code_error.raise "unsupported file extension" [ ("extension", String ext) ]

let force_open_document (state : State.t) uri =
  let open Fiber.O in
  let filename = Uri.to_path uri in
  let text = Io.String_path.read_file filename in
  let delay = Configuration.diagnostics_delay state.configuration in
  let* timer = Scheduler.create_timer ~delay in
  let languageId = language_id_of_fname filename in
  let text_document =
    Lsp.Types.TextDocumentItem.create ~uri ~languageId ~version:0 ~text
  in
  let params = DidOpenTextDocumentParams.create ~textDocument:text_document in
  let+ doc = Document.make timer state.merlin params in
  Document_store.put state.store doc;
  doc

let infer_intf ~force_open_impl (state : State.t) doc =
  let open Fiber.O in
  let intf_uri = Document.uri doc in
  let impl_uri = Document.get_impl_intf_counterparts intf_uri |> List.hd in
  let* impl =
    match (Document_store.get_opt state.store impl_uri, force_open_impl) with
    | None, false ->
      Code_error.raise
        "The implementation for this interface has not been open." []
    | None, true -> force_open_document state impl_uri
    | Some impl, _ -> Fiber.return impl
  in
  infer_intf_for_impl impl
