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

(* All modules from [Stdune] should be in the struct below. The modules are
   listed alphabetically. Try to keep the order. *)
include struct
  open Stdune
  module Array = Array
  module Code_error = Code_error
  module Comparable = Comparable
  module Dyn = Dyn
  module Exn_with_backtrace = Exn_with_backtrace
  module Fdecl = Fdecl
  module Fpath = Path
  module Int = Int
  module List = List
  module Option = Option
  module Ordering = Ordering
  module Pid = Pid
  module Poly = Poly
  module Result = Result
  module String = String
  module Table = Table
  module Unix_env = Env
  module Io = Io

  let sprintf = sprintf
end

(* All modules from [Lsp] should be in the struct below. The modules are listed
   alphabetically. Try to keep the order. *)
include struct
  open Lsp
  module Client_notification = Client_notification
  module Client_request = Client_request
  module Json = Import.Json
  module Server_request = Server_request
  module Text_document = Text_document
  module Uri = Uri
end

(* Misc modules *)
module Scheduler = Fiber_unix.Scheduler

(* All modules from [Lsp_fiber] should be in the struct below. The modules are
   listed alphabetically. Try to keep the order. *)
include struct
  open Lsp_fiber
  module Log = Import.Log
  module Reply = Rpc.Reply
  module Server = Server
end

(* All modules from [Lsp.Types] should be in the struct below. The modules are
   listed alphabetically. Try to keep the order. *)
include struct
  open Lsp.Types
  module ClientCapabilities = ClientCapabilities
  module CodeAction = CodeAction
  module CodeActionKind = CodeActionKind
  module CodeActionOptions = CodeActionOptions
  module CodeActionParams = CodeActionParams
  module CodeActionResult = CodeActionResult
  module CodeLens = CodeLens
  module CodeLensOptions = CodeLensOptions
  module CodeLensParams = CodeLensParams
  module Command = Command
  module CompletionItem = CompletionItem
  module CompletionItemKind = CompletionItemKind
  module CompletionList = CompletionList
  module CompletionOptions = CompletionOptions
  module CompletionParams = CompletionParams
  module ConfigurationParams = ConfigurationParams
  module Diagnostic = Diagnostic
  module DiagnosticRelatedInformation = DiagnosticRelatedInformation
  module DiagnosticSeverity = DiagnosticSeverity
  module DidChangeConfigurationParams = DidChangeConfigurationParams
  module DidOpenTextDocumentParams = DidOpenTextDocumentParams
  module DocumentHighlight = DocumentHighlight
  module DocumentHighlightKind = DocumentHighlightKind
  module DocumentHighlightParams = DocumentHighlightParams
  module DocumentSymbol = DocumentSymbol
  module DocumentUri = DocumentUri
  module ExecuteCommandOptions = ExecuteCommandOptions
  module FoldingRange = FoldingRange
  module FoldingRangeParams = FoldingRangeParams
  module Hover = Hover
  module HoverParams = HoverParams
  module InitializeParams = InitializeParams
  module InitializeResult = InitializeResult
  module Location = Location
  module LogMessageParams = LogMessageParams
  module MarkupContent = MarkupContent
  module MarkupKind = MarkupKind
  module MessageType = MessageType
  module OptionalVersionedTextDocumentIdentifier =
    OptionalVersionedTextDocumentIdentifier
  module ParameterInformation = ParameterInformation
  module ProgressParams = ProgressParams
  module ProgressToken = ProgressToken
  module PublishDiagnosticsParams = PublishDiagnosticsParams
  module ReferenceParams = ReferenceParams
  module RenameOptions = RenameOptions
  module RenameParams = RenameParams
  module SelectionRange = SelectionRange
  module SelectionRangeParams = SelectionRangeParams
  module ServerCapabilities = ServerCapabilities
  module Server_notification = Lsp.Server_notification
  module SetTraceParams = SetTraceParams
  module ShowMessageParams = ShowMessageParams
  module SignatureHelp = SignatureHelp
  module SignatureHelpOptions = SignatureHelpOptions
  module SignatureHelpParams = SignatureHelpParams
  module SignatureInformation = SignatureInformation
  module SymbolInformation = SymbolInformation
  module SymbolKind = SymbolKind
  module TextDocumentContentChangeEvent = TextDocumentContentChangeEvent
  module TextDocumentEdit = TextDocumentEdit
  module TextDocumentIdentifier = TextDocumentIdentifier
  module TextDocumentSyncKind = TextDocumentSyncKind
  module TextDocumentSyncOptions = TextDocumentSyncOptions
  module TextEdit = TextEdit
  module TraceValue = TraceValue
  module VersionedTextDocumentIdentifier = VersionedTextDocumentIdentifier
  module WorkDoneProgressBegin = WorkDoneProgressBegin
  module WorkDoneProgressCreateParams = WorkDoneProgressCreateParams
  module WorkDoneProgressEnd = WorkDoneProgressEnd
  module WorkDoneProgressReport = WorkDoneProgressReport
  module WorkspaceEdit = WorkspaceEdit
  module WorkspaceFolder = WorkspaceFolder
  module WorkspaceSymbolParams = WorkspaceSymbolParams
end
