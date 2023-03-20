open! Core

(** A [t] represents a snake, which keeps track of how much it
    has left to grow. *)
type t [@@deriving sexp, equal]

(** [list_of_t t] returns a list of [Position.t]s occupied by the snake. *)
val list_of_t : t -> Position.t list

(** [head t] returns the [Position.t] occupied by the head (first element) of the snake. *)
val head : t -> Position.t

(** [is_eatting_self t] returns true iff the snake's head is overlapping with any of
    the snake's body segments.  *)
val is_eatting_self : t -> bool

(** [is_out_of_bounds ~rows ~cols t] returns true iff the snake's head has gone
    outside of the [rows]*[cols] grid. *)
val is_out_of_bounds : rows:int -> cols:int -> t -> bool

(** [spawn_random ~rows ~cols ~invalid_pos] creates a length-1 snake
    placed randomly on the left half ([col < cols/2]) of a rows*cols grid.
    The provided color will be used in calls to [cell_background]. *)
val spawn_random : rows:int -> cols:int -> color:string -> t

(** [move t dir] moves a snake 1 step in [dir]. It may or may not grow,
    depending on its internal state. *)
val move : t -> Direction.t -> t

(** [grow_eventually ~by] updates a snake's internal state to grow 1 cell
    for the next [by] times [move] is called. *)
val grow_eventually : by:int -> t -> t

(** [cell_background t pos] computes the background of a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_background : t -> Position.t -> string option
