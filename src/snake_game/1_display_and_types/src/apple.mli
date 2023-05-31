open! Core

(** A [t] represents an apple placed on the grid. *)
type t [@@deriving sexp, equal]

(** [list_of_t t] returns a list of positions occupied by the apple. *)
val list_of_t : t -> Position.t list

(** [spawn_random_exn ~rows ~cols ~invalid_pos] creates an apple placed randomly
   on a rows*cols grid; excluding cells in ~invalid_pos. *)
val spawn_random_exn : rows:int -> cols:int -> invalid_pos:Position.t list -> t

(** [cell_style t pos] computes a [Css_gen.t] style for a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_style : t -> Position.t -> Css_gen.t option
