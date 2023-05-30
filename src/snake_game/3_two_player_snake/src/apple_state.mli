open! Core
open! Bonsai_web

module Model : sig
  type t = Apple.t [@@deriving sexp, equal]
end

module Action : sig
  type t =
    | Place of Game_elements.t
    | Tick of Game_elements.t
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> default_apple:Model.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
