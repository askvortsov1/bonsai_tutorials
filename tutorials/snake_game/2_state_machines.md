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

> **Note** Bonsai *does have* a state setter/getter too; see [`Bonsai.state` in the API reference]().
> It's just that `state_machine0` tends to be a better design pattern,
> and [avoids some race conditions](https://bonsai.red/03-state.html#state-machine).

That's all you need to know for now, but I highly recommend reading [the full state docs](https://bonsai.red/03-state.html).
Let's go implement some state machines!

## When, Oh When To Spawn???

Sorry, one more thing. Before we implement anything, we have a little design conundrum:
should the snake and apple be spawned in when the page loads, or can we wait until the game starts?

Recall that `default_model` has to be a raw `Model.t`; not an incremental `Value.t`,
or `'a -> Model.t` function. However, there's a dependency between the apple and snake,
since they **may not** overlap on spawn. So in the former case, we'd need to spawn the `Snake.t` and `Apple.t`
outside of our state machines, and pass them in for `default_model` and a `Restart` action.

In contrast, if we wait until the game starts, we can have a single `Restart of other_stuff` action,
which is handled by spawning the snake or apple somewhere not occupied by `other_stuff`.
As an added benefit, we can also encapsulate the spawning logic in the state machine.

## Player (Snake) State

Our player state combines a `Snake.t` and `score: int`, and a status, which is either `Not_started`, `Playing`, or `Game_over`.

State machines encourage good design by forcing you to rigorously define all possible "actions", and how they should be handled.
If we take a step back, there's only really 3 things that happen in a game of Snake:

- At the start, or when a "restart" button is pressed, the score is set to 0, and one snake is placed randomly on the screen.
- A user can change the direction a snake is moving in.
- Every *tick*, the snake moves one step forward. If it eats itself or goes out of bounds, the game ends.
  If it eats the apple, it grows, and the apple respawns.

All 3 affect the player, so we'll have corresponding `Restart`, `Move of Apple.t`, and `Change_direction of Direction.t` actions.
Note that we'll spawn the snake before the apple, so the snake's `Restart` action doesn't need an `Apple.t` dependency.

Create `player_state.mli` and add the following type declarations:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.mli,part=action -->
```ocaml
open! Core
open! Bonsai

module Action : sig
  type t =
    | Restart
    | Move of Apple.t option
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
    | Move of Apple.t option
    | Change_direction of Direction.t
  [@@deriving sexp]
end
```

Note that we have `Move of Apple.t option`, not `Move of Apple.t`.
That's the downside to spawning the snake and apple in at runtime:
we can't use the type system to enforce existence, because existence is not always guarunteeed.

### Data Model

Let's start by formally defining the data model encapsulated by our player state machine.
Our player state combines a `Snake.t` and `score: int`, and a status, which is either `Not_started`, `Playing`, or `Game_over`.
`Not_started` is there because we don't want to start the game before the player is ready.
As discussed above, the snake shouldn't be spawned until the `Playing` status.
Additionally, for `Game_over`, we'll want to store an `End_reason`: did the snake eat itself, or run into a wall?

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

  module Data : sig
    type t =
      { score : int
      ; snake : Snake.t
      }
    [@@deriving sexp, equal, fields]
  end

  type t =
    | Not_started
    | Playing of Data.t
    | Game_over of (Data.t * End_reason.t)
  [@@deriving sexp, equal, variants]
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

  module Data = struct
    type t =
      { score : int
      ; snake : Snake.t
      }
    [@@deriving sexp, equal, fields]
  end

  type t =
    | Not_started
    | Playing of Data.t
    | Game_over of (Data.t * End_reason.t)
  [@@deriving sexp, equal, variants]
end
```

Note that Bonsai models can be arbitrarily complex data structures,
as long as they implement `sexp` and `equal`.
Generally speaking though, you'll want immutable models,
so that all possible data changes are rigorously defined in `apply_action`.
And on that note!

### Player `apply_action`

We've defined the player state machine's data model, and the actions that should update it.
Now, it's time to implement the transition function, which updates the model in response to an action.
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
  match action, model with
```

`rows`, `cols`, and `color` are extra arguments that we'll pass to `apply_action` through [currying](https://dev.realworldocaml.org/variables-and-functions.html#multi-argument-functions).
The `inject` and `schedule_event` arguments allow `apply_action` to dispatch other actions.
Our implementation won't use them.
The actual implementation of this function is a giant pattern match, since each action/model combo should be handled differently.

If the action is `Restart`, we'll want to spawn a new snake and reset the score regardless of the current status:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_restart -->
```ocaml
  | Restart, _ ->
    let snake = Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color in
    Model.Playing { score = 0; snake }
```

Pretty straightforward.
Note that `apply_action` doesn't mutate anything; it just computes a new `Model.t`.
This lets us deal with state in a clean, functional way.

Anyways, let's look at a trickier case: the `Move` action while status is `Playing`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_move_playing_no_snake -->
```ocaml
  | Move None, Playing _ ->
    raise_s [%message "Invalid state: snake initialized but not apple."]
```

As mentioned above, because snakes and apples aren't spawned in immediately,
we have to represent them as options. This allows for an illegal state,
where one of the entities has spawned, but the other has not.
This should never happen, so we'll raise an exception if it does.

If the status is valid, and both the snake and apple are present,
we'll move the snake, and then either end the game, tell the snake to grow next turn,
or do nothing, depending on where the snake ends up.
To keep things simple and readable, we'll implement most of this in terms of
helper functions from `Snake`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_move_playing_snake -->
```ocaml
  | Move (Some apple), Playing data ->
    let ate_apple_score = 1 in
    let snake = Snake.move data.snake in
    if Snake.is_eatting_self snake
    then Game_over (data, Ate_self)
    else if Snake.is_out_of_bounds ~rows ~cols snake
    then Game_over (data, Out_of_bounds)
    else if Snake.is_eatting_apple snake apple
    then
      Playing
        { snake = Snake.grow_eventually ~by:1 snake
        ; score = data.score + ate_apple_score
        }
    else Playing { data with snake }
```

Note that with this approach, the snake does not tell the apple it has been eatten.
Instead, we'll need to implement `Apple_state.apply_action` so that it respawns
if eatten by a snake. But we'll get to that.

For now, let's finish implementing our cases.
If the direction is changed while playing, we'll update our snake accordingly:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=apply_change_direction -->
```ocaml
  | Change_direction dir, Playing data ->
    Playing { data with snake = Snake.with_direction data.snake dir }
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
a Bonsai state machine by adding the following to `player_state.ml`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.ml,part=computation -->
```ocaml
let computation ~rows ~cols ~color =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:Not_started
    ~apply_action:(apply_action ~rows ~cols ~color)
;;
```

There's also a `state_machine1`, which takes an additional `'a Value.t` input,
and provides that `'a` to the `apply_action` function.
And that's not the only state primitive Bonsai provides!
See [the mli reference](https://github.com/janestreet/bonsai/blob/master/src/bonsai.mli) for more.

Finally, export it by adding the type signature to `player_state.mli`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/player_state.mli,part=computation -->
```ocaml
val computation
  :  rows:int
  -> cols:int
  -> color:Css_gen.Color.t
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
```

Congratulations: you've implemented the most complex state machine in Snake!

## Apple State

The state machine wrapping our `Apple.t` is a lot simpler.
The only actions are `Spawn of Snake.t option`, which respawns the apple (shocking, I know!),
and `Tick of Snake.t option`, which respawns the apple if it has been eatten.
And the model is `Not_started | Placed of Apple.t`.
Apples can't "lose" the game, so we don't need a `Game_over` status.

Create `apple_state.mli` with the following contents:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.mli -->
```ocaml
open! Core
open! Bonsai_web

module Model : sig
  type t =
    | Not_started
    | Placed of Apple.t
  [@@deriving sexp, equal]
end

module Action : sig
  type t =
    | Spawn of Snake.t option
    | Tick of Snake.t option
  [@@deriving sexp]
end

val computation
  :  rows:int
  -> cols:int
  -> (Model.t * (Action.t -> unit Effect.t)) Computation.t
```

And `apple_state.ml` with the corresponding `Model` and `Action` modules:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=model_action -->
```ocaml
open! Core
open! Bonsai_web

module Model = struct
  type t =
    | Not_started
    | Placed of Apple.t
  [@@deriving sexp, equal]
end

module Action = struct
  type t =
    | Spawn of Snake.t option
    | Tick of Snake.t option
  [@@deriving sexp]
end
```

Once again, we'll implement `apply_action` one step at a time.
Note that as before, the `Snake.t` argument to these actions is a `Snake.t option`.
Since the snake spawns before the apple, it not existing should raise an exception.

Let's start with `Spawn`. Regardless of whether the apple is
placed or not placed, we'll spawn in a new apple, with the status `Playing`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=apply_action_spawn -->
```ocaml
let spawn ~rows ~cols snake =
  let invalid_pos = Snake.list_of_t snake in
  Model.Placed (Apple.spawn_random_exn ~rows ~cols ~invalid_pos)
;;

let apply_action ~rows ~cols ~inject:_ ~schedule_event:_ model action =
  match action, model with
  | Action.Spawn None, _ ->
    raise_s [%message "Invalid state: snake should be spawned before apple."]
  | Action.Spawn (Some snake), _ -> spawn ~rows ~cols snake
```

On `Tick`, if the apple is `Placed`, we respawn it if it has been eatten.
Otherwise, nothing happens:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=apply_action_tick -->
```ocaml
  | Tick None, Model.Placed _ ->
    raise_s [%message "Invalid state: apple initialized but not snake."]
  | Tick (Some snake), Model.Placed apple ->
    if Snake.is_eatting_apple snake apple then spawn ~rows ~cols snake else model
  | Tick _, Model.Not_started -> model
;;
```

> **Note** Instead of the apple checking whether it has been
> eatten on every tick, we could have had the snake dispatch an
> `Apple.Action.Spawn` using the `schedule_event` function in its
> `apply_action`. This would save the redundant check, but would
> force us to pass every apple's `inject` function to the Snake's
> `Move` action, which gets messy, fast.

And finally, we'll wrap things up in a `Bonsai.state_machine0`:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/apple_state.ml,part=computation -->
```ocaml
let computation ~rows ~cols =
  Bonsai.state_machine0
    [%here]
    (module Model)
    (module Action)
    ~default_model:Not_started
    ~apply_action:(apply_action ~rows ~cols)
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
let component ~rows ~cols player apple =
  let open Bonsai.Let_syntax in
  (* TODO: use `Attr.css_var` instead. *)
  let on_activate =
    Ui_effect.of_sync_fun
      (fun () ->
        set_style_property "--grid-rows" (Int.to_string rows);
        set_style_property "--grid-cols" (Int.to_string cols))
      ()
    |> Value.return
  in
  let%sub () = Bonsai.Edge.lifecycle ~on_activate () in
  let%arr player = player
  and apple = apple in
  let cell_style_driver =
    match player, apple with
    | Player_state.Model.Not_started, _ | _, Apple_state.Model.Not_started ->
      merge_cell_style_drivers ~snakes:[] ~apples:[]
    | Playing data, Placed apple | Game_over (data, _), Placed apple ->
      merge_cell_style_drivers ~snakes:[ data.snake ] ~apples:[ apple ]
  in
  Vdom.(
    Node.div
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
let view_score_status ~label player =
  let content =
    let open Vdom.Node in
    let score_text score = p [ textf "Score: %d" score ] in
    match player with
    | Player_state.Model.Not_started -> [ p [ text "Click to start!" ] ]
    | Playing data -> [ score_text data.score ]
    | Game_over (data, Out_of_bounds) ->
      [ p [ text "Game over... Out of bounds!" ]; score_text data.score ]
    | Game_over (data, Ate_self) ->
      [ p [ text "Game over... Ate self!" ]; score_text data.score ]
  in
  Vdom.(Node.div (Node.h3 [ Node.text label ] :: content))
;;
```

## Composing Everything Together

We've now implemented state machines for the player and apple,
and updated the board component to display them.
The last step is composing everything together in `App.component`.

## Exercises

- Switching direction from left->right, up->down, etc should be a no-op because it's an annoying way to die.
- Store (and display!) a high score in `Window.localStorage`. You'll need to use `Js_of_ocaml` directly.
