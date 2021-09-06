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
