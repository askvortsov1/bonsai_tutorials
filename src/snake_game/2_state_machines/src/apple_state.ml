open! Core
open! Bonsai_web

module Model = struct
  type t =
    | Not_started
    | Playing of Apple.t
  [@@deriving sexp, equal]

  let apple_pos t =
    match t with
    | Playing a -> Apple.list_of_t a
    | Not_started -> []
  ;;
end

module Action = struct
  type t =
    | Spawn of Position.t list
    | Eatten of Position.t list
  [@@deriving sexp]
end

let apply_action ~rows ~cols ~inject:_ ~schedule_event:_ _model action =
  match action with
  | Action.Eatten invalid_pos | Spawn invalid_pos ->
    Model.Playing (Apple.spawn_random_exn ~rows ~cols ~invalid_pos)
;;

let computation ~rows ~cols =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:Not_started
    ~apply_action:(apply_action ~rows ~cols)
;;
