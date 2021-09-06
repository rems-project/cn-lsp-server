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

open! Import

type t =
  { tdoc : Text_document.t
  ; merlin : Scheduler.thread
  ; timer : Scheduler.timer
  }

let uri doc = Text_document.documentUri doc.tdoc

let timer t = t.timer

let source doc = Text_document.text doc.tdoc

let with_pipeline (_doc : t) _f = failwith "Documnet.with_pipeline"

let with_pipeline_exn doc f =
  let open Fiber.O in
  let+ res = with_pipeline doc f in
  match res with
  | Ok s -> s
  | Error exn -> Exn_with_backtrace.reraise exn

let version doc = Text_document.version doc.tdoc

let make timer merlin_thread tdoc =
  let tdoc = Text_document.make tdoc in
  (* we can do that b/c all text positions in LSP are line/col *)
  Fiber.return { tdoc; merlin = merlin_thread; timer }

let update_text ?version doc changes =
  let tdoc =
    List.fold_left changes ~init:doc.tdoc ~f:(fun acc change ->
        Text_document.apply_content_change ?version acc change)
  in
  Fiber.return { doc with tdoc }

let dispatch (doc : t) _command =
  with_pipeline doc (failwith "Document.dispatch")

let dispatch_exn (doc : t) _command =
  with_pipeline_exn doc (failwith "Document.dispatch_exn")

let close t = Scheduler.cancel_timer t.timer

let get_impl_intf_counterparts _uri =
  failwith "Document.get_impl_intf_counterparts"
