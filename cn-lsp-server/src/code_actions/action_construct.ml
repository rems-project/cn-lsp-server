open Import

let action_kind = "construct"

let code_action doc (_params : CodeActionParams.t) =
  match Document.kind doc with
  | Intf -> Fiber.return None
  | Impl ->
    failwith "Action_construct.code_action:Impl"
