open! Import

type t =
  { tdoc : Text_document.t
  ; merlin : Scheduler.thread
  ; timer : Scheduler.timer
  }

let uri doc = Text_document.documentUri doc.tdoc

let timer t = t.timer

let source doc = Text_document.text doc.tdoc

let with_pipeline (_doc : t) _f =
  failwith "Documnet.with_pipeline"

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
