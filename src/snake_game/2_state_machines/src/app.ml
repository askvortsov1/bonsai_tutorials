open! Core
open! Bonsai_web

(* $MDX part-begin=style *)
module Style =
[%css
stylesheet
  {|
html,body{min-height:100%; height:100%;}

.app {
  width: 100%;
  height: 100%;
}
|}]
(* $MDX part-end *)

let rows = 20
let cols = 20

(* $MDX part-begin=keydown_util *)
let get_keydown_key evt =
  evt##.key
  |> Js_of_ocaml.Js.Optdef.to_option
  |> Option.value_exn
  |> Js_of_ocaml.Js.to_string
;;

(* $MDX part-end *)

(* $MDX part-begin=state *)
let component =
  let default_snake =
    Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color:(`Name "green")
  in
  let default_apple =
    Apple.spawn_random_exn ~rows ~cols ~invalid_pos:(Snake.list_of_t default_snake)
  in
  let open Bonsai.Let_syntax in
  let%sub player, player_inject = Player_state.computation ~rows ~cols ~default_snake in
  let%sub snake =
    let%arr player = player in
    player.snake
  in
  let%sub apple, apple_inject =
    Apple_state.computation ~rows ~cols ~default_apple snake
  in
  (* $MDX part-end *)
  (* $MDX part-begin=tick *)
  let%sub () =
    let%sub clock_effect =
      let%arr player_inject = player_inject
      and apple_inject = apple_inject
      and apple = apple in
      Effect.Many [ player_inject (Move apple); apple_inject Tick ]
    in
    Bonsai.Clock.every
      ~when_to_start_next_effect:`Every_multiple_of_period_blocking
      (Time_ns.Span.of_sec 0.25)
      clock_effect
  in
  (* $MDX part-end *)
  (* $MDX part-begin=reset *)
  let%sub on_reset =
    let%arr player_inject = player_inject
    and apple_inject = apple_inject in
    Effect.Many [ player_inject Restart; apple_inject Place ]
  in
  (* $MDX part-end *)
  (* $MDX part-begin=on_keydown *)
  let%sub on_keydown =
    let%arr player_inject = player_inject in
    fun evt ->
      match get_keydown_key evt with
      | "w" -> player_inject (Change_direction Up)
      | "s" -> player_inject (Change_direction Down)
      | "a" -> player_inject (Change_direction Left)
      | "d" -> player_inject (Change_direction Right)
      | _ -> Effect.Ignore
  in
  (* $MDX part-end *)
  (* $MDX part-begin=view *)
  let%sub board = Board.component ~rows ~cols player apple in
  let%arr board = board
  and on_keydown = on_keydown
  and on_reset = on_reset in
  Vdom.(
    Node.div
      ~attrs:[ Attr.on_keydown on_keydown; Attr.on_click (fun _ -> on_reset); Style.app ]
      [ board ])
;;
(* $MDX part-end *)
