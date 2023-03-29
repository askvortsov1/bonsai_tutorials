open! Core
open! Bonsai_web

module Model : sig
  type t =
    | Not_started
    | Playing of Apple.t
  [@@deriving sexp, equal]

  val apple_pos : t -> Position.t list
end

module Action : sig
  type t =
    | Spawn of Position.t list
    | Eatten of Position.t list
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
