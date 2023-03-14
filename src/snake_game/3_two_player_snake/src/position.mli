open! Core

(** A [t] represents a square on the playing area, identified by its row and
    column. *)
type t =
  { col : int
  ; row : int
  }
[@@deriving equal, compare, sexp]

(** [random_pos ~rows ~cols ~invalid_pos] returns a random [t] with
    [t.row < rows] and [t.col < cols]. *)
val random_pos : rows:int -> cols:int -> invalid_pos:t list -> t option
