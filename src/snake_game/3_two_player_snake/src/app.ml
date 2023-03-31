open! Core
open! Bonsai_web

module Style =
[%css.raw
{|
html,body{min-height:100%; height:100%;}

.app {
  width: 100%;
  height: 100%;
}
|}]

let rows = 20
let cols = 20

let get_keydown_key evt =
  evt##.code
  |> Js_of_ocaml.Js.Optdef.to_option
  |> Option.value_exn
  |> Js_of_ocaml.Js.to_string
;;

let chain_scheduler
  : type a. a Value.t -> ((a -> unit Ui_effect.t) list -> unit Ui_effect.t) Computation.t
  =
 fun input ->
  let module Action = struct
    type t = Run of (a -> unit Effect.t) list [@@deriving sexp]
  end
  in
  let apply_action ~inject ~schedule_event input _model (Action.Run effect_fns) =
    match effect_fns with
    | effect_fn :: dependents ->
      schedule_event (Effect.Many [ effect_fn input; inject (Action.Run dependents) ])
    | [] -> ()
  in
  let open Bonsai.Let_syntax in
  let%sub (), inject =
    Bonsai.state_machine1
      [%here]
      (module Unit)
      (module Action)
      ~default_model:()
      ~apply_action
      input
  in
  let%arr inject = inject in
  fun effects -> inject (Action.Run effects)
;;

let component =
  let open Bonsai.Let_syntax in
  (* State *)
  let%sub player1, player1_inject = Player_state.computation ~rows ~cols ~color:"green" in
  let%sub player2, player2_inject = Player_state.computation ~rows ~cols ~color:"blue" in
  let%sub apple1, apple1_inject = Apple_state.computation ~rows ~cols in
  let%sub apple2, apple2_inject = Apple_state.computation ~rows ~cols in
  let%sub game_elements =
    let%arr player1 = player1
    and player2 = player2
    and apple1 = apple1
    and apple2 = apple2 in
    { Game_elements.snakes = Player_state.Model.snakes [ player1; player2 ]
    ; apples = Apple_state.Model.apples [ apple1; apple2 ]
    }
  in
  let%sub scheduler = chain_scheduler game_elements in
  (* Tick logic *)
  let%sub () =
    let%sub clock_effect =
      let%arr player1_inject = player1_inject
      and player2_inject = player2_inject
      and apple1_inject = apple1_inject
      and apple2_inject = apple2_inject
      and scheduler = scheduler in
      scheduler
        [ (fun g -> player1_inject (Move g))
        ; (fun g -> player2_inject (Move g))
        ; (fun g -> apple1_inject (Tick g))
        ; (fun g -> apple2_inject (Tick g))
        ]
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 0.25) clock_effect
  in
  (* Reset logic *)
  let%sub reset_action =
    let%arr player1_inject = player1_inject
    and player2_inject = player2_inject
    and apple1_inject = apple1_inject
    and apple2_inject = apple2_inject
    and scheduler = scheduler in
    scheduler
      [ (fun g -> player1_inject (Restart g))
      ; (fun g -> player2_inject (Restart g))
      ; (fun g -> apple1_inject (Spawn g))
      ; (fun g -> apple2_inject (Spawn g))
      ]
  in
  (* View component *)
  let%sub board = Board.component ~rows ~cols player1 player2 game_elements in
  let%arr board = board
  and player1_inject = player1_inject
  and player2_inject = player2_inject
  and reset_action = reset_action in
  let on_keydown evt =
    match get_keydown_key evt with
    | "KeyW" -> player1_inject (Change_direction Up)
    | "KeyS" -> player1_inject (Change_direction Down)
    | "KeyA" -> player1_inject (Change_direction Left)
    | "KeyD" -> player1_inject (Change_direction Right)
    | "ArrowUp" -> player2_inject (Change_direction Up)
    | "ArrowDown" -> player2_inject (Change_direction Down)
    | "ArrowLeft" -> player2_inject (Change_direction Left)
    | "ArrowRight" -> player2_inject (Change_direction Right)
    | _ -> Effect.Ignore
  in
  Vdom.(
    Node.div
      ~attr:
        (Attr.many
           [ Attr.on_keydown on_keydown
           ; Attr.on_click (fun _ -> reset_action)
           ; Attr.class_ Style.app
           ])
      [ board ])
;;
