# Displaying a (Static) Board

In the [last chapter](./0_hello_world.md), we saw how to build and access our
web app, and went over a high-level design of Snake.

In this chapter, we'll design (.mlis) and implement functions for the base types that
our Snake implementation will be based around:

- `Position.t` and `Direction.t`, which represent coordinates and directions on the game grid, respectively.
- `Apple.t`, a type encapsulating the position of the apple, and functions to spawn a new apple.
- `Snake.t`, which encapsulates the positions and growth state of the snake, and functions for
  getting the positions, checking whether it has eatten itself, spawning new snakes, etc.

We'll also implement `Board.component`, which renders the game into HTML Vdom, as a function
of the current state.

By the end of this chapter, our game will look like this:

![chapter 1 result](img/1_result.png)

It won't work *quite* yet; that will happen in the next chapter, when we implement interactivity
and state transitions using Bonsai's state primitives.

## Types and Logic

At the end of the day, Bonsai's incremental computation and state transition tools wrap "raw" OCaml types and values.
The core types behind any Bonsai app are plain old records, variants, options, etc.

Similarly, in the next chapter, we'll write "Bonsai-ey" code that determines state transitions, component composition, and interactivity.
But this logic can be implemented in terms of simpler helper functions operating on those "raw" OCaml types.

All these types will use the `sexp` and `equal` PPXs, since we'll eventually use them in state machines,
and Bonsai requires that state models derive `sexp` and `equal`.

### Direction.t

We need a `Direction.t` type to keep track of the snake's direction.
This will just be a simple variant consisting of "Up", "Down", "Left, "Right".
Create a `direction.mli` file with the following content:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/direction.mli -->
```ocaml
open! Core

(** A [t] represents a direction on the playing board. *)
type t =
  | Up
  | Down
  | Right
  | Left
[@@deriving sexp, equal]
```

The `direction.ml` implementation will be identical:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/direction.ml -->
```ocaml
open! Core

type t =
  | Up
  | Down
  | Right
  | Left
[@@deriving sexp, equal]
```

### Position.t

Snake is played on a `rows`x`cols` grid; the locations of snakes and apples will be described in terms of `(row, col)` coordinates.
We'll represent these coordinates as `Position.t`, which is just a record that contains a row and a column.
There's a few advantages to creating this wrapping type:

- We can automatically derive functions for sexp encoding/decoding and equality.
- We can use `Position.t` in type signatures, which is more concise and informative.

We'll also implement some helper functions:

- `step` returns the new position after taking a step in `dir` from a starting position.
- `random_pos` returns a random position on the `rows`x`cols` grid,
  excluding some list of `invalid_pos`. This will be used to randomly spawn snakes and apples,
  while making sure that we don't spawn overlapping entities.

Create a `position.mli` with the following content:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/position.mli -->
```ocaml
open! Core

(** A [t] represents a square on the playing area, identified by its row and
    column. *)
type t =
  { col : int
  ; row : int
  }
[@@deriving equal, sexp]

(** [step t dir] returns the next position after taking a step in
    [dir] from [t]. *)
val step : t -> Direction.t -> t

(** [random_pos ~rows ~cols ~invalid_pos] returns a random [t] with
    [t.row < rows] and [t.col < cols], which is not in [invalid_pos]. *)
val random_pos : rows:int -> cols:int -> invalid_pos:t list -> t option
```

Then, for the implementation, create `position.ml`, and add the same type:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/position.ml,part=type -->
```ocaml
open! Core

type t =
  { col : int
  ; row : int
  }
[@@deriving equal, sexp]
```

The `step` implementation is very straightforward:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/position.ml,part=step -->
```ocaml
let step { row; col } dir =
  match dir with
  | Direction.Left -> { row; col = col - 1 }
  | Right -> { row; col = col + 1 }
  | Up -> { row = row - 1; col }
  | Down -> { row = row + 1; col }
;;
```

Note that the position `{row = 0; col = 0}` represents the top left corner of the grid,
as is typical when describing 2-dimensional arrays.

To implement `random_pos`, we generate all rows and columns in the grid,
filter out the ones in `invalid_pos`, and return them as `Position.t`s:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/position.ml,part=random -->
```ocaml
let random_pos ~rows ~cols ~invalid_pos =
  let valid_pos =
    List.init rows ~f:(fun row -> List.init cols ~f:(fun col -> { row; col }))
    |> List.concat
    |> List.filter ~f:(fun x -> not (List.mem ~equal invalid_pos x))
  in
  if List.is_empty valid_pos
  then None
  else (
    let n = Random.int (List.length valid_pos) in
    List.nth valid_pos n)
;;
```

Some improvements to this implementation are left as exercises at the end of this
chapter.

### Apple.t

Let's implement the first of our "more interesting" types: `Apple.t`.
An `Apple.t` represents an apple placed somewhere on the board.
We'll also define several helper functions for spawning and displaying `Apple.t`s:

- `list_of_t`, which returns a list of `Position.t`s occupied by the apple.
- `spawn_random_exn`, which spawns an apple somewhere on a `rows`x`cols` game board
- `cell_style`, which returns a [Css_gen.t](http://bonsai.red/08-css.html)
  if the given game grid cell is occupied by the apple, and `None` otherwise.
  We'll use this later in the `Board` component: essentially, we'll run each cell's
  coordinates through `cell_style` for every snake and apple to determine what it should look like.

With all this in mind, create `apple.mli`, and add the following contents:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/apple.mli -->
```ocaml
open! Core

(** A [t] represents an apple placed on the grid. *)
type t [@@deriving sexp, equal]

(** [list_of_t t] returns a list of positions occupied by the apple. *)
val list_of_t : t -> Position.t list

(** [spawn_random_exn ~rows ~cols ~invalid_pos] creates an apple placed randomly
   on a rows*cols grid; excluding cells in ~invalid_pos. *)
val spawn_random_exn : rows:int -> cols:int -> invalid_pos:Position.t list -> t

(** [cell_style t pos] computes a [Css_gen.t] style for a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_style : t -> Position.t -> Css_gen.t option
```

To keep this tutorial simple, all apples will be `1x1` cell, red squares.
So an `Apple.t` is just a `Position.t` in disguise.
With that in mind, the implementation should be straightforward:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/apple.ml -->
```ocaml
open! Core

type t = Position.t [@@deriving sexp, equal]

let list_of_t t = [ t ]

let spawn_random_exn ~rows ~cols ~invalid_pos =
  Position.random_pos ~rows ~cols ~invalid_pos |> Option.value_exn
;;

let cell_style a pos =
  if Position.equal a pos then Some (Css_gen.background_color (`Name "red")) else None
;;
```

> **Note** In our implementation, `Apple.t` is just an alias for `Position.t`.
That doesn't *have* to be the case though: there's nothing preventing you from building a variant
of snake where apples are 2x2 squares, or some other wacky shape.
To allow future maintainers of OSnake 3000++# this flexibility, we use an
[abstract type](https://dev.realworldocaml.org/files-modules-and-programs.html#scrollNav-3).

### Snake.t

All we want to do in this chapter is display a static snake and apple on the game board.
The `mli` interface for Snake will be nearly identical to that of `Apple`.
Create `snake.mli` with the following contents:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/snake.mli -->
```ocaml
open! Core

(** A [t] represents a snake, which keeps track of how much it
    has left to grow. *)
type t [@@deriving sexp, equal]

(** [list_of_t t] returns a list of [Position.t]s occupied by the snake. *)
val list_of_t : t -> Position.t list

(** [spawn_random_exn ~rows ~cols ~invalid_pos ~color] creates a length-1 snake
    placed randomly on the left half ([col < cols/2]) of a rows*cols grid.
    The provided color will be used in calls to [cell_style]. *)
val spawn_random_exn
  :  rows:int
  -> cols:int
  -> invalid_pos:Position.t list
  -> color:Css_gen.Color.t
  -> t

(** [cell_style t pos] computes a [Css_gen.t] style for a cell at [pos], if
    that cell is occupied by t. Otherwise, it returns [None] *)
val cell_style : t -> Position.t -> Css_gen.t option
```

The difference is in the implementation. `Apple.t`s occupy single `Position.t`s, while
a `Snake.t`s is a [Position.t list](0_hello_world.md#snake-and-apple-implementation).
However, that's not all a `Snake.t` needs to keep track of.
Since we'll eventually have multiple snakes, each should have a different color so
we can tell them apart. Also, we'll eventually need to store metadata about
how much the snake has left to grow.

The `color` field will be used to generate CSS for snake cells on the game grid,
so we represent it as a `Css_gen.Color.t`. This causes a slight issue:
as mentioned before, all these types need to PPX-derive `sexp` and `equal`
so they can be used as Bonsai state machine models. But `Css_gen.Color` doesn't
include an `equal` function. To get around this, we'll create a small module
that includes `Css_gen.Color`, and defines `equal` in terms of `Css_gen.Color.compare`.

The other thing we should think about is spawning the snake.
It wouldn't be fun if the snake immediately ran into the wall
right after the game started.
To keep this simple, we'll just spawn a one-cell snake on the left side of
the board (i.e. cols = cols/2), facing right.
Support for spawning longer snakes with random directions is left as an exercise
at the end of this chapter.

With all that in mind, create `snake.ml` with the following contents:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/snake.ml -->
```ocaml
open! Core

module Color = struct
  include Css_gen.Color

  let equal a b = Css_gen.Color.compare a b |> Int.equal 0
end

type t =
  { pos : Position.t list
  ; direction : Direction.t
  ; color : Color.t
  }
[@@deriving sexp, equal]

let list_of_t s = s.pos

let spawn_random_exn ~rows ~cols ~invalid_pos ~color =
  let head = Position.random_pos ~rows ~cols:(cols / 2) ~invalid_pos in
  let head_exn = Option.value_exn head in
  { pos = [ head_exn ]; color; direction = Direction.Right }
;;

let cell_style s pos =
  if List.mem (list_of_t s) pos ~equal:Position.equal
  then Some (Css_gen.background_color s.color)
  else None
;;
```

And that's that! Now, let's put all of these onto a screen.

## Displaying the Board

> **Note** If you haven't yet done so, you should complete chapters [0](../todo_list/0_hello_world.md)
> and [especially 1](../todo_list/1_static_components.md) of the todo_list tutorial to learn about
> Bonsai components, computations, values, virtual dom, and style.
> Or at least skim them. It's quick, I promise!

V1 of our board component is a Bonsai computation that takes:

- the row/grid dimensions (since we need to render the board)
- an incrementally computed `Snake.t`
- an incrementally computed `Apple.t`

Create `board.mli` with the following contents:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/board.mli -->
```ocaml
open! Core
open! Bonsai_web

val component
  :  rows:int
  -> cols:int
  -> Snake.t Value.t
  -> Apple.t Value.t
  -> Vdom.Node.t Computation.t
```

So, how do we implement this?

There's quite a few ways to display a game in the browser:

- Use regular old HTML DOM elements with some styling
- Draw on a [HTML5 Canvas](https://www.w3schools.com/graphics/canvas_intro.asp) via Canvas2D
- Render [3D graphics with WebGL](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/Tutorial/Getting_started_with_WebGL)
- Go back in time and use [Adobe Flash](https://www.adobe.com/products/flashplayer/end-of-life-alternative.html).
  Is that a remotely good solution? Absolutely not. Did I list it anyway because of coolmathgames nostalgia? *maybe*. Moving on...

The [`Virtual_dom` library](https://github.com/janestreet/virtual_dom) lets Bonsai
incrementally compute DOM in a clean, declarative style.
As of writing this post, no one has built a similar library for Canvas2D or WebGL.
That doesn't mean it's not possible! For example, see
[this demo](https://twitter.com/tyroverby/status/1597057701288476672) of a prototype
for Bonsai running natively via an [OpenGL wrapper](https://github.com/let-def/wall).

Anyways, for now we'll be using a simple DOM layout, but keep posted for a possible
"Vector Graphics with Bonsai" tutorial in a few years.

### Styling the Grid

The simplest way to display the snake game grid is with, well, a grid.
Then, the color of each cell will depend on whether the cell is occupied by
a snake, an apple, or nothing at all.

We'll implement this by arranging (`rows`x`cols`) HTML `div` elements using
[CSS grid](https://css-tricks.com/snippets/css/complete-guide-grid/).
Happily, we can use CSS variables to allow for a dynamic grid size.

Create a `board.ml` file, and add the following CSS:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/board.ml,part=style -->
```ocaml
open! Core
open! Bonsai_web

module Style =
[%css.raw
{|
.grid {
  width: 600px;
  height: 600px;
  display: grid;
  grid-template-rows: repeat(var(--grid-rows), 1fr);
  grid-template-columns: repeat(var(--grid-cols), 1fr);
  border: 5px solid gray;
}
|}]
```

Now, how do we style the individual cells?
Recall that in `Apple` and `Snake`, we defined `cell_style` functions
that return a [`Css_gen.t option`](http://bonsai.red/08-css.html), depending on
whether that cell is occupied by a given snake or apple.
In our simple implementation, those functions decorated occupied cells with a solid color background.

To style a given cell, we'll run its coordinates through all these `cell_style` driver functions,
returning as soon as one doesn't return `None`. If none match, the cell must be empty,
so we fall back to a plain white cell with a thin border to help visualize the game grid.

Add the following code to `board.ml`:

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/board.ml,part=style_drivers -->
```ocaml
let empty_cell_style =
  Css_gen.(
    background_color (`Name "white")
    @> border ~width:(`Px 1) ~color:(`Name "gray") ~style:`Solid ())
;;

let merge_cell_style_drivers ~snakes ~apples =
  let drivers =
    List.join [ List.map snakes ~f:Snake.cell_style; List.map apples ~f:Apple.cell_style ]
  in
  fun pos ->
    match List.find_map drivers ~f:(fun driver -> driver pos) with
    | Some x -> x
    | None -> empty_cell_style
;;
```

### Game Grid Vdom

And with these building blocks, implementing a `view_game_grid` function should be trivial.
All we need to do is generate `rows`x`cols` HTML `<div />` elements, run each of them
through the merged cell driver, and apply the grid CSS classes from before.
This is a nice example of how the [`ppx_css` and `Css_gen` styling strategies](http://bonsai.red/08-css.html)
can be used together.

Add the following implementation to `board.ml`, after the style module and cell style drivers.

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/board.ml,part=board_view -->
```ocaml
let view_game_grid rows cols cell_style_driver =
  let cells =
    List.init rows ~f:(fun row ->
      List.init cols ~f:(fun col ->
        let pos = { Position.row; col } in
        let style = cell_style_driver pos in
        Vdom.(Node.div ~attr:(Attr.style style) [])))
    |> List.concat
  in
  Vdom.(Node.div ~attr:(Attr.class_ Style.grid) cells)
;;
```

### The Board Component

With these building blocks, we can implement the actual Bonsai component,
as defined in the `.mli`. Essentially, we need to:

- Use `let%arr` to unwrap the `Snake.t Value.t` and `Apple.t Value.t` inputs.
- Pass those to `merge_cell_style_drivers`, creating a full cell style driver
- Use that to generate VDOM for the game grid via `view_game_grid
- Return that game grid vdom, along with some instructions / other page content.

Add the following implementation of `component` at the bottom of `board.ml

<!-- $MDX file=../../src/snake_game/1_display_and_types/src/board.ml,part=component -->
```ocaml
let set_style_property key value =
  let open Js_of_ocaml in
  let priority = Js.undefined in
  let res =
    Dom_html.document##.documentElement##.style##setProperty
      (Js.string key)
      (Js.string value)
      priority
  in
  ignore res
;;

let component ~rows ~cols snake apple =
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
  let%arr snake = snake
  and apple = apple in
  let cell_style_driver = merge_cell_style_drivers ~snakes:[ snake ] ~apples:[ apple ] in
  Vdom.(
    Node.div
      [ Node.h1 [ Node.text "Snake Game" ]
      ; Node.p [ Node.text "Click anywhere to reset." ]
      ; view_game_grid rows cols cell_style_driver
      ])
;;
```

### Bringing It All Together

Finally, our last step is replacing the "hello world" code in
`app.ml` with a component that spawns a snake and apple, and
passes them to `Board.component`, ultimately computing vdom
that displays a static frame of Snake.

Replace `app.ml` with the following code:


<!-- $MDX file=../../src/snake_game/1_display_and_types/src/app.ml -->
```ocaml
open! Core
open! Bonsai_web

let rows = 20
let cols = 20

let component =
  let snake = Snake.spawn_random_exn ~rows ~cols ~invalid_pos:[] ~color:(`Name "green") in
  let apple = Apple.spawn_random_exn ~rows ~cols ~invalid_pos:(Snake.list_of_t snake) in
  Board.component ~rows ~cols (Value.return snake) (Value.return apple)
;;
```

And we're done! If you build and open the game in your browser,
you should see something quite similar to the image at the start of this chapter.

In the [next chapter](2_state_machines.md), you'll learn how to build state machines
in Bonsai, and implement a working 1-player version of Snake.

## Exercises

### More Efficient `random_pos`

Currently, calling `random_pos` with `r` rows, `c` columns, and `n` `invalid_pos`s will
take O(rcn) time. Can you make this faster?

<details>
  <summary>Hint</summary>

   > Create a `Position.t Set.t` at the start of `random_pos`, and use that for lookups.
   This is a bit tricky, because you'll need to call `Set.Make(M)`, but type `t` is defined
   in the same scope, and we can't reference the `Position` module from itself.
   Wrap the `type t` declaration and its ppx derivers in another module, and `include` that
   into the `Position` top scope, then use your new temp module to make the set.
</details>

### Improve Spawning Algorithm

To keep things simple, new snakes are generated with length 1, always facing to the right,
on the left side of the board. Can you expand this to generate longer snakes, which can start
facing any direction?

<details>
  <summary>Hint</summary>

  > Start by randomly selecting a direction. Then, restrict `rows` and `cols` to the first
  half of the board in that direction. For example, snakes facing down should start
  in the top half. Then, extend `random_pos` with `length` and `dir` parameters.
  It should check that `length` blocks in the `dir` direction all aren't in `invalid_pos`.
</details>

### Improve Page Layout

We've kept the page layout and CSS very bare-bones for simplicity.
To practice your top-notch Bonsai design skills, try making the page nicer!
Some ideas:

- Add instructions
- Add a background image to the grid
- Center the game board in the middle of the page

### Fancier Snakes

Currently, each "segment" of a snake is just a solid-background cell.
Try making the snake's head a different color, or even better, stylizing the segments
with images.
