open! Core
open! Bonsai_web

type t = Position.t option [@@deriving sexp, equal]

let set_of_t t =
  let module Pos_set = Set.Make (Position) in
  match t with
  | Some pos -> Pos_set.singleton pos
  | None -> Pos_set.empty
;;

let spawn_random ~rows ~cols ~invalid_pos =
  Position.random_pos ~rows ~cols ~invalid_pos:(Set.to_list invalid_pos)
;;

let cell_background a pos =
  if Option.mem a pos ~equal:Position.equal then Some "red" else None
;;
