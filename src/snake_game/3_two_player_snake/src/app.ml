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
let num_apples = 5

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
    Snake.spawn_random_exn ~rows ~cols ~invalid_pos ~color:(`Name "blue")
  in
  let open Bonsai.Let_syntax in
  let%sub player1, player1_inject =
    Player_state.computation ~rows ~cols ~default_snake:default_snake1
  in
  let%sub player2, player2_inject =
    Player_state.computation ~rows ~cols ~default_snake:default_snake2
  in
  let%sub apples, apple_injects =
    List.init num_apples ~f:(fun _ -> ())
    |> List.fold ~init:([], []) ~f:(fun (apple_acc, invalid_pos) _ ->
         let default_apple = Apple.spawn_random_exn ~rows ~cols ~invalid_pos in
         let apple_sm = Apple_state.computation ~rows ~cols ~default_apple in
         apple_sm :: apple_acc, Apple.list_of_t default_apple @ invalid_pos)
    |> Tuple2.get1
    |> Computation.all
    |> Computation.map ~f:(fun x -> List.map ~f:Tuple2.get1 x, List.map ~f:Tuple2.get2 x)
  in
  (* $MDX part-end *)
  (* $MDX part-begin=scheduler *)
  let%sub game_elements =
    let%arr player1 = player1
    and player2 = player2
    and apples = apples in
    { Game_elements.snakes = [ player1.snake; player2.snake ]; apples }
  in
  let%sub scheduler = Chain_incr_effects.component game_elements in
  (* $MDX part-end *)
  (* $MDX part-begin=tick *)
  let%sub () =
    let%sub clock_effect =
      let%arr player1_inject = player1_inject
      and player2_inject = player2_inject
      and apple_injects = apple_injects
      and scheduler = scheduler in
      scheduler
        ([ (fun g -> player1_inject (Move g)); (fun g -> player2_inject (Move g)) ]
         @ List.map apple_injects ~f:(fun inject game_elements ->
             inject (Tick game_elements)))
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 0.25) clock_effect
  in
  (* $MDX part-end *)
  (* $MDX part-begin=reset *)
  let%sub reset_action =
    let%arr player1_inject = player1_inject
    and player2_inject = player2_inject
    and apple_injects = apple_injects
    and scheduler = scheduler in
    scheduler
      ([ (fun g -> player1_inject (Restart g)); (fun g -> player2_inject (Restart g)) ]
       @ List.map apple_injects ~f:(fun inject game_elements ->
           inject (Tick game_elements)))
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
