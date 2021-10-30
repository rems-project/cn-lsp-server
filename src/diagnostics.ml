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

module Uri = struct
  include Uri

  let compare x y = Ordering.of_int (Uri.compare x y)
end

module Uri_c = Comparable.Make (Uri)
module Uri_set = Uri_c.Set

type dune_status =
  | Inactive
  | Connected
  | Disconnected

type t =
  { mutable dune_status : dune_status
  ; workspace_root : Uri.t Lazy.t
  ; merlin : (Uri.t, Diagnostic.t list) Table.t
  ; send : PublishDiagnosticsParams.t list -> unit Fiber.t
  ; mutable dirty_uris : Uri_set.t
  }

let workspace_root t = Lazy.force t.workspace_root

let create send ~workspace_root =
  { merlin = Table.create (module Uri) 32
  ; dirty_uris = Uri_set.empty
  ; dune_status = Inactive
  ; send
  ; workspace_root
  }

let update_dune_status _t _status =
  failwith "TODO: Diagnostics.update_dune_status"

let dune_status_diagnostic t =
  match t.dune_status with
  | Disconnected ->
    Some
      (Diagnostic.create ~severity:Information ~source:"dune"
         ~range:Range.first_line
         ~message:
           "Dune diagnostic status may be stale. Please run dune in watch mode\n\
            to see up to date diagnostics"
         ())
  | _ -> None

let send t =
  let pending = Table.create (module Uri) 32 in
  Uri_set.iter t.dirty_uris ~f:(fun uri ->
      let diagnostics = Table.Multi.find t.merlin uri in
      Table.set pending uri diagnostics);
  dune_status_diagnostic t
  |> Option.iter ~f:(fun d ->
         Table.Multi.cons pending (Lazy.force t.workspace_root) d);
  t.dirty_uris <- Uri_set.empty;
  Table.foldi pending ~init:[] ~f:(fun uri diagnostics acc ->
      PublishDiagnosticsParams.create ~uri ~diagnostics () :: acc)
  |> t.send

let set t what =
  let uri =
    match what with
    | `Merlin (uri, _) -> uri
  in
  t.dirty_uris <- Uri_set.add t.dirty_uris uri;
  match what with
  | `Merlin (uri, diagnostics) -> Table.set t.merlin uri diagnostics

let remove t = function
  | `Merlin uri ->
    t.dirty_uris <- Uri_set.add t.dirty_uris uri;
    Table.remove t.merlin uri
