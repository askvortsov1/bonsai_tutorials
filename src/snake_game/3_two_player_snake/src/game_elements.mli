open! Core

type t =
  { snakes : Snake.t list
  ; apples : Apple.t list
  }
[@@deriving sexp]

val occupied_pos : t -> Position.t list
