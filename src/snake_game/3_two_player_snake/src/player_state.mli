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

  (** [snakes ps] returns a list of snakes for each player who's status isn't
      [Not_started]. Intended to be used in the assembly of [Game_elements.t],
      but can't be located there to avoid circular dependencies. *)
  val snakes : t list -> Snake.t list
end

module Action : sig
  type t =
    | Restart of Game_elements.t
    | Move of Game_elements.t
    | Change_direction of Direction.t
end

val computation
  :  rows:int
  -> cols:int
  -> color:string
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
