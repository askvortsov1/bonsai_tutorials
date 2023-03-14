open! Core
open! Bonsai_web

val component
  :  rows:int
  -> cols:int
  -> Player.t Value.t
  -> Player.t Value.t
  -> Apple.t Value.t
  -> Vdom.Node.t Computation.t
