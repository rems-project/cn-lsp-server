open Import

let init_params (state : State.t) =
  match state.init with
  | Uninitialized -> assert false
  | Initialized init -> init

let client_capabilities (state : State.t) = (init_params state).capabilities

let make_error = Jsonrpc.Response.Error.make

let not_supported () =
  Jsonrpc.Response.Error.raise
    (make_error ~code:InternalError ~message:"Request not supported yet!" ())

let initialize_info : InitializeResult.t =
  (* let codeActionProvider = let codeActionKinds = [ CodeActionKind.Other
     Action_destruct.action_kind ; CodeActionKind.Other
     Action_inferred_intf.action_kind ; CodeActionKind.Other
     Action_type_annotate.action_kind ; CodeActionKind.Other
     Action_construct.action_kind ; CodeActionKind.Other
     Action_refactor_open.unqualify.action_kind ; CodeActionKind.Other
     Action_refactor_open.qualify.action_kind ; CodeActionKind.QuickFix ] in
     `CodeActionOptions (CodeActionOptions.create ~codeActionKinds ()) in let
     codeLensProvider = CodeLensOptions.create ~resolveProvider:false () in let
     completionProvider = (* TODO even if this re-enabled in general, it should
     stay disabled for emacs. It makes completion too slow *)
     CompletionOptions.create ~triggerCharacters:[ "."; "#" ]
     ~resolveProvider:true () in let signatureHelpProvider =
     SignatureHelpOptions.create ~triggerCharacters:[ " "; "~"; "?"; ":"; "(" ]
     () in let renameProvider = `RenameOptions (RenameOptions.create
     ~prepareProvider:true ()) in *)
  let textDocumentSync =
    `TextDocumentSyncOptions
      (TextDocumentSyncOptions.create ~openClose:true
         ~change:TextDocumentSyncKind.Incremental ~willSave:false
         ~save:(`Bool true) ~willSaveWaitUntil:false ())
  in
  let capabilities =
    (* let experimental = `Assoc [ ( "ocamllsp" , `Assoc [
       ("interfaceSpecificLangId", `Bool true) ; Req_switch_impl_intf.capability
       ; Req_infer_intf.capability ; Req_typed_holes.capability ;
       Req_wrapping_ast_node.capability ] ) ] in *)
    ServerCapabilities.create ~textDocumentSync
      (* ~hoverProvider:(`Bool true) ~declarationProvider:(`Bool true)
         ~definitionProvider:(`Bool true) ~typeDefinitionProvider:(`Bool true)
         ~completionProvider ~signatureHelpProvider ~codeActionProvider
         ~codeLensProvider ~referencesProvider:(`Bool true)
         ~documentHighlightProvider:(`Bool true)
         ~documentFormattingProvider:(`Bool true) ~selectionRangeProvider:(`Bool
         true) ~documentSymbolProvider:(`Bool true)
         ~workspaceSymbolProvider:(`Bool true) ~foldingRangeProvider:(`Bool
         true) ~experimental ~renameProvider *)
      ()
  in
  let serverInfo =
    let version = Version.get () in
    InitializeResult.create_serverInfo ~name:"cnlsp" ~version ()
  in
  InitializeResult.create ~capabilities ~serverInfo ()

let task_if_running (state : State.t) ~f =
  let open Fiber.O in
  let* running = Fiber.Pool.running state.detached in
  match running with
  | false -> Fiber.return ()
  | true -> Fiber.Pool.task state.detached ~f

let set_diagnostics rpc doc =
  let state : State.t = Server.state rpc in
  let uri = Document.uri doc in
  let async send =
    let open Fiber.O in
    let+ () =
      task_if_running state ~f:(fun () ->
          let open Fiber.O in
          let timer = Document.timer doc in
          let+ res = Scheduler.schedule timer send in
          match res with
          | Error `Cancelled
          | Ok () ->
            ())
    in
    ()
  in
  async (fun () ->
      let diagnostics = Cn.get_errs doc in
      Diagnostics.set state.diagnostics (`Merlin (uri, diagnostics));
      Diagnostics.send state.diagnostics)

let on_initialize rpc (ip : InitializeParams.t) =
  let state : State.t = Server.state rpc in
  let state = { state with init = Initialized ip } in
  let state =
    match ip.trace with
    | None -> state
    | Some trace -> { state with trace }
  in
  (initialize_info, state)

let code_action (state : State.t) (params : CodeActionParams.t) =
  let open Fiber.O in
  let store = state.store in
  let uri = params.textDocument.uri in
  let* doc = Fiber.return (Document_store.get store uri) in
  let code_action (kind, f) =
    match params.context.only with
    | Some set when not (List.mem set kind ~equal:Poly.equal) ->
      Fiber.return None
    | Some _
    | None ->
      let+ action_opt = f () in
      Option.map action_opt ~f:(fun action_opt -> `CodeAction action_opt)
  in
  let open Fiber.O in
  let+ code_action_results =
    Fiber.parallel_map ~f:code_action
      [ ( CodeActionKind.Other Action_destruct.action_kind
        , fun () -> Action_destruct.code_action doc params )
      ; ( CodeActionKind.Other Action_inferred_intf.action_kind
        , fun () -> Action_inferred_intf.code_action doc state params )
      ; ( CodeActionKind.Other Action_type_annotate.action_kind
        , fun () -> Action_type_annotate.code_action doc params )
      ; ( CodeActionKind.Other Action_construct.action_kind
        , fun () -> Action_construct.code_action doc params )
      ; ( CodeActionKind.Other Action_refactor_open.unqualify.action_kind
        , fun () -> Action_refactor_open.unqualify.run doc params )
      ; ( CodeActionKind.Other Action_refactor_open.qualify.action_kind
        , fun () -> Action_refactor_open.qualify.run doc params )
      ]
  in
  let code_action_results = List.filter_opt code_action_results in
  match code_action_results with
  | [] -> None
  | l -> Some l

module Formatter = struct
  let jsonrpc_error (e : Fmt.error) =
    let message = Fmt.message e in
    let code : Jsonrpc.Response.Error.Code.t =
      match e with
      | Unknown_extension _
      | Missing_binary _ ->
        InvalidRequest
      | Unexpected_result _ -> InternalError
    in
    make_error ~code ~message ()

  let run rpc doc =
    let open Fiber.O in
    let state = Server.state rpc in
    let* res = Fmt.run state.State.ocamlformat doc in
    match res with
    | Result.Error e ->
      let message = Fmt.message e in
      let error = jsonrpc_error e in
      let msg = ShowMessageParams.create ~message ~type_:Warning in
      let open Fiber.O in
      let+ () =
        let state : State.t = Server.state rpc in
        task_if_running state ~f:(fun () ->
            Server.notification rpc (ShowMessage msg))
      in
      Jsonrpc.Response.Error.raise error
    | Result.Ok result -> Fiber.return (Some result)
end

let markdown_support (client_capabilities : ClientCapabilities.t) ~field =
  match client_capabilities.textDocument with
  | None -> false
  | Some td -> (
    match field td with
    | None -> false
    | Some format ->
      let set = Option.value format ~default:[ MarkupKind.Markdown ] in
      List.mem set MarkupKind.Markdown ~equal:Poly.equal)

let format_contents ~markdown ~typ ~doc =
  let markdown_name = "c" in
  `MarkupContent
    (if markdown then
      let value =
        match doc with
        | None -> sprintf "```%s\n%s\n```" markdown_name typ
        | Some s ->
          let doc =
            match Doc_to_md.translate s with
            | Raw d -> sprintf "(** %s *)" d
            | Markdown d -> d
          in
          sprintf "```%s\n%s\n```\n---\n%s" markdown_name typ doc
      in
      { MarkupContent.value; kind = MarkupKind.Markdown }
    else
      let value =
        match doc with
        | None -> sprintf "%s" typ
        | Some d -> sprintf "%s\n%s" typ d
      in
      { MarkupContent.value; kind = MarkupKind.PlainText })

let query_doc _doc _pos = failwith "Cn_lsp_server.query_doc"

let query_type _doc _pos = failwith "Cn_lsp_server.query_type"

let hover _server (state : State.t)
    { HoverParams.textDocument = { uri }; position; _ } =
  let store = state.store in
  let doc = Document_store.get store uri in
  let pos = Position.logical position in
  let client_capabilities = client_capabilities state in
  let open Fiber.O in
  (* TODO we shouldn't acquiring the merlin thread twice per request *)
  let* query_type = query_type doc pos in
  match query_type with
  | None -> Fiber.return None
  | Some (loc, typ) ->
    let+ doc = query_doc doc pos in
    let contents =
      let markdown =
        markdown_support client_capabilities ~field:(fun td ->
            Option.map td.hover ~f:(fun h -> h.contentFormat))
      in
      format_contents ~markdown ~typ ~doc
    in
    let range = Range.of_loc loc in
    let resp = Hover.create ~contents ~range () in
    Some resp

let signature_help (_state : State.t) = failwith "Cn_lsp_server.signature_help"

let text_document_lens (state : State.t)
    { CodeLensParams.textDocument = { uri }; _ } =
  let store = state.store in
  let _doc = Document_store.get store uri in
  failwith "Cn_lsp_server.text_document_lens"

let folding_range (_state : State.t)
    { FoldingRangeParams.textDocument = { uri = _ }; _ } =
  failwith "Cn_lsp_server.folding_range"

let rename (_state : State.t)
    { RenameParams.textDocument = { uri = _ }; position = _; newName = _; _ } =
  failwith "Cn_lsp_server.rename"

let selection_range (_state : State.t)
    { SelectionRangeParams.textDocument = { uri = _ }; positions = _; _ } =
  failwith "Cn_lsp_server.selection_range"

let references (_state : State.t)
    { ReferenceParams.textDocument = { uri = _ }; position = _; _ } =
  failwith "Cn_lsp_server.references"

let workspace_symbol server (state : State.t) (params : WorkspaceSymbolParams.t)
    =
  let open Fiber.O in
  let* symbols, errors =
    let workspaces =
      let init_params = init_params state in
      (* WorkspaceFolders has the most priority. Then rootUri and finally
         rootPath *)
      let root_uri = init_params.rootUri in
      let root_path = init_params.rootPath in
      match (init_params.workspaceFolders, root_uri, root_path) with
      | Some (Some workspace_folders), _, _ -> workspace_folders
      | _, Some root_uri, _ ->
        [ WorkspaceFolder.create ~uri:root_uri
            ~name:(Filename.basename (Uri.to_path root_uri))
        ]
      | _, _, Some (Some root_path) ->
        [ WorkspaceFolder.create ~uri:(Uri.of_path root_path)
            ~name:(Filename.basename root_path)
        ]
      | _ ->
        let cwd = Sys.getcwd () in
        [ WorkspaceFolder.create ~uri:(Uri.of_path cwd)
            ~name:(Filename.basename cwd)
        ]
    in
    let* thread = Lazy_fiber.force state.symbols_thread in
    let+ symbols_results =
      let+ res =
        Scheduler.async_exn thread (fun () ->
            Workspace_symbol.run params workspaces)
        |> Scheduler.await_no_cancel
      in
      match res with
      | Ok s -> s
      | Error exn -> Exn_with_backtrace.reraise exn
    in
    List.partition_map symbols_results ~f:(function
      | Ok r -> Left r
      | Error e -> Right e)
  in
  let open Fiber.O in
  let+ () =
    match errors with
    | [] -> Fiber.return ()
    | _ :: _ ->
      let msg =
        let message =
          List.map errors ~f:(function
              | Workspace_symbol.Build_dir_not_found workspace_name ->
              workspace_name)
          |> String.concat ~sep:", "
          |> sprintf "No build directory found in workspace(s): %s"
        in
        ShowMessageParams.create ~message ~type_:Warning
      in
      task_if_running state ~f:(fun () ->
          Server.notification server (ShowMessage msg))
  in
  Some (List.concat symbols)

let highlight (_state : State.t)
    { DocumentHighlightParams.textDocument = { uri = _ }; position = _; _ } =
  failwith "Cn_lsp_server.highlight"

let document_symbol (_state : State.t) _uri =
  failwith "Cn_lsp_server.document_symbol"

(** handles requests for OCaml (syntax) documents *)
let ocaml_on_request :
    type resp.
       State.t Server.t
    -> resp Client_request.t
    -> (resp Reply.t * State.t) Fiber.t =
 fun rpc req ->
  let state = Server.state rpc in
  let store = state.store in
  let now res = Fiber.return (Reply.now res, state) in
  let later f req =
    Fiber.return
      ( Reply.later (fun k ->
            let open Fiber.O in
            let* resp = f state req in
            k resp)
      , state )
  in
  match req with
  | Initialize ip ->
    let res, state = on_initialize rpc ip in
    Fiber.return (Reply.now res, state)
  | Shutdown -> now ()
  | DebugTextDocumentGet { textDocument = { uri }; position = _ } -> (
    match Document_store.get_opt store uri with
    | None -> now None
    | Some doc -> now (Some (Document.source doc)))
  | DebugEcho params -> now params
  | TextDocumentColor _ -> now []
  | TextDocumentColorPresentation _ -> now []
  | TextDocumentHover req -> later (fun state () -> hover rpc state req) ()
  | TextDocumentReferences req -> later references req
  | TextDocumentCodeLensResolve codeLens -> now codeLens
  | TextDocumentCodeLens req -> later text_document_lens req
  | TextDocumentHighlight req -> later highlight req
  | WorkspaceSymbol req ->
    later (fun state () -> workspace_symbol rpc state req) ()
  | DocumentSymbol { textDocument = { uri }; _ } -> later document_symbol uri
  | TextDocumentDeclaration { textDocument = { uri = _ }; position = _ } ->
    failwith "TODO: Cn_lsp_server.ocaml_on_request:TextDocumentDeclaration"
  | TextDocumentDefinition { textDocument = { uri = _ }; position = _; _ } ->
    failwith "TODO: Cn_lsp_server.ocaml_on_request:TextDocumentDefinition"
  | TextDocumentTypeDefinition { textDocument = { uri = _ }; position = _; _ }
    ->
    failwith "TODO Cn_lsp_server.ocaml_on_request:TextDocumentTypeDefinition"
  | TextDocumentCompletion { textDocument = { uri = _ }; position = _; _ } ->
    failwith "TODO: Cn_lsp_server.ocaml_on_request:TextDocumentCompletion"
  | TextDocumentPrepareRename { textDocument = { uri = _ }; position = _ } ->
    failwith "TODO: Cn_lsp_server.ocaml_on_request:TextDocumentPrepareRename"
  | TextDocumentRename req -> later rename req
  | TextDocumentFoldingRange req -> later folding_range req
  | SignatureHelp req -> later signature_help req
  | ExecuteCommand _ -> not_supported ()
  | TextDocumentLinkResolve l -> now l
  | TextDocumentLink _ -> now None
  | WillSaveWaitUntilTextDocument _ -> now None
  | CodeAction params -> later code_action params
  | CodeActionResolve ca -> now ca
  | CompletionItemResolve _ci ->
    failwith "TODO: Cn_lsp_server.ocaml_on_request:CompletionItemResolve"
  | TextDocumentFormatting { textDocument = { uri }; options = _; _ } ->
    later
      (fun _ () ->
        let doc = Document_store.get store uri in
        Formatter.run rpc doc)
      ()
  | TextDocumentOnTypeFormatting _ -> now None
  | SelectionRange req -> later selection_range req
  | TextDocumentMoniker _ -> not_supported ()
  | SemanticTokensFull _ -> not_supported ()
  | SemanticTokensDelta _ -> not_supported ()
  | SemanticTokensRange _ -> not_supported ()
  | LinkedEditingRange _ -> not_supported ()
  | UnknownRequest _ ->
    Jsonrpc.Response.Error.raise
      (make_error ~code:InvalidRequest ~message:"Got unknown request" ())

let on_request :
    type resp.
       State.t Server.t
    -> resp Client_request.t
    -> (resp Reply.t * State.t) Fiber.t =
 fun server req ->
  let state : State.t = Server.state server in
  match req with
  | Client_request.UnknownRequest { meth; params } -> (
    match
      [ (Req_switch_impl_intf.meth, Req_switch_impl_intf.on_request)
      ; (Req_infer_intf.meth, Req_infer_intf.on_request)
      ; (Req_typed_holes.meth, Req_typed_holes.on_request)
      ; (Req_wrapping_ast_node.meth, Req_wrapping_ast_node.on_request)
      ]
      |> List.assoc_opt meth
    with
    | None ->
      Jsonrpc.Response.Error.raise
        (make_error ~code:InternalError ~message:"Unknown method"
           ~data:(`Assoc [ ("method", `String meth) ])
           ())
    | Some handler ->
      Fiber.return
        ( Reply.later (fun send ->
              let open Fiber.O in
              let* res = handler ~params state in
              send res)
        , state ))
  | _ -> ocaml_on_request server req

let on_notification server (notification : Client_notification.t) :
    State.t Fiber.t =
  let state : State.t = Server.state server in
  let store = state.store in
  match notification with
  | TextDocumentDidOpen params ->
    Log.log ~section:"debug" (fun () -> Log.msg "doc opened" []);
    let open Fiber.O in
    let* doc =
      let delay = Configuration.diagnostics_delay state.configuration in
      let* timer = Scheduler.create_timer ~delay in
      Document.make timer state.merlin params
    in
    Document_store.put store doc;
    let+ () = set_diagnostics server doc in
    state
  | TextDocumentDidClose { textDocument = { uri } } ->
    Log.log ~section:"debug" (fun () -> Log.msg "doc closed" []);
    let open Fiber.O in
    let+ () =
      Diagnostics.remove state.diagnostics (`Merlin uri);
      let* () = Document_store.remove_document store uri in
      task_if_running state ~f:(fun () -> Diagnostics.send state.diagnostics)
    in
    state
  | TextDocumentDidChange { textDocument = { uri; version }; contentChanges } ->
    Log.log ~section:"debug" (fun () -> Log.msg "doc changed" []);
    let prev_doc = Document_store.get store uri in
    let open Fiber.O in
    let* doc = Document.update_text ~version prev_doc contentChanges in
    Document_store.put store doc;
    let+ () = set_diagnostics server doc in
    state
  | CancelRequest _ ->
    Log.log ~section:"debug" (fun () -> Log.msg "ignoring cancellation" []);
    Fiber.return state
  | ChangeConfiguration req ->
    (* TODO this is wrong and we should just fetch the config from the client
       after receiving this notification *)
    let configuration = Configuration.update state.configuration req in
    Fiber.return { state with configuration }
  | DidSaveTextDocument { textDocument = { uri }; _ } -> (
    let open Fiber.O in
    let state = Server.state server in
    match Document_store.get_opt state.store uri with
    | None ->
      ( Log.log ~section:"on receive DidSaveTextDocument" @@ fun () ->
        Log.msg "saved document is not in the store" [] );
      Fiber.return state
    | Some doc ->
      (* we need [update_text] with no changes to get a new merlin pipeline;
         otherwise the diagnostics don't get updated *)
      let* doc = Document.update_text doc [] in
      Document_store.put store doc;
      let+ () = set_diagnostics server doc in
      state)
  | WillSaveTextDocument _
  | ChangeWorkspaceFolders _
  | Initialized
  | WorkDoneProgressCancel _
  | Exit ->
    Fiber.return state
  | SetTrace { value } -> Fiber.return { state with trace = value }
  | Unknown_notification req ->
    let open Fiber.O in
    let+ () =
      task_if_running state ~f:(fun () ->
          let log =
            LogMessageParams.create ~type_:Error
              ~message:("Unknown notication " ^ req.method_)
          in
          Server.notification server (Server_notification.LogMessage log))
    in
    state

let start () =
  let store = Document_store.make () in
  let handler =
    let on_request = { Server.Handler.on_request } in
    Server.Handler.make ~on_request ~on_notification ()
  in
  let open Fiber.O in
  let* stream =
    let io = Lsp.Io.make stdin stdout in
    Lsp_fiber.Fiber_io.make io
  in
  let configuration = Configuration.default in
  let detached = Fiber.Pool.create () in
  let server = Fdecl.create Dyn.Encoder.opaque in
  let diagnostics =
    let workspace_root =
      lazy
        (let server = Fdecl.get server in
         let state = Server.state server in
         State.workspace_root state)
    in
    Diagnostics.create ~workspace_root (function
      | [] -> Fiber.return ()
      | diagnostics ->
        let server = Fdecl.get server in
        let state = Server.state server in
        task_if_running state ~f:(fun () ->
            let batch = Server.Batch.create server in
            List.iter diagnostics ~f:(fun d ->
                Server.Batch.notification batch (PublishDiagnostics d));
            Server.Batch.submit batch))
  in
  let* server =
    let+ merlin = Scheduler.create_thread () in
    let ocamlformat = Fmt.create () in
    let symbols_thread = Lazy_fiber.create Scheduler.create_thread in
    Fdecl.set server
      (Server.make handler stream
         { store
         ; init = Uninitialized
         ; merlin
         ; ocamlformat
         ; configuration
         ; detached
         ; trace = `Off
         ; diagnostics
         ; symbols_thread
         });
    Fdecl.get server
  in
  Fiber.parallel_iter
    ~f:(fun f -> f ())
    [ (fun () -> Fiber.Pool.run detached)
    ; (fun () ->
        let* () = Server.start server in
        Fiber.parallel_iter
          ~f:(fun f -> f ())
          [ (fun () -> Fiber.Pool.stop detached) ])
    ]

let run () = Scheduler.run (start ())
