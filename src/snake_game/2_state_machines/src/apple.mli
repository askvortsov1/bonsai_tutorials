open! Core
open! Bonsai_web

type t = Position.t option [@@deriving sexp]

val set_of_t : t -> Set.Make(Position).t
val spawn_random : rows:int -> cols:int -> invalid_pos:Set.Make(Position).t -> t

module Action : sig
  type t =
    | Spawn
    | Eatten
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> invalid_pos:Set.Make(Position).t Value.t
  -> (t * (Action.t -> unit Effect.t)) Computation.t
