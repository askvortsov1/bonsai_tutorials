open! Core
open Bonsai_web

(* $MDX part-begin=hello_world *)
let component = Computation.return (Vdom.Node.text "Hello World")
(* $MDX part-end *)