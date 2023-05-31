open! Core
open! Bonsai_web

val component
  :  rows:int
  -> cols:int
  -> Player_state.Model.t Value.t
  -> Apple_state.Model.t Value.t
  -> Vdom.Node.t Computation.t
