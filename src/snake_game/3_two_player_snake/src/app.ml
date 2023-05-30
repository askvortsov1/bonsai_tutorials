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
  evt##.key
  |> Js_of_ocaml.Js.Optdef.to_option
  |> Option.value_exn
  |> Js_of_ocaml.Js.to_string
;;

(* $MDX part-begin=state *)
let component =
  let default_snake1 =
    Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color:(`Name "green")
  in
  let default_snake2 =
    let invalid_pos = Snake.list_of_t default_snake1 in
    Snake.spawn_random_exn ~rows ~cols ~invalid_pos ~color:(`Name "green")
  in
  let default_apple1 =
    let invalid_pos = Snake.list_of_t default_snake1 @ Snake.list_of_t default_snake2 in
    Apple.spawn_random_exn ~rows ~cols ~invalid_pos
  in
  let default_apple2 =
    let invalid_pos =
      Snake.list_of_t default_snake1
      @ Snake.list_of_t default_snake2
      @ Apple.list_of_t default_apple1
    in
    Apple.spawn_random_exn ~rows ~cols ~invalid_pos
  in
  let open Bonsai.Let_syntax in
  let%sub player1, player1_inject =
    Player_state.computation ~rows ~cols ~default_snake:default_snake1
  in
  let%sub player2, player2_inject =
    Player_state.computation ~rows ~cols ~default_snake:default_snake2
  in
  let%sub apple1, apple1_inject =
    Apple_state.computation ~rows ~cols ~default_apple:default_apple1
  in
  let%sub apple2, apple2_inject =
    Apple_state.computation ~rows ~cols ~default_apple:default_apple2
  in
  (* $MDX part-end *)
  (* $MDX part-begin=scheduler *)
  let%sub game_elements =
    let%arr player1 = player1
    and player2 = player2
    and apple1 = apple1
    and apple2 = apple2 in
    { Game_elements.snakes = [ player1.snake; player2.snake ]
    ; apples = [ apple1; apple2 ]
    }
  in
  let%sub scheduler = Chain_incr_effects.component game_elements in
  (* $MDX part-end *)
  (* $MDX part-begin=tick *)
  let%sub () =
    let%sub clock_effect =
      let%arr player1_inject = player1_inject
      and player2_inject = player2_inject
      and apple1_inject = apple1_inject
      and apple2_inject = apple2_inject
      and scheduler = scheduler in
      scheduler
        [ (fun g -> player1_inject (Move g))
        ; (fun g -> player2_inject (Move g))
        ; (fun g -> apple1_inject (Tick g))
        ; (fun g -> apple2_inject (Tick g))
        ]
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 0.25) clock_effect
  in
  (* $MDX part-end *)
  (* $MDX part-begin=reset *)
  let%sub reset_action =
    let%arr player1_inject = player1_inject
    and player2_inject = player2_inject
    and apple1_inject = apple1_inject
    and apple2_inject = apple2_inject
    and scheduler = scheduler in
    scheduler
      [ (fun g -> player1_inject (Restart g))
      ; (fun g -> player2_inject (Restart g))
      ; (fun g -> apple1_inject (Place g))
      ; (fun g -> apple2_inject (Place g))
      ]
  in
  (* $MDX part-end *)
  (* $MDX part-begin=on_keydown *)
  let%sub on_keydown =
    let%arr player1_inject = player1_inject
    and player2_inject = player2_inject in
    fun evt ->
      match get_keydown_key evt with
      | "w" -> player1_inject (Change_direction Up)
      | "s" -> player1_inject (Change_direction Down)
      | "a" -> player1_inject (Change_direction Left)
      | "d" -> player1_inject (Change_direction Right)
      | "ArrowUp" -> player2_inject (Change_direction Up)
      | "ArrowDown" -> player2_inject (Change_direction Down)
      | "ArrowLeft" -> player2_inject (Change_direction Left)
      | "ArrowRight" -> player2_inject (Change_direction Right)
      | _ -> Effect.Ignore
  in
  (* $MDX part-end *)
  let%sub board = Board.component ~rows ~cols player1 player2 game_elements in
  let%arr board = board
  and on_keydown = on_keydown
  and reset_action = reset_action in
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
