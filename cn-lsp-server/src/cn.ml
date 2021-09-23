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
  let f s = s ^ "=" ^ Unix.getenv s in
  [| f "OPAM_SWITCH_PREFIX" ; "PATH=/usr/bin" |] )

(* Can use Yojson to get Json from in_channel *)
let get_errs (doc : Document.t) : Diagnostic.t list =
  let doc_path = Uri.to_path @@ Document.uri doc in
  let cn = Fpath.to_string @@ Option.value_exn @@ Bin.which "cn" in
  let (_stdin, _stdout, stderr) as pipes =
    Unix.open_process_args_full cn [| cn ; doc_path |] (Lazy.force env) in
  let message = input_all stderr in
  ignore (Unix.close_process_full pipes);
  let pos = Position.create ~line:0 ~character:0 in
  let range = Range.create ~start:pos ~end_:pos in
  [ Diagnostic.create ~message ~range () ]
