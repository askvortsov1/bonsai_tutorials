open! Core
open! Bonsai_web
open Common

module Style =
[%css.raw
{|
.task_tile {
  box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
  transition: 0.3s;
  padding: 2px 16px;
  max-width: 500px;
  margin: 20px 0;
}

.task_tile:hover {
  box-shadow: 0 8px 16px 0 rgba(0,0,0,0.2);
}
.task_tile .task_meta {
  border-top: 1px solid;
  border-bottom: 1px solid;
}
|}]

(* In a real product, we'd use a more sophisticated Markdown -> HTML renderer. *)
let format_description text =
  let inner =
    text |> String.split_lines
    |> List.map ~f:(fun l -> Vdom.Node.p [ Vdom.Node.text l ])
  in
  Vdom.Node.div inner

let view_task { Task.completion_status; due_date; title; description } =
  let view_completion =
    let open Vdom in
    match completion_status with
    | Todo -> Node.none
    | Completed date ->
        Node.p [ Node.textf "Completed: %s" (Date.to_string date) ]
  in
  Vdom.(
    Node.div
      ~attr:(Attr.class_ Style.task_tile)
      [
        Node.h3 [ Node.text title ];
        Node.div
          ~attr:(Attr.class_ Style.task_meta)
          [
            Node.p [ Node.textf "Due: %s" (Date.to_string due_date) ];
            view_completion;
          ];
        format_description description;
      ])

let view_tasks items =
  Vdom.(
    Node.div
      [
        Node.h2 [ Node.text "Your Tasks" ];
        Node.div (List.map items ~f:view_task);
      ])

let component ~tasks =
  let open Bonsai.Let_syntax in
  let%arr tasks = tasks in
  view_tasks tasks
