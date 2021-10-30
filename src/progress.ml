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

open Import

type enabled =
  { (* TODO this needs to be mutexed *)
    mutable token : ProgressToken.t option
  ; mutable build_counter : int
  ; report_progress :
      Server_notification.Progress.t ProgressParams.t -> unit Fiber.t
  ; create_task : WorkDoneProgressCreateParams.t -> unit Fiber.t
  }

type t =
  | Disabled
  | Enabled of enabled

let create (client_capabilities : ClientCapabilities.t) ~report_progress
    ~create_task =
  match client_capabilities.window with
  | Some { workDoneProgress = Some true; _ } ->
    Enabled { token = None; build_counter = 0; create_task; report_progress }
  | _ -> Disabled

let end_build (t : enabled) ~message =
  match t.token with
  | None -> Fiber.return ()
  | Some token ->
    t.token <- None;
    t.report_progress
      (ProgressParams.create ~token
         ~value:
           (Server_notification.Progress.End
              (WorkDoneProgressEnd.create ~message ())))

let end_build_if_running = function
  | Disabled -> Fiber.return ()
  | Enabled e -> end_build e ~message:"Build interrupted"

let start_build (t : enabled) =
  let open Fiber.O in
  let* () = end_build t ~message:"Starting new build" in
  let token = `String ("dune-build-" ^ Int.to_string t.build_counter) in
  t.token <- Some token;
  t.build_counter <- t.build_counter + 1;
  let* () = t.create_task (WorkDoneProgressCreateParams.create ~token) in
  t.token <- Some token;
  let+ () =
    t.report_progress
      (ProgressParams.create ~token
         ~value:
           (Server_notification.Progress.Begin
              (WorkDoneProgressBegin.create ~title:"Build" ~message:"started" ())))
  in
  token

let build_event t (event : Drpc.Build.Event.t) =
  match t with
  | Disabled -> Code_error.raise "progress reporting is not supported" []
  | Enabled t -> (
    match event with
    | Finish -> end_build t ~message:"Build finished"
    | Fail -> end_build t ~message:"Build failed"
    | Interrupt -> end_build t ~message:"Build interrupted"
    | Start ->
      let open Fiber.O in
      let+ (_ : ProgressToken.t) = start_build t in
      ())

let build_progress t (progress : Drpc.Progress.t) =
  match t with
  | Disabled -> Code_error.raise "progress reporting is not supported" []
  | Enabled ({ token; report_progress; _ } as t) ->
    let open Fiber.O in
    let* token =
      match token with
      | Some token -> Fiber.return token
      | None ->
        (* This can happen when we connect to dune in the middle of a build. *)
        start_build t
    in
    let percentage =
      let fraction =
        float_of_int progress.complete
        /. float_of_int (progress.complete + progress.remaining)
      in
      int_of_float (fraction *. 100.)
    in
    report_progress
      (ProgressParams.create ~token
         ~value:
           (Server_notification.Progress.Report
              (WorkDoneProgressReport.create ~percentage ~message:"Building" ())))

let should_report_build_progress = function
  | Disabled -> false
  | Enabled _ -> true
