open Import

type t =
  { stdin : Scheduler.thread Lazy_fiber.t
  ; stderr : Scheduler.thread Lazy_fiber.t
  ; stdout : Scheduler.thread Lazy_fiber.t
  }

let create () =
  let stdout = Lazy_fiber.create Scheduler.create_thread in
  let stderr = Lazy_fiber.create Scheduler.create_thread in
  let stdin = Lazy_fiber.create Scheduler.create_thread in
  { stdout; stderr; stdin }

type error =
  | Unsupported_syntax of Document.Syntax.t
  | Missing_binary of { binary : string }
  | Unexpected_result of { message : string }
  | Unknown_extension of Uri.t

let message = function
  | Unsupported_syntax syntax ->
    sprintf "formatting %s files is not supported"
      (Document.Syntax.human_name syntax)
  | Missing_binary { binary } ->
    sprintf
      "Unable to find %s binary. You need to install %s manually to use the \
       formatting feature."
      binary binary
  | Unknown_extension uri ->
    Printf.sprintf "Unable to format. File %s has an unknown extension"
      (Uri.to_path uri)
  | Unexpected_result { message } -> message

let run _state _doc : (TextEdit.t list, error) result Fiber.t =
  failwith "Fmt.run"
