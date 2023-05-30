# Two Player Snake

In the [last chapter](./2_state_machines.md),
we built a working version of Snake using Bonsai's state machine design.

In this chapter, we'll showcase Bonsai's flexibility by adding
a second snake (controlled by the arrow keys) and more apples.

We'll dive deeper into computation composition,
what incrementality really means,
and how things are scheduled in Bonsai.

For simplicity, the snakes will be completely independent.
One player can continue even if the other's game has ended.
They'll also be allowed to overlap;
collision behavior is left as an exercise at the end of this chapter.
Apples, however, may not be placed on top of each other, or on top of snakes.

## The Challenge

There are two ways to provide external data to a Bonsai state machine's `apply_action` logic:

1. We can make it an input to the state machine with `state_machine1`.
   Last chapter, `Snake.t` was an input to `Apple_state.computation`.
2. We can pass it in the `Action.t` itself.
   For example, last time we passed `Apple.t` to `Player_state` through the `Move of Apple.t` action,
   and `Direction.t` through the `Change_direction of Direction.t` action.

To understand how these are functionally different,
we need to think a bit about how Bonsai's incrementality and event scheduling work together.

Let's dive in by examining the "tick" implementation from last chapter,
which dispatches `Move` and `Tick` actions to the player and apple on an interval.
Here's the code again:

<!-- $MDX file=../../src/snake_game/2_state_machines/src/app.ml,part=tick -->
```ocaml
  let%sub () =
    let%sub clock_effect =
      let%arr player_inject = player_inject
      and apple_inject = apple_inject
      and apple = apple in
      Effect.Many [ player_inject (Move apple); apple_inject Tick ]
    in
    Bonsai.Clock.every [%here] (Time_ns.Span.of_sec 0.25) clock_effect
  in
```

`clock_effect` is an incrementally computed `unit Effect.t Value.t`.
Remember than `unit Effect.t` is a task that we tell Bonsai to do.
`Value.t` is like a cell in a spreadsheet. When its inputs change,
the value it contains will change. Just a recap.

Anyways, every 0.25 seconds, `Bonsai.Clock.every` will
take the current value of `clock_effect`, which is a `unit Effect.t`,
and schedule that on the event-queue. Let's name this `curr_clock_effect`.

`curr_clock_effect` is **not** incremental. It's defined by:

<!-- $MDX skip -->
```ocaml
Effect.Many [ player_inject (Move apple); apple_inject Tick ]
```

Where `apple`, `apple_inject`, and `player_inject` are the values
of the corresponding `Value.t`s *at the time the effect was scheduled*.
That's the key detail: incrementality is not laziness.
`Value.t`s always contain some *regular OCaml value*,
and once if we take that value out, it's locked into place.

Let's take a look at a naive implementation of `clock_effect` for multiple apples and snakes:

<!-- $MDX skip -->
```ocaml
let%sub clock_effect =
  let%arr player1 = player1
  and player2 = player2
  and player1_inject = player1_inject
  and player2_inject = player2_inject
  and apple1 = apple1
  and apple2 = apple2
  and apple1_inject = apple1_inject
  and apple2_inject = apple2_inject
  in
  Effect.Many [
    player1_inject (Move ([player2], [apple1; apple2]));
    player2_inject (Move ([player1], [apple1; apple2]));
    apple1_inject (Move ([player1; player2], [apple2]));
    apple2_inject (Move ([player1; player2], [apple1]));
  ]
in
...
```

The behavior we would like to see is:

1. The `unit Effect.t` is queued, and eventually 
2. The first `player1_inject (Move ...)` effect is executed.
   As a result, the `player` model is changed.
3. The second `player2_inject (Move ...)` effect is executed.
   As a result, the `player` model is changed.
4. The `apple_inject (Move players)` effects are executed.
   where `players` are the **new, up-to-date** `Player_state` model.

But `player1` and `player2` are locked into place
when `clock_effect`was last incrementally adjusted,
befoe it was queued.

As a result, this implementati




###


In the [previous chapter](./2_state_machines.md#implementing-state),
there was an obvious dependency.
The apple needs to *always* know the snake's position,
since it spawns second, and needs to react to the snake's movement.

Here, things are trickier, since everything depends on everything else:

- Apples need to know where all the apples are, so they don't spawn on top of each other.
- Apples also need to know where all the snakes are, so that they can check if they've been eatten, and immediately respawn.
- Snakes need to know where all the apples are, so they 

## The Bug

A naive implementation of `reset_action` would look something like this:

<!-- $MDX skip -->
```ocaml
let%sub reset_action =
  let%arr player = player
  and player_inject = player_inject
  and apple_inject = apple_inject in
  Effect.Many [
    player_inject Restart;
    apple_inject (Spawn player.snake)
  ]
in
...
```

This looks very reasonable!
When the game is reset, the player state machine receives `Restart`,
and then the apple state machine receives `Spawn` with the new `player.snake`
parameter, so that it doesn't spawn somewhere that's already occupied by the snake.
What's the issue?

The problematic phrase is **the new `player.snake`**.
`reset_action` is an incremental computation that depends on `player`,
`player_inject`, and `apple_inject`.
However, the two `unit Effect.t`s it combines via `Effect.Many`
are **not independently incremental**.

The behavior we would like to see is:

0. The `unit Effect.t` is popped off Bonsai's event-queue.
1. The first `player_inject Restart` effect is executed.
   As a result, the `player` model is changed.
2. The second `player_inject (Spawn player.snake)` effect is executed,
   where `player` is the **new, up-to-date** `Player_state` model.

But that's not how incremental computations work!
Incrementality is not laziness.
You can think of an incremental computation as
closing over

## Exercises

- Define behavior if snakes collide
  - Maybe the larger one wins?
  - Or the one with a higher score?
  - Or the one that crashed loses?
  - Maybe they don't affect each other?
  - Or something else?
  - Hints
    - You'll need to implement a way to get all other players from a `Game_elements.t`. Note that just deriving a `Player_state.equal` alone might not be sufficie if snakes can have length 1, since . For example, if snakes can have length 1, 2 snakes could have the same color and location, but belong to different players.
- Add more apples, with different behaviors?
  - Hints
    - Define an "apple type" variant that determines appearance and effect on snake when eatten
- Add a form that controls grid size, how many apples, etc?
  - Start by converting rows, cols, and num_snakes to `Value.t`
  - https://github.com/TyOverby/composition-comparison#04---multiplicity
- Add one (or multiple!) AI-powered snakes!
  - Hints
    - Create a new `AI_player` computation that wraps `Player_state.computation`. On `Move`, dispatch `Change_direction` (if necessary) and `Move` to internal Player_state.
