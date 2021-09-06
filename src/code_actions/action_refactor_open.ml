(*============================================================================*)
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

let code_action (_mode : [ `Qualify | `Unqualify ]) (_action_kind : string) _doc
    (_params : CodeActionParams.t) =
  failwith "Action_refactor_open.code_action"

let unqualify =
  let action_kind = "remove module name from identifiers" in
  { Code_action.action_kind; run = code_action `Unqualify action_kind }

let qualify =
  let action_kind = "put module name in identifiers" in
  { Code_action.action_kind; run = code_action `Qualify action_kind }
