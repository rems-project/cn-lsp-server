open Import

let action_kind = "type-annotate"

let check_typeable_context _pipeline _pos_start =
  failwith "Action_type_annotate.check_typeable_context"

let get_source_text _doc (_loc : Loc.t) =
  failwith "Action_type_annotate.get_source_text"

let code_action_of_type_enclosing uri doc (loc, typ) =
  let open Option.O in
  let+ original_text = get_source_text doc loc in
  let newText = Printf.sprintf "(%s : %s)" original_text typ in
  let edit : WorkspaceEdit.t =
    let textedit : TextEdit.t = { range = Range.of_loc loc; newText } in
    let version = Document.version doc in
    let textDocument =
      OptionalVersionedTextDocumentIdentifier.create ~uri ~version ()
    in
    let edit =
      TextDocumentEdit.create ~textDocument ~edits:[ `TextEdit textedit ]
    in
    WorkspaceEdit.create ~documentChanges:[ `TextDocumentEdit edit ] ()
  in
  let title = String.capitalize_ascii action_kind in
  CodeAction.create ~title ~kind:(CodeActionKind.Other action_kind) ~edit
    ~isPreferred:false ()

let code_action doc (params : CodeActionParams.t) =
  let open Fiber.O in
  let pos_start = Position.logical params.range.start in
  let+ res =
    Document.with_pipeline doc (fun pipeline ->
        let context = check_typeable_context pipeline pos_start in
        match context with
        | `Invalid -> None
        | `Valid -> failwith "Action_type_annotate.code_action:`Valid")
  in
  match res with
  | Error e -> Exn_with_backtrace.reraise e
  | Ok None
  | Ok (Some [])
  | Ok (Some ((_, `Index _, _) :: _)) ->
    None
  | Ok (Some ((location, `String value, _) :: _)) ->
    code_action_of_type_enclosing params.textDocument.uri doc (location, value)
