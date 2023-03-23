open! Core
open! Bonsai_web

module Style =
[%css.raw
{|
html,body{min-height:100%; height:100%;}

.app {
  width: 100%;
  height: 100%;
}
|}]

let rows = 20
let cols = 20

let get_keydown_key evt =
  evt##.code
  |> Js_of_ocaml.Js.Optdef.to_option
  |> Option.value_exn
  |> Js_of_ocaml.Js.to_string
;;

let component =
  let open Bonsai.Let_syntax in
  (* State *)
  let%sub player1, player1_inject = Player.computation ~rows ~cols ~color:"green" in
  let%sub player2, player2_inject = Player.computation ~rows ~cols ~color:"blue" in
  let%sub apple, apple_inject = Apple.computation ~rows ~cols in
  let%sub game_elements =
    let%arr player1 = player1
    and player2 = player2
    and apple = apple
    and apple_inject = apple_inject in
    { Game_elements.snakes = Player.snakes [ player1; player2 ]
    ; apples = [ apple, apple_inject ]
    }
  in
  (* Tick logic *)
  let%sub () =
    let%sub clock_effect =
      let%arr player1_inject = player1_inject
      and player2_inject = player2_inject
      and game_elements = game_elements in
      Effect.Many
        [ player1_inject (Move game_elements); player2_inject (Move game_elements) ]
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 0.25) clock_effect
  in
  (* Reset logic *)
  let%sub reset_action =
    let%arr player1_inject = player1_inject
    and player2_inject = player2_inject
    and apple_inject = apple_inject
    and game_elements = game_elements in
    let invalid_pos = Game_elements.occupied_pos game_elements in
    Effect.Many
      [ player1_inject Restart; player2_inject Restart; apple_inject (Spawn invalid_pos) ]
  in
  (* View component *)
  let%sub board = Board.component ~rows ~cols player1 player2 apple in
  let%arr board = board
  and player1_inject = player1_inject
  and player2_inject = player2_inject
  and reset_action = reset_action in
  let on_keydown evt =
    match get_keydown_key evt with
    | "KeyW" -> player1_inject (Change_direction Up)
    | "KeyS" -> player1_inject (Change_direction Down)
    | "KeyA" -> player1_inject (Change_direction Left)
    | "KeyD" -> player1_inject (Change_direction Right)
    | "ArrowUp" -> player2_inject (Change_direction Up)
    | "ArrowDown" -> player2_inject (Change_direction Down)
    | "ArrowLeft" -> player2_inject (Change_direction Left)
    | "ArrowRight" -> player2_inject (Change_direction Right)
    | _ -> Effect.Ignore
  in
  Vdom.(
    Node.div
      ~attr:
        (Attr.many
           [ Attr.on_keydown on_keydown
           ; Attr.on_click (fun _ -> reset_action)
           ; Attr.class_ Style.app
           ])
      [ board ])
;;
