open Import

let input_all t =
  (* We use 65536 because that is the size of OCaml's IO buffers. *)
  let chunk_size = 65536 in
  let buffer = Buffer.create chunk_size in
  let rec loop () =
    Buffer.add_channel buffer t chunk_size;
    loop ()
  in
  try loop () with
  | End_of_file -> Buffer.contents buffer

let env =
  lazy (
    (* let f s = s ^ "=" ^ Unix.getenv s in *)
    (* FIXME don't hard code *)
    (* need path for CC for preprocessor *)
    [| "OPAM_SWITCH_PREFIX=/auto/homes/dcm41/.opam/4.09.1" ; "PATH=/usr/bin" |] )

let json_to_diagnostic json = 
  let module Util = Yojson.Safe.Util in
  try
    (* { "loc":
         [ "Region", {
           "region_start": { "file": "structs9.c", "line": 8, "char": 13 },
           "region_end": { "file": "structs9.c", "line": 8, "char": 25 },
           "region_cursor": { "file": "structs9.c", "line": 8, "char": 22 } } ],
       "short": "Undefined behaviour",
       "descr": "(§6.5#2) an exceptional condition occurred during the evaluation of an expression." } *)
    let region = json
                 |> Util.member "loc"
                 |> Util.to_list
                 |> (fun x ->
                     assert (List.length x = 2);
                     assert (String.equal (Util.to_string @@ List.hd x)  "Region");
                     List.tl x)
                 |> List.hd in
    let start , end_ = Util.member "region_start" region , Util.member "region_end" region in
    let pos x = Position.create
        ~line:(Util.to_int (Util.member "line" x) - 1 (* LSP starts at line 0 *))
        ~character:(Util.to_int @@ Util.member "char" x) in
    let start , end_ = pos start , pos end_ in
    let range = Range.create ~start ~end_ in
    let href = "file:///auto/homes/dcm41/c-tests/annotated/state.html" in
    let message = Util.((to_string (member "short" json) 
                         ^ " " ^ to_string (member "descr" json))) in
    (* [code] must be present for [codeDescription] to work *)
    let code = `String "View Program State" in
    let codeDescription = Lsp.Types.CodeDescription.create ~href in
    [ Diagnostic.create ~code ~codeDescription ~message ~range () ]
  with
  | Util.Type_error (_str , _)
  | Util.Undefined (_str , _) ->
    (* FIXME Log.debug str *)
    []

let get_errs (doc : Document.t) : Diagnostic.t list =
  let doc_path = Uri.to_path @@ Document.uri doc in
  (* let cn = Fpath.to_string @@ Option.value_exn @@ Bin.which "cn" in *)
  let cn = "/auto/homes/dcm41/.opam/4.09.1/bin/cn" in
  let (_stdin, _stdout, stderr) as pipes =
    Unix.open_process_args_full cn [| cn ; "--json" ; doc_path |] (Lazy.force env) in
    (* FIXME handle errors from this? *)
    let stream = Yojson.Safe.stream_from_channel ~fname:doc_path stderr in
    match Stream.peek stream with
    (* FIXME add tests for no error *)
    | None -> [ (* no errors *) ]
    (* currently CN only supports one error *) 
    | Some json -> 
      ignore (Unix.close_process_full pipes);
      json_to_diagnostic json

