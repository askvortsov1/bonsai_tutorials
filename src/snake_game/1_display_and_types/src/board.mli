open! Core
open! Bonsai_web

val component
  :  rows:int
  -> cols:int
  -> Snake.t Value.t
  -> int Value.t
  -> Player_status.t Value.t
  -> Apple.t Value.t
  -> Vdom.Node.t Computation.t
