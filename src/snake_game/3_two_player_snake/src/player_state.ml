open! Core
open! Bonsai

module Action = struct
  type t =
    | Restart of Game_elements.t
    | Move of Game_elements.t
    | Change_direction of Direction.t
  [@@deriving sexp]
end

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

  let snakes states =
    List.fold states ~init:[] ~f:(fun snakes -> function
      | Playing data | Game_over (data, _) -> data.snake :: snakes
      | Not_started -> snakes)
  ;;
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
  match action, model with
  | Restart game_elements, _ ->
    let invalid_pos = Game_elements.occupied_pos game_elements in
    let snake = Snake.spawn_random_exn ~rows ~cols ~color ~invalid_pos in
    Model.Playing { score = 0; snake }
  | Move game_elements, Playing data ->
    let ate_apple_score = 1 in
    let snake = Snake.move data.snake in
    if Snake.is_eatting_self snake
    then Game_over (data, Ate_self)
    else if Snake.is_out_of_bounds ~rows ~cols snake
    then Game_over (data, Out_of_bounds)
    else (
      let num_apples_eatten =
        game_elements.apples
        |> List.filter ~f:(Snake.is_eatting_apple snake)
        |> List.length
      in
      Playing
        { snake = Snake.grow_eventually ~by:num_apples_eatten snake
        ; score = data.score + (num_apples_eatten * ate_apple_score)
        })
  | Change_direction dir, Playing data ->
    Playing { data with snake = Snake.with_direction data.snake dir }
  | Move _, Not_started
  | Move _, Game_over _
  | Change_direction _, Not_started
  | Change_direction _, Game_over _ -> model
;;

let computation ~rows ~cols ~color =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:Not_started
    ~apply_action:(apply_action ~rows ~cols ~color)
;;
