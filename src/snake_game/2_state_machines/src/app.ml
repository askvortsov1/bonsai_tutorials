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
  let%sub player, player_inject = Player_state.computation ~rows ~cols ~color:"green" in
  let%sub apple, apple_inject = Apple_state.computation ~rows ~cols in
  (* Tick logic *)
  let%sub () =
    let%sub clock_effect =
      let%arr player_inject = player_inject
      and apple = apple
      and apple_inject = apple_inject in
      match apple with
      | Playing apple -> player_inject (Move (apple, apple_inject))
      | Not_started -> Effect.Ignore
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 0.25) clock_effect
  in
  (* Reset logic *)
  let%sub reset_action =
    let%arr player_inject = player_inject
    and apple_inject = apple_inject
    and player = player
    and apple = apple in
    let invalid_pos =
      Player_state.Model.snake_pos player @ Apple_state.Model.apple_pos apple
    in
    Effect.Many [ player_inject Restart; apple_inject (Spawn invalid_pos) ]
  in
  (* View component *)
  let%sub board = Board.component ~rows ~cols player apple in
  let%arr board = board
  and player_inject = player_inject
  and reset_action = reset_action in
  let on_keydown evt =
    match get_keydown_key evt with
    | "KeyW" -> player_inject (Change_direction Up)
    | "KeyS" -> player_inject (Change_direction Down)
    | "KeyA" -> player_inject (Change_direction Left)
    | "KeyD" -> player_inject (Change_direction Right)
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
