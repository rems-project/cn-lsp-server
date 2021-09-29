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
    Unix.open_process_args_full cn [| cn ; "--json" ; doc_path |] (Lazy.force env) in
  let module Util = Yojson.Safe.Util in
  try
  let json = Yojson.Safe.from_channel ~fname:doc_path stderr in
  (* {
  "loc": [
    "Region",
    {
      "region_start": { "file": "structs9.c", "line": 8, "char": 13 },
      "region_end": { "file": "structs9.c", "line": 8, "char": 25 },
      "region_cursor": { "file": "structs9.c", "line": 8, "char": 22 }
    }
  ],
  "short": "Undefined behaviour",
  "descr": "(§6.5#2) an exceptional condition occurred during the evaluation of an expression."
  } *)
  let region = json
               |> Util.member "loc"
               |> Util.to_list
               |> (fun x ->
                   assert (String.equal (Util.to_string @@ List.hd x)  "Region");
                   List.tl x)
               |> List.hd in
  let start , end_ = Util.member "region_start" region , Util.member "region_end" region in
  let pos x = Position.create
      ~line:(Util.to_int @@ Util.member "line" x)
      ~character:(Util.to_int @@ Util.member "char" x) in
  let start , end_ = pos start , pos end_ in
  let range = Range.create ~start ~end_ in
  let message = Util.(to_string (member "short" json)
                      ^ "\n" ^ to_string (member "descr" json)) in
  ignore (Unix.close_process_full pipes);
  [ Diagnostic.create ~message ~range () ]
  with
  | Util.Type_error (str , _)
  | Util.Undefined (str , _) ->
  let message = str in
  ignore (Unix.close_process_full pipes);
  let pos = Position.create ~line:0 ~character:0 in
  let range = Range.create ~start:pos ~end_:pos in
  [ Diagnostic.create ~message ~range () ]

