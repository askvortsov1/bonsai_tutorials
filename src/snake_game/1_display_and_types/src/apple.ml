open! Core
open! Bonsai_web

type t = Position.t option [@@deriving sexp, equal]

let list_of_t t =
  match t with
  | Some pos -> [ pos ]
  | None -> []
;;

let spawn_random ~rows ~cols ~invalid_pos = Position.random_pos ~rows ~cols ~invalid_pos
let is_eatten a s = Option.mem a (Snake.head s) ~equal:Position.equal

let cell_background a pos =
  if Option.mem a pos ~equal:Position.equal then Some "red" else None
;;
