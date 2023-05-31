(* $MDX part-begin=model_action *)
open! Core
open! Bonsai_web

module Model = struct
  type t = Apple.t [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Place
    | Tick
  [@@deriving sexp]
end
(* $MDX part-end *)

(* $MDX part-begin=apply_action_spawn *)
let apply_action ~rows ~cols ~inject ~schedule_event snake model action =
  match action with
  | Action.Place ->
    let invalid_pos = Snake.list_of_t snake in
    Apple.spawn_random_exn ~rows ~cols ~invalid_pos
  (* $MDX part-end *)
  (* $MDX part-begin=apply_action_tick *)
  | Tick ->
    if Snake.is_eatting_apple snake model then schedule_event (inject Action.Place);
    model
;;

(* $MDX part-end *)

(* $MDX part-begin=computation *)
let computation ~rows ~cols ~default_apple snake =
  Bonsai.state_machine1
    [%here]
    (module Model)
    (module Action)
    ~default_model:default_apple
    ~apply_action:(apply_action ~rows ~cols)
    snake
;;
(* $MDX part-end *)
