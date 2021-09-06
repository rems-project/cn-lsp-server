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

module Resolve : sig
  type t

  val uri : t -> Uri.t

  (** if the completion item doesn't have [data] field, then we don't resolve
      but return it *)
  val of_completion_item : CompletionItem.t -> t option

  include Json.Jsonable.S with type t := t
end

val complete :
  Document.t -> Position.t -> [> `CompletionList of CompletionList.t ] Fiber.t

(** creates a server response for ["completionItem/resolve"] *)
val resolve :
     Document.t
  -> CompletionItem.t
  -> Resolve.t
  -> (Document.t -> [> `Logical of int * int ] -> string option Fiber.t)
  -> markdown:bool
  -> CompletionItem.t Fiber.t

(** [prefix_of_position ~short_path source position] computes prefix before
    given [position].

    @param short_path
      determines whether we want full prefix or cut at ["."], e.g.
      [List.m<cursor>] returns ["m"] when [short_path] is set vs ["List.m"] when
      not.
    @return prefix of [position] in [source] and its length *)
val prefix_of_position :
  short_path:bool -> Msource.t -> [< Msource.position ] -> string

(** [suffix_of_position source position] computes the suffix of the identifier
    after [position]. *)
val suffix_of_position : Msource.t -> [< Msource.position ] -> string

(** [reconstruct_ident source position] returns the identifier at [position].
    Note: [position] can be in the middle of the identifier.

    @return identifier unless none is found *)
val reconstruct_ident : Msource.t -> [< Msource.position ] -> string option
