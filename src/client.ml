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

module Vscode = struct
  module Commands = struct
    let triggerSuggest =
      Command.create ~title:"Trigger Suggest"
        ~command:"editor.action.triggerSuggest" ()

    module Custom = struct
      let next_hole ?start_position ~notify_if_no_hole () =
        let arguments =
          let arg_obj_fields =
            let notif_json =
              Some ("notify-if-no-hole", Json.bool notify_if_no_hole)
            in
            let pos_json =
              Option.map start_position ~f:(fun p ->
                  ("position", Position.yojson_of_t p))
            in
            List.filter_opt [ pos_json; notif_json ]
          in
          match arg_obj_fields with
          | [] -> [] (* no arguments -- the extension uses defaults *)
          | fields ->
            (* the use of a (json) object as the first and single argument to
               the command is intended *)
            [ `Assoc fields ]
        in
        Command.create ~title:"Jump to Next Hole" ~command:"ocaml.next-hole"
          ~arguments ()
    end
  end
end
