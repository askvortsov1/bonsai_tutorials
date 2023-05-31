(* $MDX part-begin=sig *)
open! Core
open Bonsai

let scheduler
  : type input.
    input Value.t -> ((input -> unit Ui_effect.t) list -> unit Ui_effect.t) Computation.t
  =
 (* $MDX part-end *)
 fun input ->
  (* $MDX part-begin=action *)
  let module Action = struct
    type t = Run of (input -> unit Effect.t) list [@@deriving sexp]
  end
  in
  (* $MDX part-end *)
  (* $MDX part-begin=apply_action *)
  let apply_action ~inject ~schedule_event input _model (Action.Run effect_fns) =
    match input, effect_fns with
    | Bonsai.Computation_status.Active input_val, effect_fn :: dependents ->
      schedule_event (Effect.Many [ effect_fn input_val; inject (Action.Run dependents) ])
    | _, [] | Inactive, _ -> ()
  in
  (* $MDX part-end *)
  (* $MDX part-begin=sm_def *)
  let open Bonsai.Let_syntax in
  let%sub (), inject =
    Bonsai.state_machine1
      (module Unit)
      (module Action)
      ~default_model:()
      ~apply_action
      input
  in
  (* $MDX part-end *)
  (* $MDX part-begin=inject *)
  let%arr inject = inject in
  fun effects -> inject (Action.Run effects)
;;
(* $MDX part-end *)
