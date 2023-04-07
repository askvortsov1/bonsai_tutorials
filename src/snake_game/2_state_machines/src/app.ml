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
  let%sub player, player_inject =
    Player_state.computation ~rows ~cols ~color:(`Name "green")
  in
  let%sub apple, apple_inject = Apple_state.computation ~rows ~cols in
  let%sub snake_apple =
    let%arr apple = apple
    and player = player in
    let apple_opt =
      match apple with
      | Playing apple -> Some apple
      | Not_started -> None
    in
    let snake_opt =
      match player with
      | Playing p | Game_over (p, _) -> Some p.snake
      | Not_started -> None
    in
    snake_opt, apple_opt
  in
  let%sub scheduler = Chain_incr_effects.component snake_apple in
  (* Tick logic *)
  let%sub () =
    let%sub clock_effect =
      let%arr player_inject = player_inject
      and apple_inject = apple_inject
      and scheduler = scheduler in
      scheduler
        [ (fun (_s, a) -> player_inject (Move a))
        ; (fun (s, _a) -> apple_inject (Tick s))
        ]
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 0.25) clock_effect
  in
  (* Reset logic *)
  let%sub reset_action =
    let%arr player_inject = player_inject
    and apple_inject = apple_inject
    and scheduler = scheduler in
    scheduler
      [ (fun _ -> player_inject Restart); (fun (s, _a) -> apple_inject (Spawn s)) ]
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
