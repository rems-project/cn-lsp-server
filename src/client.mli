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

(** This module is a collection of client-specific functionality (client =
    editor) *)

module Vscode : sig
  (** A collection of VS Code editor commands.

      Reference for VS Code built-in commands:
      https://code.visualstudio.com/api/references/commands *)
  module Commands : sig
    (** [editor.action.triggerSuggest] is a vscode-specific command, which
        triggers the completion request on all completion providers *)
    val triggerSuggest : Command.t

    (** Represents custom commands, i.e., commands added by a certain extension.

        Currently, the module includes custom commands introduced by "OCaml
        Platform" extension *)
    module Custom : sig
      (** Request client cursor to jump to the next hole.

          Looks for a hole starting at position [start_position], if provided;
          otherwise, uses the cursor position.

          Will not show a pop-up notification if [notify-if-no-hole] is set to
          [false] (the default value is [true]) *)
      val next_hole :
           ?start_position:Position.t
        -> notify_if_no_hole:bool
        -> unit
        -> Command.t
    end
  end
end
