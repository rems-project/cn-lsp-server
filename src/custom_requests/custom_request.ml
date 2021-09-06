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

type 't req_params_spec =
  { params_schema : Jsonrpc.Message.Structured.t
  ; of_jsonrpc_params : Jsonrpc.Message.Structured.t -> 't option
  }

let of_jsonrpc_params_exn spec params =
  let raise_invalid_params ?data ~message () =
    Jsonrpc.Response.Error.raise
    @@ Jsonrpc.Response.Error.make ?data
         ~code:Jsonrpc.Response.Error.Code.InvalidParams ~message ()
  in
  match params with
  | None -> raise_invalid_params ~message:"Expected params but received none" ()
  | Some params -> (
    match spec.of_jsonrpc_params params with
    | Some t -> t
    | None ->
      let error_json =
        `Assoc
          [ ("params_expected", (spec.params_schema :> Json.t))
          ; ("params_received", (params :> Json.t))
          ]
      in
      raise_invalid_params ~message:"Unexpected parameter format"
        ~data:error_json ())
