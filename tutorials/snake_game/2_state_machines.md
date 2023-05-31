# Implementing State

In the [last chapter](1_display_and_types.md), we implemented types and logic for
building blocks like `Position.t`, `Direction.t`, `Snake.t`, and `Apple.t`.
We then built `Board.component`, which renders the game into Vdom.

In this chapter, we'll bundle those building blocks in Bonsai state machines,
finally creating a dynamic, working system.

We'll also implement user controls, so that the snake game can actually be played.

By the end of this chapter, you'll have a working single-player version of Snake!

I recommend pairing it with:

- The official Bonsai documentation on [state](https://bonsai.red/03-state.html).
- The stateful primitives and helpers listed in the
  [bonsai.mli API reference](https://github.com/janestreet/bonsai/blob/master/src/bonsai.mli)
- The docs on [effects](https://bonsai.red/05-effect.html)

## State in Bonsai Intro

Before we dive into building stateful wrappers for `Snake.t` and `Apple.t`,
let's take a second to introduce how Bonsai deals with state.

Bonsai's main state primitive is the *state machine*. To create one, you need several things:

- A `Model` first-class module.
  It must include `type t`, which is the structure of data in the state machine.
  `Model.t` must be `sexp`able and `equal`able; i.e. it should ppx-derive `sexp` and `equal`.
- A `default_model : Model.t` value. Unsurprisingly, this is the state machine's initial value.
  Note that this has to be a raw OCaml value; it can't be a `Value.t`, or a function of the
  state machine's inputs.
- An `Action` first-class module.
  `Action.t` needs to sexpable, and represents *things that could happen*.
  In practice, this generally boils down to a variant type.
- An `apply_action` function, which takes the current model value and an `Action.t`,
  and computes a new model.

If you've ever used [React Redux](https://react-redux.js.org/) or [Elm](https://elm-lang.org/), this should look a bit familiar.
So why do all of this instead of just having `state, setState = React.useState(default)`
like in React?

Often, the state machine components we build will be used in other components.
Exhaustively defining all possible `Action.t`s, and how the model should
change in response to all of them, gives us a rigorous, behavior-driven public API.
This makes big, complex programs much more maintainable, since the state transition
logic is centralized in one place, and any given implementation could be easily
swapped out for another.

> **Note** Bonsai *does have* a state setter/getter too;
> see [`Bonsai.state` in the API reference](https://bonsai.red/03-state.html#simple-state).
> It's just that `state_machine0` tends to be a better design pattern,
> and [avoids some race conditions](https://bonsai.red/03-state.html#state-machine).
> And that's not the only other state primitive Bonsai provides!
> See [the mli reference](https://github.com/janestreet/bonsai/blob/master/src/bonsai.mli) for more.

All of this describes `state_machine0`. The `0` means there are no inputs.
But our apple depends on the snake!
It spawns second, so it needs to know which cells are already occupied by the snake.
It also needs the most up-to-date position of the snake,
so that it can check if it has been eatten after the snake moves.

To implement that, we'll use `Bonsai.state_machine1`, which takes a `'input Value.t` argument,
and provides the current `'input` value in its `apply_action` function.

That's all you need to know for now, but I highly recommend reading
[the full state docs](https://bonsai.red/03-state.html).
Let's go implement some state machines!

## Player (Snake) State

Our player state combines a `Snake.t` and `score: int`, and a status, which is either `Not_started`, `Playing`, or `Game_over`.

State machines encourage good design by forcing you to rigorously define all possible "actions", and how they should be handled.
If we take a step back, there's only really 3 things that happen in a game of Snake after it starts:

- When a "restart" button is pressed, the score is set to 0, and the snake is re-placed randomly on the screen.
- Every *tick*, the snake moves one step forward. If it eats itself or goes out of bounds, the game ends.
  If it eats the apple, it grows, and the apple respawns.
- A user can change the direction a snake is moving in.

All 3 affect the player, so we'll need corresponding `Restart`, `Move of Apple.t`, and `Change_direction of Direction.t` actions.
Note that we'll spawn the snake before the apple, so the snake's `Restart` action doesn't need an `Apple.t` data argument.

Create `player_state.mli` and add the following type declarations:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.mli,part=action -->
```ocaml
open! Core
open! Bonsai

module Action : sig
  type t =
    | Restart
    | Move of Apple.t
    | Change_direction of Direction.t
end
```

And also `player_state.ml` with a nearly identical implementation:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=action -->
```ocaml
open! Core
open! Bonsai

module Action = struct
  type t =
    | Restart
    | Move of Apple.t
    | Change_direction of Direction.t
  [@@deriving sexp]
end
```

### Data Model

Let's start by formally defining the data model encapsulated by our player state machine.
Our player state combines a `Snake.t` and `score: int`, and a status, which is either `Not_started`, `Playing`, or `Game_over`.
`Not_started` is there because we don't want to start the game before the player is ready.
Also, for `Game_over`, we'll want to store an `End_reason`: did the snake eat itself, or run into a wall?

Add the following signature to `player_state.mli`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.mli,part=model -->
```ocaml
module Model : sig
  module End_reason : sig
    type t =
      | Ate_self
      | Out_of_bounds
    [@@deriving sexp, equal]
  end

  module Status : sig
    type t =
      | Not_started
      | Playing
      | Game_over of End_reason.t
    [@@deriving sexp, equal, variants]
  end

  type t =
    { score : int
    ; snake : Snake.t
    ; status : Status.t
    }
  [@@deriving sexp, equal, fields]
end
```

And the corresponding implementation to `player_state.ml`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=model -->
```ocaml
module Model = struct
  module End_reason = struct
    type t =
      | Ate_self
      | Out_of_bounds
    [@@deriving sexp, equal]
  end

  module Status = struct
    type t =
      | Not_started
      | Playing
      | Game_over of End_reason.t
    [@@deriving sexp, equal, variants]
  end

  type t =
    { score : int
    ; snake : Snake.t
    ; status : Status.t
    }
  [@@deriving sexp, equal, fields]
end
```

### Player `apply_action`

We've defined the player state machine's data model, and the actions that should update it.
Now, it's time to implement the state transition function, which updates the model in response to an action.
We'll write this one piece at a time.

Start by adding the following to `player_state.ml`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_match -->
```ocaml
let apply_action
  ~rows
  ~cols
  ~color
  ~inject:_
  ~schedule_event:_
  (model : Model.t)
  (action : Action.t)
  =
  match action, model.status with
```

`rows`, `cols`, and `color` are extra arguments that we'll pass to `apply_action` through [currying](https://dev.realworldocaml.org/variables-and-functions.html#multi-argument-functions).
The `inject` and `schedule_event` arguments allow `apply_action` to dispatch other actions.
Our implementation won't use them.
The actual implementation of this function is a giant pattern match, since each action/status combo should be handled differently.

If the action is `Restart`, we'll want to spawn a new snake and reset the score regardless of the current status:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_restart -->
```ocaml
  | Restart, _ ->
    let snake = Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color in
    { Model.score = 0; snake; status = Playing }
```

Pretty straightforward.
Note that `apply_action` doesn't mutate anything; it just computes a new `Model.t`.
This lets us deal with state in a clean, functional way.

For `Move`, if the status is `Playing`,
we'll move the snake, and then either end the game, tell the snake to grow next turn,
or do nothing, depending on where the snake ends up.
To keep things simple and readable, we'll implement most of this in terms of
(soon to be defined) helper functions from `Snake`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_move_playing_snake -->
```ocaml
  | Move apple, Playing ->
    let ate_apple_score = 1 in
    let snake = Snake.move model.snake in
    if Snake.is_eatting_self snake
    then { model with status = Game_over Ate_self }
    else if Snake.is_out_of_bounds ~rows ~cols snake
    then { model with status = Game_over Out_of_bounds }
    else if Snake.is_eatting_apple snake apple
    then
      { model with
        snake = Snake.grow_eventually ~by:1 snake
      ; score = model.score + ate_apple_score
      }
    else { model with snake }
```

Note that with this approach, the snake does not tell the apple it has been eatten.
Instead, we'll need to implement `Apple_state.apply_action` so that it respawns
if eatten by a snake. But we'll get to that.

For now, let's finish implementing our cases.
If the direction is changed while playing, we'll update our snake accordingly:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_change_direction -->
```ocaml
  | Change_direction dir, Playing ->
    { model with snake = Snake.with_direction model.snake dir }
```

There's also some cases where nothing should change.
A `Move` or `Change_direction` action when the status is `Not_started` or `Game_over` is a no-op:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_noop -->
```ocaml
  | Move _, Not_started
  | Move _, Game_over _
  | Change_direction _, Not_started
  | Change_direction _, Game_over _ -> model
;;
```

And with that, all cases should be covered.

### Snake Helper Functions

Before we can finish the component, we should implement all the `Snake.*` helper functions
that we added to make our code clean and simple.
Here are their type signatures, which you should add to `snake.mli`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/snake.mli,part=new_helpers -->
```ocaml
(** [move t] moves a snake 1 step in its current direction. It may or may not grow,
    depending on its internal state. *)
val move : t -> t

(** [color t] returns the color of the snake. *)
val color : t -> Css_gen.Color.t

(** [with_direction t dir] returns a [Snake.t] with an updated direction. *)
val with_direction : t -> Direction.t -> t

(** [is_eatting_apple t] returns true iff the snake's head is overlapping
    with the provided [Apple.t].  *)
val is_eatting_apple : t -> Apple.t -> bool

(** [is_eatting_self t] returns true iff the snake's head is overlapping with any of
    the snake's body segments.  *)
val is_eatting_self : t -> bool

(** [is_out_of_bounds ~rows ~cols t] returns true iff the snake's head has gone
    outside of the [rows]*[cols] grid. *)
val is_out_of_bounds : rows:int -> cols:int -> t -> bool

(** [grow_eventually ~by] updates a snake's internal state to grow 1 cell
    for the next [by] times [move] is called. *)
val grow_eventually : by:int -> t -> t
```

First, we need to keep track of how much the snake has left to grow.
Add a `left_to_grow: int` field to the `type t` definition in `snake.ml`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/snake.ml,part=t_new_field -->
```ocaml
type t =
  { pos : Position.t list
  ; direction : Direction.t
  ; color : Color.t
  ; left_to_grow : int
  }
[@@deriving sexp, equal]
```

And to the `spawn_random_exn` initializer:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/snake.ml,part=new_field_initialization -->
```ocaml
let spawn_random_exn ~rows ~cols ~invalid_pos ~color =
  let head = Position.random_pos ~rows ~cols:(cols / 2) ~invalid_pos in
  let head_exn = Option.value_exn head in
  { pos = [ head_exn ]; direction = Direction.Right; left_to_grow = 0; color }
;;

let cell_style s pos =
  if List.mem (list_of_t s) pos ~equal:Position.equal
  then Some (Css_gen.background_color s.color)
  else None
;;
```

And then implement `move`. As discussed
[in the first chapter of this tutorial](./0_hello_world.md#snake-and-apple-implementation),
we'll find the next head, add that to the snake's position list, and then drop the last
element if the snake is **not** growing:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/snake.ml,part=move_impl -->
```ocaml
let head s = List.hd_exn s.pos

let move s =
  let new_head = Position.step (head s) s.direction in
  let new_pos =
    let with_head = new_head :: s.pos in
    if Int.equal s.left_to_grow 0 then List.drop_last_exn with_head else with_head
  in
  let left_to_grow = Int.max 0 (s.left_to_grow - 1) in
  { s with left_to_grow; pos = new_pos }
;;
```

The other helpers are very straightforward:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/snake.ml,part=other_impl -->
```ocaml
let color s = s.color
let with_direction s direction = { s with direction }
let grow_eventually ~by s = { s with left_to_grow = s.left_to_grow + by }

let is_out_of_bounds ~rows ~cols s =
  let { Position.row; col } = head s in
  row < 0 || row >= rows || col < 0 || col >= cols
;;

let is_eatting_apple s a = List.mem (Apple.list_of_t a) (head s) ~equal:Position.equal

let is_eatting_self s =
  match list_of_t s with
  | head :: tail -> List.mem tail head ~equal:Position.equal
  (* This should never happen. *)
  | [] -> false
;;
```

### Player State Component

Finally, let's wrap our `Action`, `Model`, and `apply_action` in
a Bonsai state machine.

We've defined [all the parts we need](#state-in-bonsai-intro),
except for `default_model`.
This part is tricky, because `default_model` needs to be a raw `Model.t`.
It can't be a function that computes `Model.t`, or an incremental function.
`Apple_state`'s `default_value` depends on that of `Player_state`,
because the apple **may not** spawn on top of the snake.
This means that we'll need to compute the `default_model`s of Player and Apple
in some parent component, and pass them in. Add the following to `player_state.ml`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=computation -->
```ocaml
let computation ~rows ~cols ~default_snake =
  Bonsai.state_machine0
    (module Model)
    (module Action)
    ~default_model:{ Model.snake = default_snake; status = Not_started; score = 0 }
    ~apply_action:(apply_action ~rows ~cols ~color:(Snake.color default_snake))
;;
```

Notice that we use a `Snake.color` helper,
so that we don't need to pass the color in for both the default state and component definition.
That's the only helper defined in the previous section that's not used by `apply_action`.

Then, export it by adding the type signature to `player_state.mli`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.mli,part=computation -->
```ocaml
val computation
  :  rows:int
  -> cols:int
  -> default_snake:Snake.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
```

Note that the state machine returns 2 things:
the current `Model.t`, and an `Action.t -> unit Effect.t` function,
which can be used to dispatch actions into the state machine.

Congratulations: you've implemented the most complex state machine in Snake!

## Apple State

The state machine wrapping our `Apple.t` is a lot simpler.
The only actions are `Place`, which respawns the apple somewhere random,
and `Tick of Snake.t`, which respawns the apple if it has been eatten.
Apples don't need have a status, so the model is just `Apple.t`.

The biggest difference is that we'll use `state_machine1`,
so that a `Snake.t Value.t` can be an input.
It will be an extra argument to the `computation` function.

Create `apple_state.mli` with the following contents:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.mli -->
```ocaml
open! Core
open! Bonsai_web

module Model : sig
  type t = Apple.t [@@deriving sexp, equal]
end

module Action : sig
  type t =
    | Place
    | Tick
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> default_apple:Model.t
  -> Snake.t Value.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
```

And `apple_state.ml` with the corresponding `Model` and `Action` modules:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=model_action -->
```ocaml
open! Core
open! Bonsai_web

module Model = struct
  type t = Apple.t [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Place
    | Tick
  [@@deriving sexp]
end
```

Once again, we'll implement `apply_action` one step at a time.
Notice that `apply_action` takes an additional `snake` argument,
which is the up-to-date value of the `Snake.t Value.t` we provided.
This input is actually a `Snake.t Computation_status.t`,
which is just `Inactive | Active Snake.t`. We don't need to worry about inactive inputs, so we can treat that as a no-op:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=apply_action_sig -->
```ocaml
let apply_action ~rows ~cols ~inject ~schedule_event snake model action =
  match snake with
  | Bonsai.Computation_status.Inactive -> model (* Should never happen. *)
  | Active snake ->
```

Onto the cases.
`Place` is simple: we just respawn the apple.

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=apply_action_spawn -->
```ocaml
    (match action with
     | Action.Place ->
       let invalid_pos = Snake.list_of_t snake in
       Apple.spawn_random_exn ~rows ~cols ~invalid_pos
```

On `Tick`, if the apple has been eatten, we respawn it by dispatching an `Action.Place`.
Unlike with `Player_state`'s `apply_action`, we use `inject` to create an `unit Effect.t`,
and `schedule_event` to dispatch it to the Bonsai event-queue.
Regardless, we return model.
Note that the dispatched effect will be executed *after*
the currently running effect.

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=apply_action_tick -->
```ocaml
     | Tick ->
       if Snake.is_eatting_apple snake model then schedule_event (inject Action.Place);
       model)
;;
```

> **Note** Instead of the apple checking whether it has been
> eatten on every tick, we could have had the snake dispatch an
> `Apple.Action.Spawn` using the `schedule_event` function in its
> `apply_action`. This would save the redundant check, but would
> force us to pass every apple's `inject` function to the Snake's
> `Move` action, which gets messy, fast.

And finally, we'll wrap things up in a `Bonsai.state_machine1`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=computation -->
```ocaml
let computation ~rows ~cols ~default_apple snake =
  Bonsai.state_machine1
    (module Model)
    (module Action)
    ~default_model:default_apple
    ~apply_action:(apply_action ~rows ~cols)
    snake
;;
```

## Board Changes

Instead of `Snake.t Value.t` and `Apple.t Value.t`,
our `Board.component` will take `Player_state.Model.t Value.t`
and `Apple_state.Model.t Value.t`. Update `board.mli` accordingly:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/board.mli -->
```ocaml
open! Core
open! Bonsai_web

val component
  :  rows:int
  -> cols:int
  -> Player_state.Model.t Value.t
  -> Apple_state.Model.t Value.t
  -> Vdom.Node.t Computation.t
```

Other than renaming `snake` to `player` in the `Board.component` function,
the biggest change is that we'll only create the full style drivers
if both the snake and apple are initialized:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/board.ml,part=computation_changes -->
```ocaml
let component ~rows ~cols (player : Player_state.Model.t Value.t) apple =
  let open Bonsai.Let_syntax in
  let%arr player = player
  and apple = apple in
  let cell_style_driver =
    merge_cell_style_drivers ~snakes:[ player.snake ] ~apples:[ apple ]
  in
  Vdom.(
    Node.div
      ~attrs:
        [ Style.Variables.set
            ~grid_cols:(Int.to_string rows)
            ~grid_rows:(Int.to_string cols)
            ()
        ]
      [ Node.h1 [ Node.text "Snake Game" ]
      ; Node.p [ Node.text "Click anywhere to reset." ]
      ; view_score_status ~label:"Results" player
      ; view_game_grid rows cols cell_style_driver
      ])
;;
```

We'll also add a `view_score_status` vdom element,
which displays the score and game status above the game grid.
Add the following code above the `component` function:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/board.ml,part=score_status -->
```ocaml
let view_score_status ~label (player : Player_state.Model.t) =
  let content =
    let open Vdom.Node in
    let score_text score = p [ textf "Score: %d" score ] in
    match player.status with
    | Player_state.Model.Status.Not_started -> [ p [ text "Click to start!" ] ]
    | Playing -> [ score_text player.score ]
    | Game_over Out_of_bounds ->
      [ p [ text "Game over... Out of bounds!" ]; score_text player.score ]
    | Game_over Ate_self ->
      [ p [ text "Game over... Ate self!" ]; score_text player.score ]
  in
  Vdom.(Node.div (Node.h3 [ Node.text label ] :: content))
;;
```

## Composing Everything Together

We've now implemented state machines for the player and apple,
and updated the board component to display them.
The last step is composing everything together in `App.component`.

Before we start writing code, let's decide what we want this "coordinating" component to do.

As in the static version from last chapter, we need to create a snake and apple,
and pass them to `Board.component. For interactivity, we'll also want to:

- Start/restart the game when the player clicks anywhere.
  We'll do this by dispatching `Restart`/`Place` actions.
- Change the snake's direction via WASD keypresses.
  Similarly, this will dispatch a `Change_direction` action.

And of course, every `x` seconds, we'll want to dispatch `Move` and `Tick` actions
for the snake and apple so that things actually happen.

We'll start by composing in the `Player_state` and `Apple_state` state machines,
and passing their outputs to `Board.component`.
As mentioned above, we'll generate `default_model` values externally
so that they don't overlap, and pass those into the `computation`s.

Change the `component` function in `app.ml` to the following:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=state -->
```ocaml
let component =
  let default_snake =
    Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color:(`Name "green")
  in
  let default_apple =
    Apple.spawn_random_exn ~rows ~cols ~invalid_pos:(Snake.list_of_t default_snake)
  in
  let open Bonsai.Let_syntax in
  let%sub player, player_inject = Player_state.computation ~rows ~cols ~default_snake in
  let%sub snake =
    let%arr player = player in
    player.snake
  in
  let%sub apple, apple_inject =
    Apple_state.computation ~rows ~cols ~default_apple snake
  in
```

Note that above, we incrementally map `snake` from `player`,
and provide that as a dependency to `Apple_state.computation`.

Also, recall that state machines incrementally compute 2 things:
the `Model.t`, and a `Action.t -> unit Effect.t` function,
which can be used by other components to dispatch actions into
the state machine. We call this function `inject`, for, uh,
[reasons](https://github.com/janestreet/bonsai/pull/30#discussion_r1041679507).

Continuing with the code...

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=view -->
```ocaml
  let%sub board = Board.component ~rows ~cols player apple in
  let%arr board = board
  and on_keydown = on_keydown
  and on_reset = on_reset in
  Vdom.(
    Node.div
      ~attrs:[ Attr.on_keydown on_keydown; Attr.on_click (fun _ -> on_reset); Style.app ]
      [ board ])
;;
```

Note that we wrapped the `Board.component` in a div with style `app`.
We want clicks/keypresses *anywhere* on the page to trigger clicks + keydowns,
so we'll also add some custom CSS to make this div take up the whole page:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=style -->
```ocaml
module Style =
[%css
stylesheet
  {|
html,body{min-height:100%; height:100%;}

.app {
  width: 100%;
  height: 100%;
}
|}]
```

Our code won't compile yet, because we still need to implement
`on_keydown : (Js_of_ocaml.Dom_html.keyboardEvent Js_of_ocaml.Js.t -> unit Ui_effect.t) Value.t`
and `on_reset : unit Ui_effect.t Value.t`.
As with all event handlers, these are (or return) `Effect.t`.
These are scheduled on an event queue, and when executed,
instruct Bonsai to [update state or perform side effects](https://bonsai.red/05-effect.html).

Let's start with `on_keydown`, which should dispatch `Change_direction` on player,
because that doesn't involve the snake. First, we need to figure out which key is pressed.
Depending on that key, dispatch `Change_direction` of some direction, or a no-op.

Add the following util function to the top of the file:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=keydown_util -->
```ocaml
let get_keydown_key evt =
  evt##.key
  |> Js_of_ocaml.Js.Optdef.to_option
  |> Option.value_exn
  |> Js_of_ocaml.Js.to_string
;;
```

This takes a `keyboardEvent Js.t`, which is the `Js_of_ocaml` wrapper around
a [browser KeyboardEvent](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent),
and returns its `key` property as a string.
Read the [Jsoo docs](https://ocsigen.org/js_of_ocaml/latest/manual/library)
for more info on how Jsoo syntax and types work.

Back to `component`, right above our board definition, add the following code:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=on_keydown -->
```ocaml
  let%sub on_keydown =
    let%arr player_inject = player_inject in
    fun evt ->
      match get_keydown_key evt with
      | "w" -> player_inject (Change_direction Up)
      | "s" -> player_inject (Change_direction Down)
      | "a" -> player_inject (Change_direction Left)
      | "d" -> player_inject (Change_direction Right)
      | _ -> Effect.Ignore
  in
```

We create an incremental computation depending on `player_inject` using `let%arr`.
It produces a function that takes a keydownEvent (`evt`), gets
the key using our helper, and if the key is `w`, `a`, `s`, or `d`,
returns `unit Effect.t` that dispatches `Change_direction` to the player.
Otherwise, it returns the no-op `Effect.Ignore`.
We use `let%sub` to instantiate `on_keydown` from a `Computation.t` to a `Value.t`.

`on_reset` is even simpler:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=reset -->
```ocaml
  let%sub on_reset =
    let%arr player_inject = player_inject
    and apple_inject = apple_inject in
    Effect.Many [ player_inject Restart; apple_inject Place ]
  in
```

We simply use `Effect.Many` to trigger both the player and apple to restart/replace.

Finally, since we want the game to run,
we need to dispatch `Move`/`Tick` actions on an interval.
We can do this with [Bonsai.Clock.every](https://github.com/janestreet/bonsai/blob/v0.15/src/bonsai.mli#L433):

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=tick -->
```ocaml
  let%sub () =
    let%sub clock_effect =
      let%arr player_inject = player_inject
      and apple_inject = apple_inject
      and apple = apple in
      Effect.Many [ player_inject (Move apple); apple_inject Tick ]
    in
    Bonsai.Clock.every
      ~when_to_start_next_effect:`Every_multiple_of_period_blocking
      (Time_ns.Span.of_sec 0.25)
      clock_effect
  in
```

`when_to_start_next_effect` gives you fine control over the scheduler.
For our case, it doesn't really matter which option we choose.

## Recap

And that's it! Congratulations, you've now built a working version of Snake in Bonsai.

To recap, this chapter, we've:

- Introduced what state machines are.
- Defined the actions and model structure for the Player and Apple state machines.
- Implemented `apply_action` functions for Player (no inputs) and Apple (1 input).
- Built working state machines out of these pieces with `Bonsai.state_machine0` and `Bonsai.state_machine1`.
- Adapted the board to take `Player_state.Model.t` and `Apple.Model.t`.
- Composed our new state machines together, computing the `default_model` values externally for a valid initial state.
- Implemented resetting the game, changing direction, and an interval-based tick in terms of `Effect.t`.
- Scheduled that interval-based tick with `Bonsai.Clock.every`.

In [the next chapter](./3_two_player_snake.md), we'll showcase the flexibility of Bonsai by adding another snakes,
and a variable number of apples.

## Exercises

### (Accidential) Sudden Death

Currently, if your snake has length > 1, if you change its direction to the opposite of its current direction,
the game will end because it will overlap onto itself.

This is annoying, and almost always the result of pressing the wrong key.
Can you make this better?

<details>
  <summary>Hint</summary>

   > In `Snake.with_direction`, don't do anything if the new direction
   > is the opposite (left <> right, up <> down) of the current direction.
</details>

### High Scores!

A true Snake enthuiast simply must know if they are improving.
Use [Bonsai.Edge'](https://github.com/janestreet/bonsai/blob/v0.15/src/bonsai.mli#L462)
and [window.localStorage](https://ocaml.org/p/js_of_ocaml/latest/doc/Js_of_ocaml/Dom_html/class-type-window/index.html#method-localStorage)
to keep track of the high score.

<details>
  <summary>Hint</summary>

   > In `App.component`, monitor `player.status` with `Bonsai.Edge.on_change'`.
   > When the status becomes `Game_over`, use [the Js_of_ocaml ppx](https://ocsigen.org/js_of_ocaml/latest/manual/ppx)
   > to access [`Js_of_ocaml.Dom_html.window##.localStorage`'s `getItem` and `setItem` methods](https://ocaml.org/p/js_of_ocaml/latest/doc/Js_of_ocaml/Dom_html/class-type-storage/index.html).
   > Put that in a `Bonsai.Var.t`, which should be passed to `Board.component` and displayed.
</details>
