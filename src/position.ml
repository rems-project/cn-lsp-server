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
