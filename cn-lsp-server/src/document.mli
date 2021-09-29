open Import

type t

val make :
     Scheduler.timer
  -> Scheduler.thread
  -> DidOpenTextDocumentParams.t
  -> t Fiber.t

val timer : t -> Scheduler.timer

val uri : t -> Uri.t

val source : t -> string

val with_pipeline :
  t -> (Mpipeline.t -> 'a) -> ('a, Exn_with_backtrace.t) result Fiber.t

val with_pipeline_exn : t -> (Mpipeline.t -> 'a) -> 'a Fiber.t

val version : t -> int

val update_text :
  ?version:int -> t -> TextDocumentContentChangeEvent.t list -> t Fiber.t

val dispatch :
  t -> 'a Query_protocol.t -> ('a, Exn_with_backtrace.t) result Fiber.t

val dispatch_exn : t -> 'a Query_protocol.t -> 'a Fiber.t

val close : t -> unit Fiber.t

(** [get_impl_intf_counterparts uri] returns the implementation/interface
    counterparts for the URI [uri].

    For instance, the counterparts of the file [/file.ml] are [/file.mli]. *)
val get_impl_intf_counterparts : Uri.t -> Uri.t list
