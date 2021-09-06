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
include Lsp.Types.Range

let compare (x : t) (y : t) =
  match Position.compare x.start y.start with
  | (Lt | Gt) as r -> r
  | Ordering.Eq -> Position.compare x.end_ y.end_

(* Compares ranges by their lengths*)
let compare_size (x : t) (y : t) =
  let dx = Position.(x.end_ - x.start) in
  let dy = Position.(y.end_ - y.start) in
  Stdune.Tuple.T2.compare Int.compare Int.compare (dx.line, dy.line)
    (dx.character, dy.character)

let first_line =
  let start = { Position.line = 0; character = 0 } in
  let end_ = { Position.line = 1; character = 0 } in
  { start; end_ }

let of_loc (loc : Loc.t) : t =
  (let open Option.O in
  let* start = Position.of_lexical_position loc.loc_start in
  let+ end_ = Position.of_lexical_position loc.loc_end in
  { start; end_ })
  |> Option.value ~default:first_line
