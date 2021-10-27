(** Generic formatting facility for OCaml and Reason sources.

    Relies on [ocamlformat] for OCaml and [refmt] for reason *)

open Import

type t

val create : unit -> t

type error =
  | Missing_binary of { binary : string }
  | Unexpected_result of { message : string }
  | Unknown_extension of Uri.t

val message : error -> string

val run : t -> Document.t -> (TextEdit.t list, error) result Fiber.t
