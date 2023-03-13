open! Core
open! Bonsai_web

type t = Position.t Deque.t [@@deriving sexp]

let equal a b = List.equal Position.equal (Deque.to_list a) (Deque.to_list b)

let set_of_t x =
  let module Pos_set = Set.Make (Position) in
  x |> Deque.to_list |> Pos_set.of_list
;;

let head s = Deque.peek_front_exn s

let spawn_random ~rows ~cols =
  let head = Position.random_pos ~rows ~cols ~invalid_pos:[] in
  let head_exn = Option.value_exn head in
  Deque.of_array [| head_exn |]
;;

let move ~grow s dir =
  let new_head = Direction.next_position dir (head s) in
  Deque.enqueue_front s new_head;
  if not grow then ignore (Deque.dequeue_front s : Position.t option);
  s
;;

let is_out_of_bounds ~rows ~cols s =
  let { Position.row; col } = head s in
  row < 0 || row >= rows || col < 0 || col >= cols
;;

let is_eatting_self s =
  let module Pos_set = Set.Make (Position) in
  match Deque.to_list s with
  | head :: tail -> Set.mem (Pos_set.of_list tail) head
  | [] -> false (* This should never happen. *)
;;
