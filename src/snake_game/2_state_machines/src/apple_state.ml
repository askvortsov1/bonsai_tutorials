open! Core
open! Bonsai_web

module Model = struct
  type t =
    | Not_started
    | Playing of Apple.t
  [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Spawn of Snake.t option
    | Tick of Snake.t option
  [@@deriving sexp]
end

let spawn ~rows ~cols snake =
  let invalid_pos = Snake.list_of_t snake in
  Model.Playing (Apple.spawn_random_exn ~rows ~cols ~invalid_pos)
;;

let apply_action ~rows ~cols ~inject:_ ~schedule_event:_ model action =
  match action, model with
  | Action.Spawn None, _ ->
    raise_s [%message "Invalid state: snake should be spawned before apple."]
  | Action.Spawn (Some snake), _ -> spawn ~rows ~cols snake
  | Tick None, Model.Playing _ ->
    raise_s [%message "Invalid state: apple initialized but not snake."]
  | Tick (Some snake), Model.Playing apple ->
    if Snake.is_eatting_apple snake apple then spawn ~rows ~cols snake else model
  | Tick _, Model.Not_started -> model
;;

let computation ~rows ~cols =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:Not_started
    ~apply_action:(apply_action ~rows ~cols)
;;
