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

.snake_cell {
  background-color: green;
}

.apple_cell {
  background-color: red;
}

.empty_cell {
  background-color: white;
}
|}]

module Cell = struct
  type t =
    | Snake
    | Apple
    | Empty

  let t_of_pos ~snake ~apple =
    let snake_cells = Snake.set_of_t snake in
    let apple_cells = Apple.set_of_t apple in
    fun pos ->
      if Set.mem snake_cells pos
      then Snake
      else if Set.mem apple_cells pos
      then Apple
      else Empty
  ;;

  let classname_of_t = function
    | Snake -> Style.snake_cell
    | Apple -> Style.apple_cell
    | Empty -> Style.empty_cell
  ;;
end

let view_board rows cols snake apple =
  let cell_t_of_pos = Cell.t_of_pos ~snake ~apple in
  let cells =
    List.init rows ~f:(fun row ->
      List.init cols ~f:(fun col ->
        let pos = { Position.row; col } in
        let class_ = Cell.classname_of_t (cell_t_of_pos pos) in
        Vdom.(Node.div ~attr:(Attr.classes [ Style.grid_cell; class_ ]) [])))
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
  let%arr { Player.score; snake; status } = player
  and apple = apple in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; view_instructions
      ; view_score_status score status
      ; view_board rows cols snake apple
      ])
;;
