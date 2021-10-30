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

open Import
include Lsp.Types.Position

let start = { line = 0; character = 0 }

let is_dummy (lp : Lexing.position) =
  lp.pos_lnum = Lexing.dummy_pos.pos_lnum
  && lp.pos_cnum = Lexing.dummy_pos.pos_cnum

let of_lexical_position (lex_position : Lexing.position) : t option =
  if is_dummy lex_position then
    None
  else
    let line = lex_position.pos_lnum - 1 in
    let character = lex_position.pos_cnum - lex_position.pos_bol in
    if not (line >= 0 && character >= 0) then
      Log.log ~section:"debug" (fun () ->
          Log.msg "merlin returned dummy position %a"
            [ ("pos_fname", `String lex_position.pos_fname)
            ; ("pos_lnum", `Int lex_position.pos_lnum)
            ; ("pos_bol", `Int lex_position.pos_bol)
            ; ("pos_cnum", `Int lex_position.pos_cnum)
            ]);
    let line = max line 0 in
    let character = max character 0 in
    Some { line; character }

let ( - ) ({ line; character } : t) (t : t) : t =
  { line = line - t.line; character = character - t.character }

let abs ({ line; character } : t) : t =
  { line = abs line; character = abs character }

let compare ({ line; character } : t) (t : t) : Ordering.t =
  Stdune.Tuple.T2.compare Int.compare Int.compare (line, character)
    (t.line, t.character)

let compare_inclusion (t : t) (r : Lsp.Types.Range.t) =
  match (compare t r.start, compare t r.end_) with
  | Lt, Lt -> `Outside (abs (r.start - t))
  | Gt, Gt -> `Outside (abs (r.end_ - t))
  | Eq, Lt
  | Gt, Eq
  | Eq, Eq
  | Gt, Lt ->
    `Inside
  | Eq, Gt
  | Lt, Eq
  | Lt, Gt ->
    assert false

let logical position =
  let line = position.line + 1 in
  let col = position.character in
  `Logical (line, col)
