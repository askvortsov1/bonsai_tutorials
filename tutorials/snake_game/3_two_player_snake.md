# Two Player Snake

Now that we've built a working version of Snake, let's showcase Bonsai's flexibility by adding
a second snake, controlled by the arrow keys.

...



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
- Add one (or multiple!) AI-powered snakes!
  - Hints
    - Create a new `AI_player` computation that wraps `Player_state.computation`. On `Move`, dispatch `Change_direction` (if necessary) and `Move` to internal Player_state.
