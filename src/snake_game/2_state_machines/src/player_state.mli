(* $MDX part-begin=action *)
open! Core
open! Bonsai

module Action : sig
  type t =
    | Restart
    | Move of Apple.t option
    | Change_direction of Direction.t
end
(* $MDX part-end *)

(* $MDX part-begin=model *)
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
      }
    [@@deriving sexp, equal, fields]
  end

  type t =
    | Not_started
    | Playing of Data.t
    | Game_over of (Data.t * End_reason.t)
  [@@deriving sexp, equal, variants]
end
(* $MDX part-end *)

(* $MDX part-begin=computation *)
val computation
  :  rows:int
  -> cols:int
  -> color:Css_gen.Color.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
(* $MDX part-end *)
