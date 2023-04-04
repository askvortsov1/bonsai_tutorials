open! Core

type t =
  { pos : Position.t list
  ; left_to_grow : int
  ; color : string
  }
[@@deriving sexp, equal]

let list_of_t s = s.pos

let spawn_random_exn ~rows ~cols ~invalid_pos ~color =
  let head = Position.random_pos ~rows ~cols ~invalid_pos in
  let head_exn = Option.value_exn head in
  { pos = [ head_exn ]; left_to_grow = 0; color }
;;

let cell_background s pos =
  if List.mem (list_of_t s) pos ~equal:Position.equal then Some s.color else None
;;

let head s = List.hd_exn s.pos

let move s dir =
  let new_head = Position.step (head s) dir in
  let new_pos =
    let with_head = new_head :: s.pos in
    if Int.equal s.left_to_grow 0 then List.drop_last_exn with_head else with_head
  in
  let left_to_grow = Int.max 0 (s.left_to_grow - 1) in
  { s with left_to_grow; pos = new_pos }
;;

let grow_eventually ~by s = { s with left_to_grow = s.left_to_grow + by }

let is_out_of_bounds ~rows ~cols s =
  let { Position.row; col } = head s in
  row < 0 || row >= rows || col < 0 || col >= cols
;;

let is_eatting_apple s a = List.exists (Apple.list_of_t a) ~f:(Position.equal (head s))

let is_eatting_self s =
  match list_of_t s with
  | head :: tail -> List.mem tail head ~equal:Position.equal
  | [] -> false (* This should never happen. *)
;;
