open! Core
open! Bonsai_web

(** A [t] represents an apple which may or may not be placed somewhere
    on the grid. *)
type t = Position.t option [@@deriving sexp]

(** [list_of_t t] returns a list of positions occupied by the apple. *)
val list_of_t : t -> Position.t list

(** [spawn_random ~rows ~cols ~invalid_pos] creates an apple placed randomly
   on a rows*cols grid; excluding cells in ~invalid_pos. *)
val spawn_random : rows:int -> cols:int -> invalid_pos:Position.t list -> t

(** [is_eatten t s] returns true iff the apple is at the same position as the given
    snake's head.  *)
val is_eatten : t -> Snake.t -> bool

(** [cell_background t pos] computes the background of a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_background : t -> Position.t -> string option
