open! Core
open! Bonsai_web

module Model = struct
  type t = Apple.t [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Place of Game_elements.t
    | Tick of Game_elements.t
  [@@deriving sexp]
end

let spawn ~rows ~cols game_elements =
  let invalid_pos = Game_elements.occupied_pos game_elements in
  Apple.spawn_random_exn ~rows ~cols ~invalid_pos
;;

let apply_action ~rows ~cols ~inject ~schedule_event model action =
  match action with
  | Action.Place game_elements -> spawn ~rows ~cols game_elements
  | Tick game_elements ->
    if List.exists game_elements.snakes ~f:(fun s -> Snake.is_eatting_apple s model)
    then schedule_event (inject (Action.Place game_elements));
    model
;;

let computation ~rows ~cols ~default_apple =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:default_apple
    ~apply_action:(apply_action ~rows ~cols)
;;
