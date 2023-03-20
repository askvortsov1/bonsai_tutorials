open! Core
open Bonsai

type t =
  { snakes : Snake.t list
  ; apples : (Apple.t * (Apple.Action.t -> unit Effect.t)) list
  }
[@@deriving sexp]

val occupied_pos : t -> Position.t list
