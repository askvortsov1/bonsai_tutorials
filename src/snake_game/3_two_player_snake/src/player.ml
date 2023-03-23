open! Core
open! Bonsai

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
      ; direction : Direction.t
      }
    [@@deriving sexp, equal, fields]
  end

  type t =
    | Not_started
    | Playing of Data.t
    | Game_over of (Data.t * End_reason.t)
  [@@deriving sexp, equal, variants]
end

include Model

let snake_pos = function
  | Playing data | Game_over (data, _) -> Snake.list_of_t data.snake
  | Not_started -> []
;;

let snakes ps =
  List.fold ps ~init:[] ~f:(fun snakes -> function
    | Playing data | Game_over (data, _) -> data.snake :: snakes
    | Not_started -> snakes)
;;

module Action = struct
  type t =
    | Restart
    | Move of Game_elements.t
    | Change_direction of Direction.t
  [@@deriving sexp]
end

let ate_apple_score = 1

let apply_action
  ~rows
  ~cols
  ~color
  ~inject:_
  ~schedule_event
  (model : Model.t)
  (action : Action.t)
  =
  match action, model with
  | Restart, _ ->
    let snake = Snake.spawn_random ~rows ~cols:(cols / 2) ~color in
    Playing { score = 0; snake; direction = Right }
  | Move game_elements, Playing data ->
    let snake = Snake.move data.snake data.direction in
    if Snake.is_eatting_self snake
    then Game_over (data, Ate_self)
    else if Snake.is_out_of_bounds ~rows ~cols snake
    then Game_over (data, Out_of_bounds)
    else (
      let num_apples_eatten =
        let apples_eatten =
          game_elements.apples
          |> List.filter ~f:(fun (apple, _) -> Apple.is_eatten apple snake)
        in
        let invalid_pos = Game_elements.occupied_pos game_elements in
        List.iter apples_eatten ~f:(fun (_, apple_inject) ->
          schedule_event (apple_inject (Eatten invalid_pos)));
        List.length apples_eatten
      in
      Playing
        { direction = data.direction
        ; snake = Snake.grow_eventually ~by:num_apples_eatten snake
        ; score = data.score + (num_apples_eatten * ate_apple_score)
        })
  | Change_direction dir, Playing data -> Playing { data with direction = dir }
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
