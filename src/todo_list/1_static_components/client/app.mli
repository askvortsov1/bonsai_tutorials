open! Core
open! Bonsai_web
open Common

val component : tasks:Task.t list Value.t -> Vdom.Node.t Computation.t
