open! Core

(** A [t] represents a direction on the playing board. *)
type t =
 | Up
 | Down
 | Right
 | Left
[@@deriving sexp, equal]

val next_position : t -> Position.t -> Position.t