open! Core
open! Bonsai_web

type t [@@deriving sexp, equal]

val set_of_t : t -> Set.Make(Position).t
val head : t -> Position.t
val is_eatting_self : t -> bool
val is_out_of_bounds : rows:int -> cols:int -> t -> bool
val spawn_random : rows:int -> cols:int -> color:string -> t
val move : t -> Direction.t -> t
val grow_eventually : by:int -> t -> t
val cell_background : t -> Position.t -> string option
