open! Core
open! Bonsai_web

module Model = struct
  type t =
    | Not_started
    | Playing of Apple.t
  [@@deriving sexp, equal]

  let apples states =
    List.fold states ~init:[] ~f:(fun apples -> function
      | Playing apple -> apple :: apples
      | Not_started -> apples)
  ;;
end

module Action = struct
  type t =
    | Spawn of Game_elements.t
    | Tick of Game_elements.t
  [@@deriving sexp]
end

let spawn ~rows ~cols game_elements =
  let invalid_pos = Game_elements.occupied_pos game_elements in
  Model.Playing (Apple.spawn_random_exn ~rows ~cols ~invalid_pos)
;;

let apply_action ~rows ~cols ~inject:_ ~schedule_event:_ model action =
  match action, model with
  | Action.Spawn game_elements, _ -> spawn ~rows ~cols game_elements
  | Tick game_elements, Model.Playing apple ->
    Js_of_ocaml.Firebug.console##log (Game_elements.print game_elements);
    if List.exists game_elements.snakes ~f:(fun s -> Snake.is_eatting_apple s apple)
    then spawn ~rows ~cols game_elements
    else model
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
