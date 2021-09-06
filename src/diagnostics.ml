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
