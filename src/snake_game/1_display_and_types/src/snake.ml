open! Core

type t =
  { pos : Position.t list
  ; left_to_grow : int
  ; color : string
  }
[@@deriving sexp, equal]

let list_of_t s = s.pos

let spawn_random_exn ~rows ~cols ~color =
  let head = Position.random_pos ~rows ~cols ~invalid_pos:[] in
  let head_exn = Option.value_exn head in
  { pos = [ head_exn ]; left_to_grow = 0; color }
;;

let cell_background s pos =
  if List.mem (list_of_t s) pos ~equal:Position.equal then Some s.color else None
;;
