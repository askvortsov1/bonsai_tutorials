# Snake Game: Hello World!

Welcome to the `snake_game` Bonsai tutorial!
Over several chapters, you'll recreate the classic game [Snake](https://en.wikipedia.org/wiki/Snake_(video_game_genre))
as a Bonsai web app, in OCaml.

You'll learn how to design and build stateful, interactive Bonsai web apps with multiple moving parts.

We recommend doing at least chapters 0 and 1 of the `todo_list` tutorial before starting this one.
They teach the basic structure of Bonsai projects, and how to build, style, and compose simple components.

In this chapter, we'll cover:

- How to run the tutorial code
- What the starter code does
- A high-level design of Snake
- What the other chapters of this tutorial will entail

We recommend pairing it with:

- The [Bonsai explanation introduction](https://bonsai.red/00-introduction.html)
- This [OCaml snake exercise](https://github.com/janestreet/learn-ocaml-workshop/tree/master/03-snake),
  which implements the core logic for Snake, as a desktop app using [Graphics](https://github.com/ocaml/graphics).

## Running the Tutorial

You'll write code in the `workbench/snake_list` directory, but terminal commands will be run
from the root of this "tutorials" library.

As you work through this tutorial, you should frequently build and re-run the application
to see your changes come to life. Consider using `dune build -w`.

Before you start, install all dependencies:

<!-- $MDX skip -->
```sh
opam install workbench/snake_game
```

And to build the app in watch mode, run:

<!-- $MDX skip -->
```sh
dune build -w
```

To access the web app, all you need to do is open [_build/default/workbench/snake_game/index.html](../../_build/default/workbench/snake_game/index.html).
to build and run your code. Then, all you need to do is go to [http://localhost:8080](http://localhost:8080) in your browser!

At this point, all you should see is a "Hello world! message.

> **Note** In `todo_list`, we ran a web server executable, which dynamically served HTML.
> Here, we don't need a server, so we can just open a static HTML file that includes the
> built JS.

## Starter Code Structure

The frontend code is pretty much the same as `todo_list`'s "Hello World" frontend.
See the `todo_list` chapter 0 (specifically the Bonsai part) for a refresher on
how "hello world" in Bonsai works.

## Snake Design

Unlike `todo_list`, which is about as straightforward a CRUD app as it gets,
`snake_game` presents us with some design decisions.
In addition to building Snake in Bonsai, we need to, well, build Snake.

The rest of this chapter gives a brief overview of how we'll design Snake.
If you've never done this before, I encourage you to spend some time
thinking about potential designs before reading further.

### High-Level Behavior

I'll refer to snakes and apples as "game elements" for brevity.

The game should start (or reset and restart) when the user
clicks anywhere on the screen. When this happens, all game elements
should spawn in random positions on the board.
Importantly, game elements should never spawn on top of each other.
Any metadata relating to status or score should also be reset.

We also need a way for players to control the snake.
If the game is running, when the "W", "A", "S", or "D" keys are pressed,
a snake's direction will change to "Up", "Left", "Down", or "Right" respectively.
Other keys can also be used if multiple snakes are present.

This leaves the "game loop" logic. Every `x` time,
the following sequence of events should happen:

- All snakes move forward one step in their current direction.
- If a snake is eatting itself, or has collided with a wall:
  - The game should end.
- If a snake is eatting an apple:
  - It will grow by one unit, *eventually*. We don't want to immediately grow
    snakes, since it isn't obvious where the new length should grow. Instead,
    when growing snakes move, their head will move forward one step, but the tail will stay in place.
  - The score should increase.
- All apples that have been eatten by a snake should respawn.

We deliberately don't define behavior when snakes collide with other snakes.
This is left as an exercise at the end of the tutorial.

### Snake and Apple Implementation

What about the data structures for our game elements' implementations?

To represent an apple, we just need to know its row/column coordinates. That's easy.

Snakes are a little trickier: they occupy more than one cell, so we'll need a collection data structure.
We also need to know which cell is the head, and would like something that makes moving the snake simple.
The perfect fit here is a linked list, so a `Position.t list`.
This also makes logic simple: to move the snake forward, just push a new element to the front of the list.
If the snake is growing, that's all we need to do. Otherwise, we just drop the last position coordinate in the list.

The actual type for snake is going to be a record that includes such a position linked list, as well as growth
metadata, color, etc.

### Display and Interactivity Implementation

How will we display all of this, and allow the user to interact with our game?

We'll talk more about browsers and UIs later, but essentially, we'll display the game grid
with a bunch of HTML divs styled via CSS grid. Cells occipied by snakes and apples will have
colored backgrounds to indicate the position of game elements on the board.
As states update, Bonsai will incrementally recalculate our display vdom,
updating the displayed board.

There will also be some other content displayed via HTML vdom, such as instructions and scores.

As for the interaction part, we'll make our a root "app" HTML div take up the whole page,
and add `onclick` and `onkeydown` event listeners.
We could listen on `document`, but that forces us to work with
[js_of_ocaml](http://ocsigen.org/js_of_ocaml/latest/manual/overview) bindings directly,
and doesn't give us effect-based event handlers like
[Virtual_dom](https://bonsai.red/01-virtual_dom.html#unit-vdom.effect.t) does.

## Tutorial Plan

In the [next chapter](./1_display_and_types.md), we'll define types and implement some basic building
blocks of our game: position/direction, snake, apple, and game status.
This allows us to implement the `Board` component, which will display the game.

[After that](./2_state_machines.md), we'll build the stateful components needed for our game.

[Finally](./3_two_player_snake.md), we'll showcase the composability of state in Bonsai by adding a second
snake (and player!) to the game. We'll end the tutorial with some suggested exercises
to further extend the game.
