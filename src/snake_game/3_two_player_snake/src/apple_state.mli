open! Core
open! Bonsai_web

module Model : sig
  type t =
    | Not_started
    | Placed of Apple.t
  [@@deriving sexp, equal]

  (** [apples states] returns a list of [Apple.t]s  for each apple
    who's status isn't [Not_started].
    Intended to be used in the assembly of [Game_elements.t],
    but can't be located there to avoid circular dependencies. *)
  val apples : t list -> Apple.t list
end

module Action : sig
  type t =
    | Spawn of Game_elements.t
    | Tick of Game_elements.t
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
