open! Core
open! Import

(* $MDX part-begin=loose_state *)
let component ~label () =
  let%sub count, set_count = Bonsai.state (module Int) (module Action) ~default_model:0 in
  let%arr count = count
  and set_count = set_count
  and label = label in
  let view =
    Vdom.Node.(
      div
        [ span [ textf "%s: " label ]
        ; button ~attrs:[(Vdom.Attr.on_click (fun _ -> set_count (count - 1)))] [ text "-" ]
        ; span [ textf "%d" count ]
        ; button ~attrs:[(Vdom.Attr.on_click (fun _ -> set_count (count + 1)))] [ text "+" ]
        ])
  in
  view, state
;;
(* $MDX part-end *)
