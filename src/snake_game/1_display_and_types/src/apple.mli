open! Core
open! Bonsai_web

(** A [t] represents an apple placed on the grid. *)
type t [@@deriving sexp, equal]

(** [list_of_t t] returns a list of positions occupied by the apple. *)
val list_of_t : t -> Position.t list

(** [spawn_random_exn ~rows ~cols ~invalid_pos] creates an apple placed randomly
   on a rows*cols grid; excluding cells in ~invalid_pos. *)
val spawn_random_exn : rows:int -> cols:int -> invalid_pos:Position.t list -> t

(** [cell_background t pos] computes the background of a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_background : t -> Position.t -> string option
