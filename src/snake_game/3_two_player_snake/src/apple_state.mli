open! Core
open! Bonsai_web

module Model : sig
  type t = Apple.t [@@deriving sexp, equal]
end

(* $MDX part-begin=action *)
module Action : sig
  type t =
    | Place of Game_elements.t
    | Tick of Game_elements.t
  [@@deriving sexp]
end
(* $MDX part-end *)

(* $MDX part-begin=computation *)
val computation
  :  rows:int
  -> cols:int
  -> default_apple:Model.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
(* $MDX part-end *)
