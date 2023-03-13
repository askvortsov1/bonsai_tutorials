open! Core
open! Bonsai

type t =
  { score : int
  ; snake : Snake.t
  }
[@@deriving sexp, fields]

module Action : sig
  type t =
    | Restart
    | Move of (Apple.t * (Apple.Action.t -> unit Effect.t))
end

val computation : rows:int -> cols:int -> (t * (Action.t -> unit Effect.t)) Computation.t
