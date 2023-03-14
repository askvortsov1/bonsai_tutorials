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

.snake1_cell {
  background-color: green;
}

.snake2_cell {
  background-color: blue;
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
    | Snake1
    | Snake2
    | Apple
    | Empty

  let t_of_pos ~snake1 ~snake2 ~apple =
    let snake1_cells = Snake.set_of_t snake1 in
    let snake2_cells = Snake.set_of_t snake2 in
    let apple_cells = Apple.set_of_t apple in
    fun pos ->
      if Set.mem snake1_cells pos
      then Snake1
      else if Set.mem snake2_cells pos
      then Snake2
      else if Set.mem apple_cells pos
      then Apple
      else Empty
  ;;

  let classname_of_t = function
    | Snake1 -> Style.snake1_cell
    | Snake2 -> Style.snake2_cell
    | Apple -> Style.apple_cell
    | Empty -> Style.empty_cell
  ;;
end

let view_board rows cols snake1 snake2 apple =
  let cell_t_of_pos = Cell.t_of_pos ~snake1 ~snake2 ~apple in
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

let view_score_status ~label score status =
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
  Vdom.(
    Node.div
      [ Node.h3 [ Node.text label ]
      ; Node.p [ Node.textf "Score: %d" score ]
      ; view_status
      ])
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

let component ~rows ~cols player1 player2 apple =
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
  let%arr { Player.score = score1; snake = snake1; status = status1 } = player1
  and { Player.score = score2; snake = snake2; status = status2 } = player2
  and apple = apple in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; view_instructions
      ; Node.div
          [ view_score_status ~label:"Player 1" score1 status1
          ; view_score_status ~label:"Player 2" score2 status2
          ]
      ; view_board rows cols snake1 snake2 apple
      ])
;;
