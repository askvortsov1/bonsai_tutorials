open! Core
open! Bonsai

type t =
  { score : int
  ; snake : Snake.t
  ; status : Player_status.t
  }
[@@deriving sexp, fields]

module Action : sig
  type t =
    | Restart
    | Move of (Apple.t * (Apple.Action.t -> unit Effect.t))
    | Change_direction of Direction.t
end

val computation
  :  rows:int
  -> cols:int
  -> color:string
  -> (t * (Action.t -> unit Effect.t)) Computation.t
