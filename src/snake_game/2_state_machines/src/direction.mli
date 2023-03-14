open! Core

(** A [t] represents a direction on the playing board. *)
type t =
  | Up
  | Down
  | Right
  | Left
[@@deriving sexp, equal]

(** [next_position t pos] returns the next position after taking a step in
    [t] from [pos] *)
val next_position : t -> Position.t -> Position.t
