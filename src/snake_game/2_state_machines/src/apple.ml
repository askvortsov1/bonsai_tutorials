open! Core
open! Bonsai_web

type t = Position.t option [@@deriving sexp, equal]

let list_of_t t =
  match t with
  | Some pos -> [ pos ]
  | None -> []
;;

let spawn_random ~rows ~cols ~invalid_pos = Position.random_pos ~rows ~cols ~invalid_pos
let is_eatten a s = Option.mem a (Snake.head s) ~equal:Position.equal

let cell_background a pos =
  if Option.mem a pos ~equal:Position.equal then Some "red" else None
;;

module Model = struct
  type t = Position.t option [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Spawn of Position.t list
    | Eatten of Position.t list
  [@@deriving sexp]
end

let apply_action ~rows ~cols ~inject:_ ~schedule_event:_ _model action =
  match action with
  | Action.Eatten invalid_pos | Spawn invalid_pos -> spawn_random ~rows ~cols ~invalid_pos
;;

let computation ~rows ~cols =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:None
    ~apply_action:(apply_action ~rows ~cols)
;;
