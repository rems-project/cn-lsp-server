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
(*  All other parts involve adapted code, with the new code subject to the    *)
(*  above BSD 2-Clause licence and the original code subject to its ISC       *)
(*  licence.                                                                  *)
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

open Import

let outline_kind kind : SymbolKind.t =
  match kind with
  | `Value -> Function
  | `Constructor -> Constructor
  | `Label -> Property
  | `Module -> Module
  | `Modtype -> Module
  | `Type -> String
  | `Exn -> Constructor
  | `Class -> Class
  | `Method -> Method

let range item = Range.of_loc item.Query_protocol.location

let rec symbol item =
  let children = List.map item.Query_protocol.children ~f:symbol in
  let range : Range.t = range item in
  let kind = outline_kind item.outline_kind in
  DocumentSymbol.create ~name:item.Query_protocol.outline_name ~kind
    ?detail:item.Query_protocol.outline_type ~deprecated:item.deprecated ~range
    ~selectionRange:range ~children ()

let rec symbol_info ?containerName uri item =
  let location = { Location.uri; range = range item } in
  let info =
    let kind = outline_kind item.outline_kind in
    SymbolInformation.create ~name:item.Query_protocol.outline_name ~kind
      ~deprecated:false ~location ?containerName ()
  in
  let children =
    List.concat_map item.children ~f:(symbol_info uri ~containerName:info.name)
  in
  info :: children

let symbols_of_outline uri outline =
  List.concat_map ~f:(symbol_info uri) outline

let run (client_capabilities : ClientCapabilities.t) doc uri =
  let command = Query_protocol.Outline in
  let open Fiber.O in
  let+ outline = Document.dispatch_exn doc command in
  let symbols =
    let hierarchicalDocumentSymbolSupport =
      let open Option.O in
      Option.value
        (let* textDocument = client_capabilities.textDocument in
         let* ds = textDocument.documentSymbol in
         ds.hierarchicalDocumentSymbolSupport)
        ~default:false
    in
    match hierarchicalDocumentSymbolSupport with
    | true ->
      let symbols = List.map outline ~f:symbol in
      `DocumentSymbol symbols
    | false ->
      let symbols = symbols_of_outline uri outline in
      `SymbolInformation symbols
  in
  symbols
