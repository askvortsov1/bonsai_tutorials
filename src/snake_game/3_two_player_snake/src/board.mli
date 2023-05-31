open! Core
open! Bonsai_web

val component
  :  rows:int
  -> cols:int
  -> Player_state.Model.t Value.t
  -> Player_state.Model.t Value.t
  -> Game_elements.t Value.t
  -> Vdom.Node.t Computation.t
