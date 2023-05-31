open! Core

type t =
  { snakes : Snake.t list
  ; apples : Apple.t list
  }
[@@deriving sexp]

let occupied_pos t =
  let snake_pos = t.snakes |> List.map ~f:Snake.list_of_t |> List.join in
  let apple_pos = t.apples |> List.map ~f:Apple.list_of_t |> List.join in
  snake_pos @ apple_pos
;;
