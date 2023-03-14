open! Core
open! Bonsai_web

let rows = 20
let cols = 20

let component =
  let snake = Snake.spawn_random ~rows ~cols in
  let apple = Apple.spawn_random ~rows ~cols ~invalid_pos:(Snake.set_of_t snake) in
  let score = 100 in
  let player_status = Player_status.Playing in
  Board.component
    ~rows
    ~cols
    (Value.return snake)
    (Value.return score)
    (Value.return player_status)
    (Value.return apple)
;;
