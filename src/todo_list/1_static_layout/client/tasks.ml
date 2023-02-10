open! Core
open! Bonsai
open! Bonsai_web
open Common
open Bonsai.Let_syntax

module Style =
[%css.raw
{|
.task_tile {
  box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
  transition: 0.3s;
  padding: 2px 16px;
  max-width: 300px;
  margin: 20px;
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

let view_task { Task.completed_on; due_date; title; description } =
  Vdom.(
    Node.div
      ~attr:(Attr.class_ Style.task_tile)
      [
        Node.h3 [ Node.text title ];
        Node.div
          ~attr:(Attr.class_ Style.task_meta)
          [
            Node.p [ Node.textf "Due: %s" (Date.to_string due_date) ];
            (match completed_on with
            | None -> Node.none
            | Some date ->
                Node.p [ Node.textf "Completed: %s" (Date.to_string date) ]);
          ];
        format_description description;
      ])

let view_tasks items =
  Vdom.(
    Node.div ~attr:(Attr.id "tasks")
      [
        Node.h1 [ Node.text "Your Tasks" ];
        Node.div (List.map items ~f:view_task);
      ])

let component ~tasks =
  let%arr tasks = tasks in
  view_tasks tasks
