open Import

type init =
  | Uninitialized
  | Initialized of InitializeParams.t

type t =
  { store : Document_store.t
  ; merlin : Scheduler.thread (* remove? *)
  ; init : init
  ; detached : Fiber.Pool.t
  ; configuration : Configuration.t
  ; trace : TraceValue.t
  ; ocamlformat : Fmt.t (* remove *)
  ; diagnostics : Diagnostics.t (* remove *)
  ; symbols_thread : Scheduler.thread Lazy_fiber.t
  }

val workspace_root : t -> Uri.t
