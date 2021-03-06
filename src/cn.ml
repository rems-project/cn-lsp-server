(*=========================================================================*)
(*  Copyright (c) 2021 Dhruv Makwana                                       *)
(*  All rights reserved.                                                   *)
(*                                                                         *)
(*  This software was developed by the University of Cambridge Computer    *)
(*  Laboratory as part of the Rigorous Engineering of Mainstream Systems   *)
(*  (REMS) project. This project has been partly funded by an EPSRC        *)
(*  Doctoral Training studentship. This project has been partly funded by  *)
(*  Google. This project has received funding from the European Research   *)
(*  Council (ERC) under the European Union's Horizon 2020 research and     *)
(*  innovation programme (grant agreement No 789108, Advanced Grant        *)
(*  ELVER).                                                                *)
(*                                                                         *)
(*  BSD 2-Clause License                                                   *)
(*                                                                         *)
(*  Redistribution and use in source and binary forms, with or without     *)
(*  modification, are permitted provided that the following conditions     *)
(*  are met:                                                               *)
(*  1. Redistributions of source code must retain the above copyright      *)
(*     notice, this list of conditions and the following disclaimer.       *)
(*  2. Redistributions in binary form must reproduce the above copyright   *)
(*     notice, this list of conditions and the following disclaimer in     *)
(*     the documentation and/or other materials provided with the          *)
(*     distribution.                                                       *)
(*                                                                         *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''     *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED      *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A        *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR    *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,           *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF       *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND    *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,     *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT     *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF     *)
(*  SUCH DAMAGE.                                                           *)
(*                                                                         *)
(*=========================================================================*)

open Import

let env =
  lazy
    (let f s = s ^ "=" ^ Unix.getenv s in
     (* need path for CC for preprocessor *)
     [| f "OPAM_SWITCH_PREFIX"; "PATH=/usr/bin" |])

module Util = Yojson.Safe.Util

let ( .%{} ) json str = Util.member str json

let get_range_exn json =
  (* [ "Region", { "region_start": { "file": "structs9.c", "line": 8, "char": 13
     }, "region_end": { "file": "structs9.c", "line": 8, "char": 25 },
     "region_cursor": { "file": "structs9.c", "line": 8, "char": 22 } } ] *)
  let region =
    match Util.to_list json.%{"loc"} with
    | []
    | [ _ ]
    | _ :: _ :: _ :: _ ->
      assert false
    | [ tag; result ] ->
      assert (String.equal (Util.to_string tag) "Region");
      result
  in
  let pos x =
    Position.create
      ~line:(Util.to_int x.%{"line"} - 1 (* LSP starts at line 0 *))
      ~character:(Util.to_int @@ x.%{"char"})
  in
  Range.create
    ~start:(pos region.%{"region_start"})
    ~end_:(pos region.%{"region_end"})

let get_message_exn json =
  let short = Util.to_string json.%{"short"} in
  match Util.to_string_option json.%{"descr"} with
  | Some descr -> short ^ " " ^ descr
  | None -> short

let get_code_and_descr_exn json =
  match Util.(to_string_option json.%{"state"}) with
  | None -> (None, None)
  | Some state_file ->
    let href = "file://" ^ state_file in
    ( Some (`String "View Program State")
    , Some (Lsp.Types.CodeDescription.create ~href) )

let json_to_diagnostic json =
  try
    (* { "loc": [ "Region", { .. } ] , "short": "Undefined behaviour" , "descr":
       "<long description>" , "state":"/tmp/944928.cn-state" } *)
    let range = get_range_exn json
    and message = get_message_exn json
    (* [code] must be present for [codeDescription] to work *)
    and code, codeDescription = get_code_and_descr_exn json in
    [ Diagnostic.create ?code ?codeDescription ~message ~range () ]
  with
  | Util.Type_error (_str, _)
  | Util.Undefined (_str, _) ->
    (* FIXME Log.debug str *)
    []

let get_errs (doc : Document.t) : Diagnostic.t list =
  let doc_path = Uri.to_path @@ Document.uri doc in
  let state_file =
    Filename.(concat (get_temp_dir_name ()) (basename doc_path ^ ".cn-state"))
  in
  let cn = Fpath.to_string @@ Option.value_exn @@ Bin.which "cn" in
  let ((_stdin, _stdout, stderr) as pipes) =
    Unix.open_process_args_full cn
      [| cn; "--json"; "--state-file=" ^ state_file; doc_path |]
      (Lazy.force env)
  in
  (* FIXME handle errors from this? *)
  let stream = Yojson.Safe.stream_from_channel ~fname:doc_path stderr in
  match Stream.peek stream with
  (* FIXME add tests for no error *)
  | None -> [ (* no errors *) ]
  (* currently CN only supports one error *)
  | Some json ->
    ignore (Unix.close_process_full pipes);
    json_to_diagnostic json
