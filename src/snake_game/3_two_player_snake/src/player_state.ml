open! Core
open! Bonsai

(* $MDX part-begin=action *)
module Action = struct
  type t =
    | Restart of Game_elements.t
    | Move of Game_elements.t
    | Change_direction of Direction.t
  [@@deriving sexp]
end
(* $MDX part-end *)

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
  (* $MDX part-begin=apply_restart *)
  | Restart game_elements, _ ->
    let invalid_pos = Game_elements.occupied_pos game_elements in
    let snake = Snake.spawn_random_exn ~rows ~cols ~color ~invalid_pos in
    { Model.score = 0; snake; status = Playing }
    (* $MDX part-end *)
    (* $MDX part-begin=apply_move *)
  | Move game_elements, Playing ->
    let ate_apple_score = 1 in
    let snake = Snake.move model.snake in
    if Snake.is_eatting_self snake
    then { model with status = Game_over Ate_self }
    else if Snake.is_out_of_bounds ~rows ~cols snake
    then { model with status = Game_over Out_of_bounds }
    else (
      let ate_apple =
        game_elements.apples
        |> List.filter ~f:(Snake.is_eatting_apple snake)
        |> List.length
        > 0
        |> Bool.to_int
      in
      { model with
        snake = Snake.grow_eventually ~by:ate_apple snake
      ; score = model.score + (ate_apple * ate_apple_score)
      })
    (* $MDX part-end *)
  | Change_direction dir, Playing ->
    { model with snake = Snake.with_direction model.snake dir }
  | Move _, Not_started
  | Move _, Game_over _
  | Change_direction _, Not_started
  | Change_direction _, Game_over _ -> model
;;

let computation ~rows ~cols ~default_snake =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:{ Model.snake = default_snake; status = Not_started; score = 0 }
    ~apply_action:(apply_action ~rows ~cols ~color:(Snake.color default_snake))
;;
