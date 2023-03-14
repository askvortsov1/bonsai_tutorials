open! Core

(** A [t] represents the readme and completed source code for a chapter of a tutorial. *)
type t =
  { readme : string
  ; source : string Mem_fs.t
  }
[@@deriving sexp]

(** [clean t] removes all infra-related annotations, such as
    MDX comment lines.
    Because tutorial chapter sources must have differently named
    .opam files so that all can build at once, convention is to name them
    [project_name][chapter_index].opam. We want to strip out the
    [chapter_index] suffix. *)
val clean : t -> t Or_error.t

module Name : sig
  type t =
    { i : int
    ; name : string
    ; src_dirname : string
    ; readme_name : string
    }
  [@@deriving sexp, typed_fields]

  (** [process_name raw] splits chapter names of the form
    "[i]_[name]" into tuples, [None] if the format is invalid. *)
  val resolve : string -> t option
end
