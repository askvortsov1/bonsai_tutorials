open! Core
open! Bonsai_web

type t = Position.t option [@@deriving sexp, equal]

let set_of_t t =
  let module Pos_set = Set.Make (Position) in
  match t with
  | Some pos -> Pos_set.singleton pos
  | None -> Pos_set.empty
;;

module Model = struct
  type t = Position.t option [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Spawn
    | Eatten
  [@@deriving sexp]
end

let apply_action ~rows ~cols ~inject:_ ~schedule_event:_ invalid_pos model action =
  let apple_set = set_of_t model in
  let full_invalid_pos = Set.union invalid_pos apple_set in
  match action with
  | Action.Eatten | Spawn ->
    Position.random_pos ~rows ~cols ~invalid_pos:(Set.to_list full_invalid_pos)
;;

let computation ~rows ~cols ~invalid_pos =
  Bonsai.state_machine1
    [%here]
    (module Model)
    (module Action)
    ~default_model:None
    ~apply_action:(apply_action ~rows ~cols)
    invalid_pos
;;
