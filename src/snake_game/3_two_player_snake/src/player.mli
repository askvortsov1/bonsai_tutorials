open! Core
open! Bonsai

module End_reason : sig
  type t =
    | Ate_self
    | Out_of_bounds
  [@@deriving sexp, equal]
end

module Data : sig
  type t =
    { score : int
    ; snake : Snake.t
    ; direction : Direction.t
    }
  [@@deriving sexp, equal, fields]
end

type t =
  | Not_started
  | Playing of Data.t
  | Game_over of (Data.t * End_reason.t)
[@@deriving sexp, equal, variants]

(** [snake_pos t] returns a list of positions occupied by the player's snake.
    If the game hasn't started, this will return an empty list. *)
val snake_pos : t -> Position.t list

(** [snakes ps] returns a list of snakes for each player who's status isn't
    [Not_started]. *)
val snakes : t list -> Snake.t list

module Action : sig
  type t =
    | Restart
    | Move of Game_elements.t
    | Change_direction of Direction.t
end

val computation
  :  rows:int
  -> cols:int
  -> color:string
  -> (t * (Action.t -> unit Effect.t)) Computation.t
