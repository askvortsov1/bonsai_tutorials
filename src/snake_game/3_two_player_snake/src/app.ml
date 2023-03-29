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

let rows = 3
let cols = 3

let get_keydown_key evt =
  evt##.code
  |> Js_of_ocaml.Js.Optdef.to_option
  |> Option.value_exn
  |> Js_of_ocaml.Js.to_string
;;

let component =
  let open Bonsai.Let_syntax in
  (* State *)
  let%sub player1, player1_inject = Player_state.computation ~rows ~cols ~color:"green" in
  let%sub player2, player2_inject = Player_state.computation ~rows ~cols ~color:"blue" in
  let%sub apple, apple_inject = Apple_state.computation ~rows ~cols in
  let%sub game_elements =
    let%arr player1 = player1
    and player2 = player2
    and apple = apple in
    { Game_elements.snakes = Player_state.Model.snakes [ player1; player2 ]
    ; apples = Apple_state.Model.apples [ apple ]
    }
  in
  (* Tick logic *)
  let%sub () =
    let%sub player1_effect =
      Bonsai.lazy_
        (lazy
          (let%arr player1_inject = player1_inject
           and game_elements = game_elements in
           player1_inject (Move game_elements)))
    in
    let%sub player2_effect =
      Bonsai.lazy_
        (lazy
          (let%arr player2_inject = player2_inject
           and game_elements = game_elements in
           player2_inject (Move game_elements)))
    in
    let%sub apple_effect =
      Bonsai.lazy_
        (lazy
          (let%arr apple_inject = apple_inject
           and game_elements = game_elements in
           apple_inject (Tick game_elements)))
    in
    let effects =
      [ player1_effect; player2_effect; apple_effect ]
      |> Value.all
      |> Value.map ~f:(fun e -> Effect.Many e)
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 2.) effects
  in
  (* Reset logic *)
  let%sub reset_action =
    let%sub player1_effect =
      Bonsai.lazy_
        (lazy
          (let%arr player1_inject = player1_inject
           and game_elements = game_elements in
           player1_inject (Restart game_elements)))
    in
    let%sub player2_effect =
      Bonsai.lazy_
        (lazy
          (let%arr player2_inject = player2_inject
           and game_elements = game_elements in
           player2_inject (Restart game_elements)))
    in
    let%sub apple_effect =
      Bonsai.lazy_
        (lazy
          (let%arr apple_inject = apple_inject
           and game_elements = game_elements in
           apple_inject (Spawn game_elements)))
    in
    [ player1_effect; player2_effect; apple_effect ]
    |> Value.all
    |> Value.map ~f:(fun e -> Effect.Many e)
    |> Bonsai.read
  in
  (* View component *)
  let%sub board = Board.component ~rows ~cols player1 player2 game_elements in
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
