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

let view_end_message status =
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
;;

let grid_vars_styles ~rows ~cols =
  let open Css_gen in
  Css_gen.create ~field:"--grid-rows" ~value:(Int.to_string rows)
  @> Css_gen.create ~field:"--grid-cols" ~value:(Int.to_string cols)
  @> Css_gen.create ~field:"color" ~value:"green"
;;

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
  Vdom.(
    Node.div
      ~attr:
        (Attr.many [ Attr.class_ Style.grid; Attr.style (grid_vars_styles ~rows ~cols) ])
      cells)
;;

let component ~rows ~cols player apple =
  let open Bonsai.Let_syntax in
  let%arr { Player.score; snake; status } = player
  and apple = apple in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; Node.p [ Node.text "Click anywhere to restart." ]
      ; Node.p [ Node.textf "Score: %d" score ]
      ; view_end_message status
      ; view_board rows cols snake apple
      ])
;;
