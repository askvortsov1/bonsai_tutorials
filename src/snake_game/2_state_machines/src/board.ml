open! Core
open! Bonsai_web

module Style =
[%css.raw
{|
.grid {
  width: 600px;
  display: grid;
  grid-template-rows: repeat(var(--grid-rows), 1fr);
  grid-template-columns: repeat(var(--grid-cols), 1fr);
}

.grid_cell {
  border: 2px solid gray;
  /* Hack to make the cells square */
  padding-bottom: 100%;
  height: 0;
}
|}]

let view_board rows cols cell_bg_driver =
  let cells =
    List.init rows ~f:(fun row ->
      List.init cols ~f:(fun col ->
        let pos = { Position.row; col } in
        let background_str = cell_bg_driver pos in
        let css = Css_gen.create ~field:"background" ~value:background_str in
        Vdom.(
          Node.div
            ~attr:(Attr.many [ Attr.style css; Attr.classes [ Style.grid_cell ] ])
            [])))
    |> List.concat
  in
  Vdom.(Node.div ~attr:(Attr.class_ Style.grid) cells)
;;

let view_instructions = Vdom.(Node.p [ Node.text "Click anywhere to reset." ])

let view_score_status ~label player =
  let content =
    let open Vdom.Node in
    let score_text score = p [ textf "Score: %d" score ] in
    match player with
    | Player_state.Model.Not_started -> [ p [ text "Click to start!" ] ]
    | Playing data -> [ score_text data.score ]
    | Game_over (data, Out_of_bounds) ->
      [ p [ text "Game over... Out of bounds!" ]; score_text data.score ]
    | Game_over (data, Ate_self) ->
      [ p [ text "Game over... Ate self!" ]; score_text data.score ]
  in
  Vdom.(Node.div (Node.h3 [ Node.text label ] :: content))
;;

let merge_cell_bg_drivers ~snakes ~apples =
  let drivers =
    List.join
      [ List.map snakes ~f:Snake.cell_background
      ; List.map apples ~f:Apple.cell_background
      ]
  in
  fun pos ->
    match List.find_map drivers ~f:(fun driver -> driver pos) with
    | Some x -> x
    | None -> "white"
;;

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

let component ~rows ~cols player apple =
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
  let cell_bg_driver =
    match player, apple with
    | Player_state.Model.Not_started, _ | _, Apple_state.Model.Not_started ->
      merge_cell_bg_drivers ~snakes:[] ~apples:[]
    | Playing data, Playing apple | Game_over (data, _), Playing apple ->
      merge_cell_bg_drivers ~snakes:[ data.snake ] ~apples:[ apple ]
  in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; view_instructions
      ; view_score_status ~label:"Results" player
      ; view_board rows cols cell_bg_driver
      ])
;;
