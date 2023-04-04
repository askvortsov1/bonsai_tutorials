open! Core
open Bonsai

let component
  : type a. a Value.t -> ((a -> unit Ui_effect.t) list -> unit Ui_effect.t) Computation.t
  =
 fun input ->
  let module Action = struct
    type t = Run of (a -> unit Effect.t) list [@@deriving sexp]
  end
  in
  let apply_action ~inject ~schedule_event input _model (Action.Run effect_fns) =
    match effect_fns with
    | effect_fn :: dependents ->
      schedule_event (Effect.Many [ effect_fn input; inject (Action.Run dependents) ])
    | [] -> ()
  in
  let open Bonsai.Let_syntax in
  let%sub (), inject =
    Bonsai.state_machine1
      [%here]
      (module Unit)
      (module Action)
      ~default_model:()
      ~apply_action
      input
  in
  let%arr inject = inject in
  fun effects -> inject (Action.Run effects)
;;
