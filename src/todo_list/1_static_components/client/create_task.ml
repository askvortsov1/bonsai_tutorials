(* $MDX part-begin=opens *)
open! Core
open! Bonsai_web
(* $MDX part-end *)

(* $MDX part-begin=style *)
module Style =
[%css.raw
{|
.create_task_button {
  font-size: 16px;
  padding: 8px 16px;
  border: 2px solid #CCCCCC;
  background-color: #CCCCCC;
}
.create_task_button:hover {
  border-color: #7a7a7a;
}
|}]
(* $MDX part-end *)

(* $MDX part-begin=button_view *)
let alert s = Js_of_ocaml.Dom_html.window##alert (Js_of_ocaml.Js.string s)

let view_create_tasks_button =
  Vdom.(
    Node.button
      ~attr:
        (Attr.many
           [ Attr.class_ Style.create_task_button
           ; Attr.on_click (fun _e ->
               alert "Not yet implemented.";
               Ui_effect.Ignore)
           ])
      [ Node.text "Create Task" ])
;;

(* $MDX part-end *)

(* $MDX part-begin=component_no_button *)
let view_create_tasks =
  Vdom.(Node.div [ Node.h2 [ Node.text "Create Tasks" ]; view_create_tasks_button ])
;;

let component = Computation.return view_create_tasks
(* $MDX part-end *)
