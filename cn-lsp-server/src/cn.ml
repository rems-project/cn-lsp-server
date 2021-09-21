open Import

(* Can use Yojson to get Json from in_channel *)
let get_errs (doc : Document.t) : Diagnostic.t list =
  let doc_path = Uri.to_path @@ Document.uri doc in
  let cn = Fpath.to_string @@ Option.value_exn @@ Bin.which "cn" in
  let _stdin, _stdout, stderr =
    Unix.open_process_args_full cn [| doc_path |]
      [| (* no env *) |] in
  let stderr = Scanf.Scanning.from_channel stderr in
  let message = Scanf.bscanf stderr "%s" (fun x -> x) in
  let pos = Position.create ~line:0 ~character:0 in
  let range = Range.create ~start:pos ~end_:pos in
  [ Diagnostic.create ~message ~range () ]
