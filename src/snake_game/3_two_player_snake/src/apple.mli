open! Core
open! Bonsai_web

(** A [t] represents an apple which may or may not be placed somewhere
    on the grid. *)
type t = Position.t option [@@deriving sexp]

(** [set_of_t t] returns a set of positions occupied by the apple. *)
val set_of_t : t -> Set.Make(Position).t

(** [spawn_random ~rows ~cols ~invalid_pos] creates an apple placed randomly
    on a rows*cols grid; excluding cells in ~invalid_pos. *)
val spawn_random : rows:int -> cols:int -> invalid_pos:Set.Make(Position).t -> t

(** [cell_background t pos] computes the background of a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_background : t -> Position.t -> string option

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
