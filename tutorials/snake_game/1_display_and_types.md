# Displaying a (Static) Board

In the [last chapter](./0_hello_world.md), we saw how to build and access our
web app, and went over a high-level design of Snake.

In this chapter, we'll design (.mlis) and implement functions for the base types that
our Snake implementation will be based around:

- `Position.t` and `Direction.t`, which represent coordinates and directions on the game grid, respectively.
- `Apple.t`, a type encapsulating the position of the apple, and functions to spawn a new apple.
- `Player_status.t`, which represents whether the game is in progress or inactive, and if applicable, why the game ended.
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

### Player_status.t

### Apple.t

### Snake.t

## Displaying the Board

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
- Create a border around the grid, and a background behind it
- Center the game board in the middle of the page

### Fancier Snakes

Currently, each "segment" of a snake is just a solid-background cell.
Try making the snake's head a different color, or even better, stylizing the segments
with images. For reference, here's the
[docs for the CSS "background"](https://www.w3schools.com/cssref/css3_pr_background.php) property.
