open! Core
open Bonsai_web
open Bonsai.Let_syntax

(* $MDX part-begin=index_html *)
module Model = struct
  type t = unit Int.Map.t [@@deriving sexp, equal]
end

let add_counter_component =
  let%sub add_counter_state =
    Bonsai.state_machine0
      (module Model)
      (module Unit)
      ~default_model:Int.Map.empty
      ~apply_action:(fun ~inject:_ ~schedule_event:_ model () ->
        let key = Map.length model in
        Map.add_exn model ~key ~data:())
  in
  let%arr state, inject = add_counter_state in
  let view =
    Vdom.Node.button
      ~attr:(Vdom.Attr.on_click (fun _ -> inject ()))
      [ Vdom.Node.text "Add Another Counter" ]
  in
  state, view
;;
(* $MDX part-end *)