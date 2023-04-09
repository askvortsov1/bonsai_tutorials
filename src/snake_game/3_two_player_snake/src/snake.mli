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

(** [move t] moves a snake 1 step in its current direction. It may or may not grow,
    depending on its internal state. *)
val move : t -> t

(** [with_direction t dir] returns a [Snake.t] with an updated direction. *)
val with_direction : t -> Direction.t -> t

(** [is_eatting_apple t] returns true iff the snake's head is overlapping
    with the provided [Apple.t].  *)
val is_eatting_apple : t -> Apple.t -> bool

(** [is_eatting_self t] returns true iff the snake's head is overlapping with any of
    the snake's body segments.  *)
val is_eatting_self : t -> bool

(** [is_out_of_bounds ~rows ~cols t] returns true iff the snake's head has gone
    outside of the [rows]*[cols] grid. *)
val is_out_of_bounds : rows:int -> cols:int -> t -> bool

(** [grow_eventually ~by] updates a snake's internal state to grow 1 cell
    for the next [by] times [move] is called. *)
val grow_eventually : by:int -> t -> t
