(* $MDX part-begin=style *)
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

(* $MDX part-end *)

(* $MDX part-begin=style_drivers *)
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

(* $MDX part-end *)

(* $MDX part-begin=board_view *)
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

(* $MDX part-end *)

(* $MDX part-begin=component *)
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

let component ~rows ~cols snake apple =
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
  let%arr snake = snake
  and apple = apple in
  let cell_style_driver = merge_cell_style_drivers ~snakes:[ snake ] ~apples:[ apple ] in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; Node.p [ Node.text "Click anywhere to reset." ]
      ; view_game_grid rows cols cell_style_driver
      ])
;;
(* $MDX part-end *)
