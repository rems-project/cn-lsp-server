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

let capability = ("handleInferIntf", `Bool true)

let meth = "ocamllsp/inferIntf"

let on_request ~(params : Jsonrpc.Message.Structured.t option) (state : State.t)
    =
  match params with
  | Some (`List [ json_uri ]) -> (
    let json_uri = DocumentUri.t_of_yojson json_uri in
    let open Fiber.O in
    match Document_store.get_opt state.store json_uri with
    | None ->
      Jsonrpc.Response.Error.raise
        (Jsonrpc.Response.Error.make ~code:InvalidParams
           ~message:
             "ocamllsp/inferIntf received a URI for an unloaded file. Load the \
              file first."
           ())
    | Some impl ->
      let+ intf = Inference.infer_intf_for_impl impl in
      Json.t_of_yojson (`String intf))
  | Some json ->
    Jsonrpc.Response.Error.raise
      (Jsonrpc.Response.Error.make ~code:InvalidRequest
         ~message:"The input parameter for ocamllsp/inferIntf is invalid"
         ~data:(`Assoc [ ("param", (json :> Json.t)) ])
         ())
  | None ->
    Jsonrpc.Response.Error.raise
      (Jsonrpc.Response.Error.make ~code:InvalidRequest
         ~message:"ocamllsp/inferIntf must receive param: DocumentUri.t" ())
