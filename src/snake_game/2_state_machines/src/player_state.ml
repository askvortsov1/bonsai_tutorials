(* $MDX part-begin=action *)
open! Core
open! Bonsai

module Action = struct
  type t =
    | Restart
    | Move of Apple.t
    | Change_direction of Direction.t
  [@@deriving sexp]
end
(* $MDX part-end *)

(* $MDX part-begin=model *)
module Model = struct
  module End_reason = struct
    type t =
      | Ate_self
      | Out_of_bounds
    [@@deriving sexp, equal]
  end

  module Status = struct
    type t =
      | Not_started
      | Playing
      | Game_over of End_reason.t
    [@@deriving sexp, equal, variants]
  end

  type t =
    { score : int
    ; snake : Snake.t
    ; status : Status.t
    }
  [@@deriving sexp, equal, fields]
end
(* $MDX part-end *)

(* $MDX part-begin=apply_match *)
let apply_action
  ~rows
  ~cols
  ~color
  ~inject:_
  ~schedule_event:_
  (model : Model.t)
  (action : Action.t)
  =
  match action, model.status with
  (* $MDX part-end *)
  (* $MDX part-begin=apply_restart *)
  | Restart, _ ->
    let snake = Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color in
    { Model.score = 0; snake; status = Playing }
  (* $MDX part-end *)
  (* $MDX part-begin=apply_move_playing_snake *)
  | Move apple, Playing ->
    let ate_apple_score = 1 in
    let snake = Snake.move model.snake in
    if Snake.is_eatting_self snake
    then { model with status = Game_over Ate_self }
    else if Snake.is_out_of_bounds ~rows ~cols snake
    then { model with status = Game_over Out_of_bounds }
    else if Snake.is_eatting_apple snake apple
    then
      { model with
        snake = Snake.grow_eventually ~by:1 snake
      ; score = model.score + ate_apple_score
      }
    else { model with snake }
  (* $MDX part-end *)
  (* $MDX part-begin=apply_change_direction *)
  | Change_direction dir, Playing ->
    { model with snake = Snake.with_direction model.snake dir }
  (* $MDX part-end *)
  (* $MDX part-begin=apply_noop *)
  | Move _, Not_started
  | Move _, Game_over _
  | Change_direction _, Not_started
  | Change_direction _, Game_over _ -> model
;;

(* $MDX part-end *)

(* $MDX part-begin=computation *)
let computation ~rows ~cols ~default_snake =
  Bonsai.state_machine0
    (module Model)
    (module Action)
    ~default_model:{ Model.snake = default_snake; status = Not_started; score = 0 }
    ~apply_action:(apply_action ~rows ~cols ~color:(Snake.color default_snake))
;;
(* $MDX part-end *)
