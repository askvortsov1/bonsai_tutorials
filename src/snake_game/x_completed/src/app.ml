open! Core
open! Bonsai_web

let rows = 20
let cols = 20

let component =
  let open Bonsai.Let_syntax in
  (* State *)
  let%sub player, player_inject = Player.computation ~rows ~cols in
  let%sub invalid_pos =
    let%arr player = player in
    Snake.set_of_t player.snake
  in
  let%sub apple, apple_inject = Apple.computation ~rows ~cols ~invalid_pos in
  (* Tick logic *)
  let%sub clock_action =
    let%arr player_inject = player_inject
    and apple = apple
    and apple_inject = apple_inject in
    player_inject (Move (apple, apple_inject))
  in
  let%sub () = Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 1.0) clock_action in
  (* Reset logic *)
  let%sub reset_action =
    let%arr player_inject = player_inject
    and apple_inject = apple_inject in
    Effect.Many [ player_inject Restart; apple_inject Spawn ]
  in
  let%sub () = Bonsai.Edge.lifecycle ~on_activate:reset_action () in
  (* View component *)
  Board.component ~reset_action ~rows ~cols player apple
;;
