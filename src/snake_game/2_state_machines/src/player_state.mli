open! Core
open! Bonsai

module Model : sig
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

  val snake_pos : t -> Position.t list
end

module Action : sig
  type t =
    | Restart
    | Move of (Apple.t * (Apple_state.Action.t -> unit Effect.t))
    | Change_direction of Direction.t
end

val computation
  :  rows:int
  -> cols:int
  -> color:string
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
