# Building a Static Todo List

Now that you're familiar with the starter code, let's start building our todo list!

For now, we want to display a static list of tasks, and make a space where
the "create task" form will eventually go. Here's what it will look like:

![chapter 1 result](img/1_result.png)

In this chapter, we'll:

- Define the data model for our Todo tasks, which will be used in both the frontend and backend.
- Create some simple, static components. Essentially, you'll learn how to write HTML and CSS in OCaml.
- Gently introduce the `let%sub` and `let%arr` operators, and the `Computation.t` and `Value.t` types, which are central to Bonsai.

We recommend pairing it with:

- The [Virtual_dom documentation](https://bonsai.red/01-virtual_dom.html)
- Bonsai's [guide to CSS and styling](https://bonsai.red/08-css.html)

## Defining Data Models

A to-do list is a web UI wrapper around displaying, creating, and editing tasks.
Before we can implement these (and other) features, we need to define what a task *is*.

In full-stack web development with separate frontends and backends, data typically lives
in a database such as PostgreSQL, MySQL, SqLite, or MongoDB. When the frontend wants to
get or change data, the backend will perform database queries, and return the results to
the frontend, as a serialized data structure. Because our frontend and backend are both in
OCaml, they can share the same data model!

A simple task should probably have a title, description, due date, and completion status.
So that's exactly what our model will look like! In `common`, create `task.ml` with the following
contents:

<!-- $MDX file=../../src/todo_list/1_static_components/common/task.ml -->
```ocaml
open! Core

module Completion_status = struct
  type t = Todo | Completed of Date.t [@@deriving sexp, bin_io, variants]
end

type t = {
  title : string;
  description : string;
  due_date : Date.t;
  completion_status : Completion_status.t;
}
[@@deriving sexp, bin_io, fields]
```

The `sexp` and `bin_io` ppx derivers allow our model to be serialized/deserialized
for testing and communication between the frontend/backend, respectively.
`fields` and `variants` provide some utils for accessing fields (or variant options)
of the data structure.

We could have represented `completion_status` as `Date.t option`, but defining a variant
is more descriptive, and could eventually support more statuses, such as "In Progress", or
"Procrastinating".

The corresponding `task.mli` should be pretty much identical:

<!-- $MDX file=../../src/todo_list/1_static_components/common/task.mli -->
```ocaml
open! Core

module Completion_status : sig
  type t = Todo | Completed of Date.t [@@deriving sexp, bin_io, variants]
end

type t = {
  title : string;
  description : string;
  due_date : Date.t;
  completion_status : Completion_status.t;
}
[@@deriving sexp, bin_io, fields]
```

## Static Components in Bonsai

Now, onto the Bonsai part!
For the bulk of this chapter, we'll:

- Introduce components and the core types of Bonsai.
- Implement the task list and create task placeholder components.
- Learn component composition, combining them into the screenshot you saw
  at the start of this chapter.

### What is a Component?

As mentioned in the [last article](./0_hello_world.md),

> Bonsai components are [incremental](https://blog.janestreet.com/introducing-incremental/)
computations, producing ["virtual" HTML](https://bonsai.red/00-introduction.html#the-underlying-machinery)
that's displayed in the browser.

If you're unfamiliar with Incremental, think of it as OCaml's Excel.
Cells can depend on other cells, and will only change when their dependencies change.
Bonsai has 2 key types that you should be aware of.

- `'a Value.t` is an incrementally computed value, or more accurately,
  a node in the incremental computation graph. You'll see it next chapter.
  Thinking in Excel, an `'a Value.t` is what we see in a cell: it may be a
  standalone variable, or it might be the output of some formula.
  It might also change over time, either if we edit the cell
  (for standalone variables), or if any inputs to the cell's formula change.
- `'a Computation.t` is a blueprint/formula for producing a Value.t.
  In our Excel analogy, a Computation.t is the formula we see when we double-click a cell.

The type of Bonsai "component" is `'a Computation.t`, or a function returning
`'a Computation.t`.

The components you're most used to are `Vdom.Node.t Computation.t`, which produce HTML.
But a component can produce anything; anything and everything can be incrementally
computed. This is part of what makes Bonsai so powerful.

See [this gist](https://gist.github.com/TyOverby/daf9a92db08d1c724f298bfb943f5a3e)
and [the Bonsai docs](https://bonsai.red/02-dynamism.html) for more background on Bonsai components.
You don't need to immediately understand all of it, but keep these analogies in mind
through the rest of this tutorial.

### Create Task Placeholder

We'll start with the "Create Task" section, since it's simple:
It will eventually be expanded into a working form, but for now
it's just a button that alerts "Not yet implemented" when pressed.

In `client`, create `create_task.mli` with the following content,
since we're just making one component that takes no inputs:

<!-- $MDX file=../../src/todo_list/1_static_components/client/create_task.mli -->
```ocaml
open! Core
open! Bonsai_web

val component : Vdom.Node.t Computation.t
```

You can compose and subdivide components as you wish (you'll learn how to soon),
but the convention of exporting one reusable component per module is a reasonable
one to follow. Now, onto the implementation!

Also in `client`, create `create_task.ml`, and start by adding the following module opens:

<!-- $MDX file=../../src/todo_list/1_static_components/client/create_task.ml,part=opens -->
```ocaml
open! Core
open! Bonsai_web
```

These will be standard in all Bonsai files; `Core` is an
[alternative standard library](https://opensource.janestreet.com/core/) for OCaml required by Bonsai,
and `Bonsai_web` gives us all the types we need to properly use Bonsai.
You should include them in all frontend code files.

Now, let's write some HTML in OCaml.
A full explanation, with many examples, can be found in [the Bonsai virtual_dom docs](https://bonsai.red/01-virtual_dom.html).
In summary:

> As a general rule, instead of `<tag attr="value">children</tag>` we'll use `tag_func ~attr:(attr_func attr_args) [child1; child2; ...]`.

So with that in mind, here's how we'll implement the create tasks section:

<!-- $MDX file=../../src/todo_list/1_static_components/client/create_task.ml,part=component_no_button -->
```ocaml
let view_create_tasks =
  Vdom.(
    Node.div [ Node.h2 [ Node.text "Create Tasks" ]; view_create_tasks_button ])

let component = Computation.return view_create_tasks
```

As with [hello world](./0_hello_world.md), we define a `Vdom.Node.t` instance, and wrap
it in a `Computation.t`.
You'll notice that `view_create_tasks_button` is undefined,
so let's implement that above `view_create_tasks`:

<!-- $MDX file=../../src/todo_list/1_static_components/client/create_task.ml,part=button_view -->
```ocaml
let alert s = Js_of_ocaml.Dom_html.window##alert (Js_of_ocaml.Js.string s)

let view_create_tasks_button =
  Vdom.(
    Node.button
      ~attr:
        (Attr.many
           [
             Attr.class_ Style.create_task_button;
             Attr.on_click (fun _e ->
                 alert "Not yet implemented.";
                 Ui_effect.Ignore);
           ])
      [ Node.text "Create Task" ])
```

This vdom looks a bit messier, but that's just because we need an extra wrapper function to
create vdom elements with multiple (`Attr.many`) attrs. We'll add `Style` in just a second.

Let's turn our attention to the `on_click` attr, which demonstrates how we can make things interactive.
The actual `alert` call is run as a side effect and ignored with a semicolon. However, there's a seemingly
random `Ui_effect.Ignore` returned at the end.
You can read more about it in the [Bonsai docs](https://bonsai.red/01-virtual_dom.html#unit-vdom.effect.t).
In summary, `Ui_effect` is used for safely scheduling state updates and some side effects, like RPC calls.
`alert` doesn't really need to be scheduled, so we use `Ui_effect.Ignore`, which is a no-op.

All that remains is styling.
The [Bonsai docs](https://bonsai.red/08-css.html) cover several options in depth.
We'll use `ppx_css`, which is the equivalent of [css in js](https://blog.logrocket.com/css-vs-css-in-js/)
for Bonsai.

It creates a module that loads our CSS into the document, and exposes class names we can use
in our components. One of our button's attributes is `Attr.class_ Style.create_task_button`.
This will apply all CSS with the class "create_task_button" to our button.
Let's write that CSS!

Add the following code above our component and view definitions:

<!-- $MDX file=../../src/todo_list/1_static_components/client/create_task.ml,part=style -->
```ocaml
module Style =
[%css.raw
{|
.create_task_button {
  font-size: 16px;
  padding: 8px 16px;
  border: 2px solid #CCCCCC;
  background-color: #CCCCCC;
}
.create_task_button:hover {
  border-color: #7a7a7a;
}
|}]
```

And with that, our code should now compile!
We've learned how to write HTML vdom in OCaml, wrap that in a `Computation.t`,
and attach custom styles.

Now let's do it all again!

### Task List


### Bringing It Together
