open! Core

module Color = struct
  include Css_gen.Color

  let equal a b = Css_gen.Color.compare a b |> Int.equal 0
end

(* $MDX part-begin=t_new_field *)
type t =
  { pos : Position.t list
  ; direction : Direction.t
  ; color : Color.t
  ; left_to_grow : int
  }
[@@deriving sexp, equal]
(* $MDX part-end *)

let list_of_t s = s.pos

(* $MDX part-begin=new_field_initialization *)
let spawn_random_exn ~rows ~cols ~invalid_pos ~color =
  let head = Position.random_pos ~rows ~cols:(cols / 2) ~invalid_pos in
  let head_exn = Option.value_exn head in
  { pos = [ head_exn ]; direction = Direction.Right; left_to_grow = 0; color }
;;

let cell_style s pos =
  if List.mem (list_of_t s) pos ~equal:Position.equal
  then Some (Css_gen.background_color s.color)
  else None
;;

(* $MDX part-end *)

(* $MDX part-begin=move_impl *)
let head s = List.hd_exn s.pos

let move s =
  let new_head = Position.step (head s) s.direction in
  let new_pos =
    let with_head = new_head :: s.pos in
    if Int.equal s.left_to_grow 0 then List.drop_last_exn with_head else with_head
  in
  let left_to_grow = Int.max 0 (s.left_to_grow - 1) in
  { s with left_to_grow; pos = new_pos }
;;

(* $MDX part-end *)

(* $MDX part-begin=other_impl *)
let with_direction s direction = { s with direction }
let grow_eventually ~by s = { s with left_to_grow = s.left_to_grow + by }

let is_out_of_bounds ~rows ~cols s =
  let { Position.row; col } = head s in
  row < 0 || row >= rows || col < 0 || col >= cols
;;

let is_eatting_apple s a = List.mem (Apple.list_of_t a) (head s) ~equal:Position.equal

let is_eatting_self s =
  match list_of_t s with
  | head :: tail -> List.mem tail head ~equal:Position.equal
  (* This should never happen. *)
  | [] -> false
;;

(* $MDX part-end *)
