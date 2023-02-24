open! Core

type t =
  { readme : string
  ; source : string list Mem_fs.t
  }
[@@deriving sexp]

(** [clean t] removes all infra-related annotations, such as
    MDX comment lines. *)
val clean : t -> t

module Name : sig
  type t =
    { i : int
    ; name : string
    ; src_dirname : string
    ; readme_name : string
    }
  [@@deriving sexp, typed_fields]

  (** [process_name raw] splits chapter names of the form
    {i}_{name} into tuples, None if the format is invalid. *)
  val resolve : string -> t option
end
