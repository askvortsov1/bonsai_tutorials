open! Core
open Bonsai

(** [component dep effect_fns] allows you to sequentially schedule effects that depend
    on an incrementally-computed ['a Value.t], allowing the dependency to change between
    the execution of each effect.

    This is particularly useful for modeling a set of interacting state machines.
    The outputs of each computation can be collected into a single [Value.t],
    which is then provided to each state machine through an injected action.
    This util allows model recomputations made in the `i`th state machine to be
    immediately visible to the [apply_action] logic of the `i+1`th state machine.
    
    In contrast, just resolving a value with [let%arr] and scheduling multiple dependent
    effects with `[Effect.Many]` will provide all state machines
    with the state of the world before *any* of them recalculated state.
    
    See [this issue](https://github.com/janestreet/bonsai/issues/33) for more information. *)
val component
  :  'a Value.t
  -> (('a -> unit Ui_effect.t) list -> unit Ui_effect.t) Computation.t
