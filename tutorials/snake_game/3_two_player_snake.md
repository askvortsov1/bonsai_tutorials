# Two Player Snake

Now that we've built a working version of Snake, let's showcase Bonsai's flexibility by adding
a second snake, controlled by the arrow keys.

...

## Exercises

- Define behavior if snakes collide
  - Maybe the larger one wins?
  - Or the one with a higher score?
  - Or the one that crashed loses?
  - Maybe they don't affect each other?
  - Or something else?
  - Hints
    - You'll need to implement a way to get all other players from a `Game_elements.t`. Note that just deriving a `Player.equal` alone might not be sufficie if snakes can have length 1, since . For example, if snakes can have length 1, 2 snakes could have the same color and location, but belong to different players.
- Add more apples, with different behaviors?
  - Hints
    - Define an "apple type" variant that determines appearance and effect on snake when eatten
- Add a form that controls grid size, how many apples, etc?
- Add one (or multiple!) AI-powered snakes!
  - Hints
    - Create a new `AI_player` computation that wraps `Player.computation`. On `Move`, dispatch `Change_direction` (if necessary) and `Move` to internal player.
