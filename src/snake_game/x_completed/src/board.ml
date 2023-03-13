open! Core
open! Bonsai_web

module Style =
[%css.raw
{|
.grid {
  display: grid;
  grid-template-rows: repeat(var(--grid-rows), 1fr);
  grid-template-columns: repeat(var(--grid-cols), 1fr);
}

.grid_cell {
  border: 2px solid gray;
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
        Vdom.(
          Node.div
            ~attr:(Attr.classes [ Style.grid_cell; class_ ])
            [ Node.textf "%d,%d" row col ])))
    |> List.concat
  in
  Vdom.(Node.div ~attr:(Attr.class_ Style.grid) cells)
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
  Firebug.console##log res
;;

let component ~reset_action ~rows ~cols player apple =
  let open Bonsai.Let_syntax in
  let on_activate =
    Ui_effect.of_sync_fun
      (fun () ->
        set_style_property "--grid-rows" (Int.to_string rows);
        set_style_property "--grid-cols" (Int.to_string cols))
      ()
    |> Value.return
  in
  let%sub () = Bonsai.Edge.lifecycle ~on_activate () in
  let%arr { Player.score; snake } = player
  and apple = apple
  and reset_action = reset_action in
  Vdom.(
    Node.div
      [ Node.button
          ~attr:(Attr.on_click (fun _ -> reset_action))
          [ Node.text "Reset game" ]
      ; Node.p [ Node.textf "Score: %d" score ]
      ; view_board rows cols snake apple
      ])
;;
