open Import

let code_action (_mode : [ `Qualify | `Unqualify ]) (_action_kind : string) _doc
    (_params : CodeActionParams.t) =
  failwith "Action_refactor_open.code_action"

let unqualify =
  let action_kind = "remove module name from identifiers" in
  { Code_action.action_kind; run = code_action `Unqualify action_kind }

let qualify =
  let action_kind = "put module name in identifiers" in
  { Code_action.action_kind; run = code_action `Qualify action_kind }
