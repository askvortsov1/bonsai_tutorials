open! Core
open! Bonsai_web

module Model : sig
  type t =
    | Not_started
    | Playing of Apple.t
  [@@deriving sexp, equal]
end

module Action : sig
  type t =
    | Spawn of Snake.t option
    | Tick of Snake.t option
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
