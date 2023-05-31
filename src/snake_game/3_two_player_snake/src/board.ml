open! Core
open! Bonsai_web

module Style =
[%css
stylesheet
  {|
.grid {
  width: 600px;
  height: 600px;
  display: grid;
  grid-template-rows: repeat(var(--grid-rows), 1fr);
  grid-template-columns: repeat(var(--grid-cols), 1fr);
  border: 5px solid gray;
}
|}]

let empty_cell_style =
  Css_gen.(
    background_color (`Name "white")
    @> border ~width:(`Px 1) ~color:(`Name "gray") ~style:`Solid ())
;;

let merge_cell_style_drivers ~snakes ~apples =
  let drivers =
    List.join [ List.map snakes ~f:Snake.cell_style; List.map apples ~f:Apple.cell_style ]
  in
  fun pos ->
    match List.find_map drivers ~f:(fun driver -> driver pos) with
    | Some x -> x
    | None -> empty_cell_style
;;

let view_game_grid rows cols cell_style_driver =
  let cells =
    List.init rows ~f:(fun row ->
      List.init cols ~f:(fun col ->
        let pos = { Position.row; col } in
        let style = cell_style_driver pos in
        Vdom.(Node.div ~attrs:[ Attr.style style ] [])))
    |> List.concat
  in
  Vdom.(Node.div ~attrs:[ Style.grid ] cells)
;;

let view_score_status ~label (player : Player_state.Model.t) =
  let content =
    let open Vdom.Node in
    let score_text score = p [ textf "Score: %d" score ] in
    match player.status with
    | Player_state.Model.Status.Not_started -> [ p [ text "Click to start!" ] ]
    | Playing -> [ score_text player.score ]
    | Game_over Out_of_bounds ->
      [ p [ text "Game over... Out of bounds!" ]; score_text player.score ]
    | Game_over Ate_self ->
      [ p [ text "Game over... Ate self!" ]; score_text player.score ]
  in
  Vdom.(Node.div (Node.h3 [ Node.text label ] :: content))
;;

(* $MDX part-begin=component *)
let component ~rows ~cols player1 player2 (game_elements : Game_elements.t Value.t) =
  let open Bonsai.Let_syntax in
  let%arr player1 = player1
  and player2 = player2
  and game_elements = game_elements in
  let cell_style_driver =
    merge_cell_style_drivers ~snakes:game_elements.snakes ~apples:game_elements.apples
  in
  Vdom.(
    Node.div
      ~attrs:
        [ Style.Variables.set
            ~grid_cols:(Int.to_string rows)
            ~grid_rows:(Int.to_string cols)
            ()
        ]
      [ Node.h1 [ Node.text "Snake Game" ]
      ; Node.p [ Node.text "Click anywhere to reset." ]
      ; Node.div
          [ view_score_status ~label:"Player 1" player1
          ; view_score_status ~label:"Player 2" player2
          ]
      ; view_game_grid rows cols cell_style_driver
      ])
;;
(* $MDX part-end *)
