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

(* {{{ COPYING *(

   This file is part of Merlin, an helper for ocaml editors

   Copyright (C) 2013 - 2015 Frédéric Bour <frederic.bour(_)lakaban.net> Thomas
   Refis <refis.thomas(_)gmail.com> Simon Castellan <simon.castellan(_)iuwt.fr>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   The Software is provided "as is", without warranty of any kind, express or
   implied, including but not limited to the warranties of merchantability,
   fitness for a particular purpose and noninfringement. In no event shall the
   authors or copyright holders be liable for any claim, damages or other
   liability, whether in an action of contract, tort or otherwise, arising from,
   out of or in connection with the software or the use or other dealings in the
   Software.

   )* }}} *)
open Import

let is_directory dir =
  try Sys.is_directory dir with
  | Sys_error _ -> false

type error = Build_dir_not_found of string

let find_build_dir ({ name; uri } : WorkspaceFolder.t) =
  let build_dir = Filename.concat (Uri.to_path uri) "_build/default" in
  if is_directory build_dir then
    Ok build_dir
  else
    Error (Build_dir_not_found name)

type cm_file =
  | Cmt of string
  | Cmti of string

let symbols_from_cm_file ~filter:_ _root_uri _cm_file =
  failwith "Workspace_symbol.symbols_from_cm_file"

let find_cm_files dir =
  let choose_file f1 f2 =
    match (f1, f2) with
    | (Cmt _ as f), _
    | _, (Cmt _ as f) ->
      f
    | (Cmti _ as f), Cmti _ -> f
  in
  (* TODO we could get into a symlink loop here so we should we be careful *)
  let rec loop acc dir =
    let contents = Sys.readdir dir in
    Array.fold_left contents ~init:acc ~f:(fun acc fname ->
        let path = Filename.concat dir fname in
        if is_directory path then
          loop acc path
        else
          match String.rsplit2 ~on:'.' path with
          | Some (path_without_ext, "cmt") ->
            String.Map.set acc path_without_ext (Cmt path)
          | Some (path_without_ext, "cmti") -> (
            let current_file = String.Map.find acc path_without_ext in
            let cmi_file = Cmti path in
            match current_file with
            | None -> String.Map.set acc path_without_ext cmi_file
            | Some current_file ->
              String.Map.set acc path_without_ext
                (choose_file current_file cmi_file))
          | _ -> acc)
  in
  loop String.Map.empty dir |> String.Map.values

let run ({ query; _ } : WorkspaceSymbolParams.t)
    (workspace_folders : WorkspaceFolder.t list) =
  let filter =
    match query with
    | "" -> fun x -> x
    | query ->
      let re = Re.str query |> Re.compile in
      List.filter ~f:(fun (symbol : SymbolInformation.t) ->
          Re.execp re symbol.name)
  in
  List.map workspace_folders ~f:(fun (workspace_folder : WorkspaceFolder.t) ->
      let open Result.O in
      let* build_dir = find_build_dir workspace_folder in
      Ok
        (let cm_files = find_cm_files build_dir in
         let path =
           let uri = workspace_folder.uri in
           Uri.to_path uri
         in
         List.concat_map ~f:(symbols_from_cm_file ~filter path) cm_files))
