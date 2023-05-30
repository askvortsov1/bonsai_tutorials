open! Core
open! Bonsai_web

module Model : sig
  type t = Apple.t [@@deriving sexp, equal]
end

module Action : sig
  type t =
    | Place
    | Tick
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> default_apple:Model.t
  -> Snake.t Value.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
