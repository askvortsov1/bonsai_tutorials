open! Core
open! Bonsai_web

val component
  :  reset_action:unit Effect.t Value.t
  -> rows:int
  -> cols:int
  -> Player.t Value.t
  -> Apple.t Value.t
  -> Vdom.Node.t Computation.t
