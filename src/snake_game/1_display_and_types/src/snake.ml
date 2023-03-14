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

let set_of_t x =
  let module Pos_set = Set.Make (Position) in
  x.pos |> Deque.to_list |> Pos_set.of_list
;;

let head s = Deque.peek_front_exn s.pos

let spawn_random ~rows ~cols ~color =
  let head = Position.random_pos ~rows ~cols ~invalid_pos:[] in
  let head_exn = Option.value_exn head in
  { pos = Deque.of_array [| head_exn |]; left_to_grow = 0; color }
;;

let move s dir =
  let new_head = Direction.next_position dir (head s) in
  Deque.enqueue_front s.pos new_head;
  if Int.equal s.left_to_grow 0 then ignore (Deque.dequeue_back s.pos : Position.t option);
  let left_to_grow = Int.max 0 (s.left_to_grow - 1) in
  { s with left_to_grow }
;;

let grow_eventually ~by s = { s with left_to_grow = s.left_to_grow + by }

let is_out_of_bounds ~rows ~cols s =
  let { Position.row; col } = head s in
  row < 0 || row >= rows || col < 0 || col >= cols
;;

let is_eatting_self s =
  let module Pos_set = Set.Make (Position) in
  match Deque.to_list s.pos with
  | head :: tail -> Set.mem (Pos_set.of_list tail) head
  | [] -> false (* This should never happen. *)
;;

let cell_background s =
  let set = set_of_t s in
  fun pos -> if Set.mem set pos then Some s.color else None
;;
