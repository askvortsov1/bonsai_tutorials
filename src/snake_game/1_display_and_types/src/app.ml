open! Core
open! Bonsai_web

let rows = 20
let cols = 20

let component =
  let snake = Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color:"green" in
  let apple = Apple.spawn_random_exn ~rows ~cols ~invalid_pos:(Snake.list_of_t snake) in
  Board.component ~rows ~cols (Value.return snake) (Value.return apple)
;;
