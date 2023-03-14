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


let background_str_of_pos ~snakes ~apples =
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



let view_board rows cols snake apple =
  let background_fn =
    background_str_of_pos ~snakes:[ snake ] ~apples:[ apple ]
  in
  let cells =
    List.init rows ~f:(fun row ->
      List.init cols ~f:(fun col ->
        let pos = { Position.row; col } in
        let background_str = background_fn pos in
        let css = Css_gen.create ~field:"background" ~value:background_str in
        Vdom.(
          Node.div
            ~attr:(Attr.many [ Attr.style css; Attr.classes [ Style.grid_cell ] ])
            [])))
    |> List.concat
  in
  Vdom.(Node.div ~attr:(Attr.class_ Style.grid) cells)
;;

let view_instructions = Vdom.(Node.p [ Node.text "Click anywhere to start or reset." ])

let view_score_status score status =
  let view_status =
    match status with
    | Player_status.Playing -> Vdom.Node.none
    | Inactive reason ->
      let message_text =
        match reason with
        | Not_started -> "Click to start!"
        | Out_of_bounds -> "Game over... Out of bounds!"
        | Ate_self -> "Game over... Ate self!"
      in
      Vdom.(Node.p [ Node.text message_text ])
  in
  Vdom.(Node.div [ Node.p [ Node.textf "Score: %d" score ]; view_status ])
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

let component ~rows ~cols snake score player_status apple =
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
  let%arr score = score
  and snake = snake
  and status = player_status
  and apple = apple in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; view_instructions
      ; view_score_status score status
      ; view_board rows cols snake apple
      ])
;;
