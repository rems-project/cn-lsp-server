(*============================================================================*)
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
