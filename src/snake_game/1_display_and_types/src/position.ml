(* $MDX part-begin=type *)
open! Core

type t =
  { col : int
  ; row : int
  }
[@@deriving equal, sexp]
(* $MDX part-end *)

(* $MDX part-begin=step *)
let step { row; col } dir =
  match dir with
  | Direction.Left -> { row; col = col - 1 }
  | Right -> { row; col = col + 1 }
  | Up -> { row = row - 1; col }
  | Down -> { row = row + 1; col }
;;

(* $MDX part-end *)

(* $MDX part-begin=random *)
let random_pos ~rows ~cols ~invalid_pos =
  let valid_pos =
    List.init rows ~f:(fun row -> List.init cols ~f:(fun col -> { row; col }))
    |> List.concat
    |> List.filter ~f:(fun x -> not (List.mem ~equal invalid_pos x))
  in
  if List.is_empty valid_pos
  then None
  else (
    let n = Random.int (List.length valid_pos) in
    List.nth valid_pos n)
;;
(* $MDX part-end *)
