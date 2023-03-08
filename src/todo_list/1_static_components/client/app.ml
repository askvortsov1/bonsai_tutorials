open! Core
open! Bonsai_web

module Style =
[%css.raw
{|
.app {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.title {
 text-align: center
}

.container {
  display: flex;
  gap: 50px;
}
|}]

let component ~tasks =
  let open Bonsai.Let_syntax in
  let%sub task_list = Tasks.component ~tasks in
  let%sub create_task = Create_task.component in
  let%arr task_list = task_list and create_task = create_task in
  Vdom.(
    Node.div
      ~attr:(Attr.many [ Attr.class_ Style.app; Attr.id "app" ])
      [
        Node.h1 ~attr:(Attr.class_ Style.title)
          [ Node.text "Bonsai To-do List" ];
        Node.div ~attr:(Attr.class_ Style.container) [ task_list; create_task ];
      ])
