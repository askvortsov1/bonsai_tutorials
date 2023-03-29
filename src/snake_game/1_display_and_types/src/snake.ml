open! Core

type t =
  { pos : Position.t Deque.t
  ; left_to_grow : int
  ; color : string
  }
[@@deriving sexp]

let equal a b =
  List.equal Position.equal (Deque.to_list a.pos) (Deque.to_list b.pos)
  && Int.equal a.left_to_grow b.left_to_grow
;;

let list_of_t s = Deque.to_list s.pos

let spawn_random_exn ~rows ~cols ~color =
  let head = Position.random_pos ~rows ~cols ~invalid_pos:[] in
  let head_exn = Option.value_exn head in
  { pos = Deque.of_array [| head_exn |]; left_to_grow = 0; color }
;;

let cell_background s pos =
  if List.mem (list_of_t s) pos ~equal:Position.equal then Some s.color else None
;;
