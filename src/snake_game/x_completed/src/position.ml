open! Core

module S = struct
  type t =
    { col : int
    ; row : int
    }
  [@@deriving equal, compare, sexp]
end

module Pos_set = Set.Make (S)
include S

let random_pos ~rows ~cols ~invalid_pos =
  let invalid_pos_set = Pos_set.of_list invalid_pos in
  let valid_pos =
    List.init rows ~f:(fun row -> List.init cols ~f:(fun col -> { row; col }))
    |> List.concat
    |> List.filter ~f:(fun x -> not (Set.mem invalid_pos_set x))
  in
  if List.is_empty valid_pos
  then None
  else (
    let n = Random.int (List.length valid_pos) in
    List.nth valid_pos n)
;;
