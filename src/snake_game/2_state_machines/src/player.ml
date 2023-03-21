open! Core
open! Bonsai

type t =
  { score : int
  ; snake : Snake.t
  ; status : Player_status.t
  }
[@@deriving sexp, fields]

module Model = struct
  type t =
    { score : int
    ; snake : Snake.t
    ; direction : Direction.t
    ; status : Player_status.t
    }
  [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Restart
    | Move of (Apple.t * (Apple.Action.t -> unit Effect.t))
    | Change_direction of Direction.t
  [@@deriving sexp]
end

let ate_apple_score = 1

let default_model ~rows ~cols ~color =
  (* Spawn in left half, going right*)
  let snake = Snake.spawn_random ~rows ~cols:(cols / 2) ~color in
  { Model.score = 0; snake; direction = Right; status = Inactive Not_started }
;;

let apply_action
  ~rows
  ~cols
  ~color
  ~inject:_
  ~schedule_event
  (model : Model.t)
  (action : Action.t)
  =
  match action, model.status with
  | Restart, _ ->
    let default = default_model ~rows ~cols ~color in
    { default with status = Playing }
  | Move (apple, apple_inject), Playing ->
    let snake = Snake.move model.snake model.direction in
    let (status : Player_status.t) =
      if Snake.is_eatting_self snake
      then Inactive Ate_self
      else if Snake.is_out_of_bounds ~rows ~cols snake
      then Inactive Out_of_bounds
      else Playing
    in
    if Apple.is_eatten apple snake
    then (
      let invalid_pos = Snake.list_of_t snake @ Apple.list_of_t apple in
      let () = schedule_event (apple_inject (Apple.Action.Eatten invalid_pos)) in
      { Model.direction = model.direction
      ; snake = Snake.grow_eventually ~by:1 snake
      ; score = model.score + ate_apple_score
      ; status
      })
    else { Model.direction = model.direction; snake; score = model.score; status }
  | Change_direction dir, Playing -> { model with direction = dir }
  | Move _, Inactive _ | Change_direction _, Inactive _ -> model
;;

let computation ~rows ~cols ~color =
  let open Bonsai.Let_syntax in
  let%sub model, inject =
    Bonsai.state_machine0
      [%here]
      (module Model)
      (module Action)
      ~default_model:(default_model ~rows ~cols ~color)
      ~apply_action:(apply_action ~rows ~cols ~color)
  in
  let%arr model = model
  and inject = inject in
  { snake = model.snake; score = model.score; status = model.status }, inject
;;
