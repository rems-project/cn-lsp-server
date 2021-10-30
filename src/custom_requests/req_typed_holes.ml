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
(*  All other parts involve adapted code, with the new code subject to the    *)
(*  above BSD 2-Clause licence and the original code subject to its ISC       *)
(*  licence.                                                                  *)
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

let capability = ("handleTypedHoles", `Bool true)

let meth = "ocamllsp/typedHoles"

module Request_params = struct
  type t = Uri.t

  (* Request params must have the form as in the given string. *)
  let expected_params = `Assoc [ ("uri", `String "<DocumentUri>") ]

  let t_of_structured_json params : t option =
    match params with
    | `Assoc [ ("uri", uri) ] ->
      let uri = Uri.t_of_yojson uri in
      Some uri
    | _ -> None

  let parse_exn (params : Jsonrpc.Message.Structured.t option) : t =
    let raise_invalid_params ?data ~message () =
      Jsonrpc.Response.Error.raise
      @@ Jsonrpc.Response.Error.make ?data
           ~code:Jsonrpc.Response.Error.Code.InvalidParams ~message ()
    in
    match params with
    | None ->
      raise_invalid_params ~message:"Expected params but received none" ()
    | Some params -> (
      match t_of_structured_json params with
      | Some uri -> uri
      | None ->
        let error_json =
          `Assoc
            [ ("params_expected", expected_params)
            ; ("params_received", (params :> Json.t))
            ]
        in
        raise_invalid_params ~message:"Unxpected parameter format"
          ~data:error_json ())
end

let on_request ~(params : Jsonrpc.Message.Structured.t option) (state : State.t)
    =
  let uri = Request_params.parse_exn params in
  let store = state.store in
  let doc = Document_store.get_opt store uri in
  match doc with
  | None ->
    Jsonrpc.Response.Error.raise
    @@ Jsonrpc.Response.Error.make
         ~code:Jsonrpc.Response.Error.Code.InvalidParams
         ~message:
           (Printf.sprintf "Document %s wasn't found in the document store"
              (Uri.to_string uri))
         ()
  | Some _doc -> failwith "Req_typed_holes.on_request"
