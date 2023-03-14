# Implementing State

In the [last chapter](1_display_and_types.md), we implemented types and logic for
building blocks like `Snake.t`, `Apple.t`, and `Player_status.t`.
We then built `Board.component`, which renders the game into Vdom.

In this chapter, we'll bundle those building blocks in Bonsai state machines,
finally creating a dynamic, working system.

We'll also implement user controls, so that the snake game can actually be played.

By the end of this chapter, you'll have a working single-player version of Snake!

## Player State

## Apple State

## Composing Everything Together

## Exercises

- Switching direction from left->right, up->down, etc should be a no-op because it's an annoying way to die.
- Store (and display!) a high score in `Window.localStorage`. You'll need to use `Js_of_ocaml` directly.
