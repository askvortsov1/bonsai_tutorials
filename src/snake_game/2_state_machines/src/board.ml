open! Core
open! Bonsai_web

module Style =
[%css.raw
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
        Vdom.(Node.div ~attr:(Attr.style style) [])))
    |> List.concat
  in
  Vdom.(Node.div ~attr:(Attr.class_ Style.grid) cells)
;;

(* $MDX part-begin=score_status *)
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

(* $MDX part-end *)

let set_style_property key value =
  let open Js_of_ocaml in
  let priority = Js.undefined in
  let res =
    Dom_html.document##.documentElement##.style##setProperty
      (Js.string key)
      (Js.string value)
      priority
  in
  ignore res
;;

(* $MDX part-begin=computation_changes *)
let component ~rows ~cols (player : Player_state.Model.t Value.t) apple =
  let open Bonsai.Let_syntax in
  (* TODO: use `Attr.css_var` instead. *)
  let on_activate =
    Ui_effect.of_sync_fun
      (fun () ->
        set_style_property "--grid-rows" (Int.to_string rows);
        set_style_property "--grid-cols" (Int.to_string cols))
      ()
    |> Value.return
  in
  let%sub () = Bonsai.Edge.lifecycle ~on_activate () in
  let%arr player = player
  and apple = apple in
  let cell_style_driver =
    merge_cell_style_drivers ~snakes:[ player.snake ] ~apples:[ apple ]
  in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; Node.p [ Node.text "Click anywhere to reset." ]
      ; view_score_status ~label:"Results" player
      ; view_game_grid rows cols cell_style_driver
      ])
;;
(* $MDX part-end *)
