open! Core

type t =
  { snakes : Snake.t list
  ; apples : Apple.t list
  }
[@@deriving sexp]

(** [occupied_pos t] returns the list of all positions occupied by some game element. *)
val occupied_pos : t -> Position.t list
