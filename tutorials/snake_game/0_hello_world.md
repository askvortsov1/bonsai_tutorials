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

...

## Tutorial Plan

In the next chapter, we'll define types and implement some basic building
blocks of our game: position/direction, snake, apple, and game status.
This allows us to implement the `Board` component, which will display the game.

After that, we'll build the stateful components needed for our game.

Finally, we'll showcase the composability of state in Bonsai by adding a second
snake (and player!) to the game. We'll end the tutorial with some suggested exercises
to further extend the game.
