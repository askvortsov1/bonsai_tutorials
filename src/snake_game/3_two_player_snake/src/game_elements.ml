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

let print t =
  let snake_head s = List.hd_exn (Snake.list_of_t s) in
  let apple_pos a = List.hd_exn (Apple.list_of_t a) in
  String.concat
    ~sep:"\n"
    (List.join
       [ List.map t.snakes ~f:(fun snake ->
           sprintf "Head: %d, %d" (snake_head snake).row (snake_head snake).col)
       ; List.map t.apples ~f:(fun apple ->
           sprintf "Pos: %d, %d" (apple_pos apple).row (apple_pos apple).col)
       ])
;;
