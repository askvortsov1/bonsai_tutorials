open! Core
open! Bonsai

module Action : sig
  type t =
    | Restart of Game_elements.t
    | Move of Game_elements.t
    | Change_direction of Direction.t
end

module Model : sig
  module End_reason : sig
    type t =
      | Ate_self
      | Out_of_bounds
    [@@deriving sexp, equal]
  end

  module Status : sig
    type t =
      | Not_started
      | Playing
      | Game_over of End_reason.t
    [@@deriving sexp, equal, variants]
  end

  type t =
    { score : int
    ; snake : Snake.t
    ; status : Status.t
    }
  [@@deriving sexp, equal, fields]
end

val computation
  :  rows:int
  -> cols:int
  -> default_snake:Snake.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
