open! Core
open! Bonsai

type t =
  { score : int
  ; snake : Snake.t
  }
[@@deriving sexp, fields]

module Model = struct
  type t =
    { score : int
    ; snake : Snake.t
    ; direction : Direction.t
    ; left_to_grow : int
    ; status : Player_status.t
    }
  [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Restart
    | Move of (Apple.t * (Apple.Action.t -> unit Effect.t))
  [@@deriving sexp]
end

let ate_apple_score = 1

let default_model ~rows ~cols =
  (* Spawn in left half, going right*)
  let snake = Snake.spawn_random ~rows ~cols:(cols / 2) in
  { Model.score = 0
  ; left_to_grow = 0
  ; snake
  ; direction = Right
  ; status = Inactive Not_started
  }
;;

let apply_action
  ~rows
  ~cols
  ~inject:_
  ~schedule_event
  (model : Model.t)
  (action : Action.t)
  =
  match action, model.status with
  | Restart, _ ->
    let default = default_model ~rows ~cols in
    { default with status = Playing }
  | Move (apple, apple_inject), Playing ->
    let left_to_grow = Int.max 0 (model.left_to_grow - 1) in
    let snake = Snake.move model.snake model.direction ~grow:(model.left_to_grow > 0) in
    let ate_apple = Option.mem apple (Snake.head snake) ~equal:Position.equal in
    let score_delta = if ate_apple then ate_apple_score else 0 in
    let score = model.score + score_delta in
    let apple_effect =
      if ate_apple then apple_inject Apple.Action.Eatten else Effect.Ignore
    in
    schedule_event apple_effect;
    let (status : Player_status.t) =
      if Snake.is_eatting_self snake
      then Inactive Ate_self
      else if Snake.is_out_of_bounds ~rows ~cols snake
      then Inactive Out_of_bounds
      else Playing
    in
    { Model.direction = model.direction; snake; score; status; left_to_grow }
  | Move _, Inactive _ -> model
;;

let computation ~rows ~cols =
  let open Bonsai.Let_syntax in
  let%sub model, inject =
    Bonsai.state_machine0
      [%here]
      (module Model)
      (module Action)
      ~default_model:(default_model ~rows ~cols)
      ~apply_action:(apply_action ~rows ~cols)
  in
  let%arr model = model
  and inject = inject in
  { snake = model.snake; score = model.score }, inject
;;
