open! Core

(** A [t] represents a snake, which keeps track of how much it
    has left to grow. *)
type t [@@deriving sexp, equal]

(** [list_of_t t] returns a list of [Position.t]s occupied by the snake. *)
val list_of_t : t -> Position.t list

(** [spawn_random_exn ~rows ~cols ~invalid_pos ~color] creates a length-1 snake
    placed randomly on the left half ([col < cols/2]) of a rows*cols grid.
    The provided color will be used in calls to [cell_style]. *)
val spawn_random_exn
  :  rows:int
  -> cols:int
  -> invalid_pos:Position.t list
  -> color:Css_gen.Color.t
  -> t

(** [cell_style t pos] computes a [Css_gen.t] style for a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_style : t -> Position.t -> Css_gen.t option
