(* $MDX part-begin=action *)
open! Core
open! Bonsai

module Action = struct
  type t =
    | Restart
    | Move of Apple.t option
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

  module Data = struct
    type t =
      { score : int
      ; snake : Snake.t
      }
    [@@deriving sexp, equal, fields]
  end

  type t =
    | Not_started
    | Playing of Data.t
    | Game_over of (Data.t * End_reason.t)
  [@@deriving sexp, equal, variants]
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
  match action, model with
  (* $MDX part-end *)
  (* $MDX part-begin=apply_restart *)
  | Restart, _ ->
    let snake = Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color in
    Model.Playing { score = 0; snake }
  (* $MDX part-end *)
  (* $MDX part-begin=apply_move_playing_no_snake *)
  | Move None, Playing _ ->
    raise_s [%message "Invalid state: snake initialized but not apple."]
  (* $MDX part-end *)
  (* $MDX part-begin=apply_move_playing_snake *)
  | Move (Some apple), Playing data ->
    let ate_apple_score = 1 in
    let snake = Snake.move data.snake in
    if Snake.is_eatting_self snake
    then Game_over (data, Ate_self)
    else if Snake.is_out_of_bounds ~rows ~cols snake
    then Game_over (data, Out_of_bounds)
    else if Snake.is_eatting_apple snake apple
    then
      Playing
        { snake = Snake.grow_eventually ~by:1 snake
        ; score = data.score + ate_apple_score
        }
    else Playing { data with snake }
  (* $MDX part-end *)
  (* $MDX part-begin=apply_change_direction *)
  | Change_direction dir, Playing data ->
    Playing { data with snake = Snake.with_direction data.snake dir }
  (* $MDX part-end *)
  (* $MDX part-begin=apply_noop *)
  | Move _, Not_started
  | Move _, Game_over _
  | Change_direction _, Not_started
  | Change_direction _, Game_over _ -> model
;;

(* $MDX part-end *)

(* $MDX part-begin=computation *)
let computation ~rows ~cols ~color =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:Not_started
    ~apply_action:(apply_action ~rows ~cols ~color)
;;
(* $MDX part-end *)
