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
- Add more apples, with different behaviors?
  - Hints
    - Define an "apple type" variant that determines appearance and effect on snake when eatten
- Add a form that controls grid size, how many apples, etc?
- Add one (or multiple!) AI-powered snakes!
  - Hints
    - Create a new `AI_snake` computation that wraps `Snake.computation`. On `Move`, dispatch `Change_direction` (if necessary) and `Move` to internal snake.
