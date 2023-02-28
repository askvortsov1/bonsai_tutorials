# Todo List: Hello World!

Welcome to the `todo_list` Bonsai tutorial!
Over several chapters, you'll build a full-stack todo list application entirely in OCaml.
We'll focus on how to design and write Bonsai components, and how to use Bonsai's tools and primitives.
However, chapter 2 will walk you through implementing the RPC protocol and backend implementation.

In this chapter, we'll cover:

- How to run the tutorial code
- What the starter code does

We recommend pairing it with:

- The [Bonsai explanation introduction](https://bonsai.red/00-introduction.html)

## Running the Tutorial

You'll write code in the `workbench/todo_list` directory, but terminal commands will be run
from the root of this "tutorials" library.

As you work through this tutorial, you should frequently build and re-run the application
to see your changes come to life. 

Before you start, install all dependencies:

<!-- $MDX skip -->
```sh
$ opam install workbench/todo_list
```

Then, when you've made changes, you can run:

<!-- $MDX skip -->
```sh
$ dune build
$ ./_build/default/workbench/todo_list/server/bin/main.exe
```

to build and run your code. Then, all you need to do is go to http://localhost:8080 in your browser!

At this point, all you should see is a "Hello world! message. Let's discuss how it works.

## Starter Code Structure

Most chapters of this tutorial will have you writing code.
Since we've given you a bunch of starter code, we wanted to explain it before we jump in.
If you've worked on full-stack OCaml projects before, you probably already know most of this.

We'll start by explaining the starter code's directory structure:

- `todo_list.opam`, `dune-project`: these declare that our workbench is a self-contained project, allowing it to be built.
- `common`: this directory will eventually contain type definitions and RPC protocol specifications that will be shared by the frontend and backend.
- `server`: this directory contains backend code, split into 2 parts:
  - `src`: this is the source code for our backend, exposed as a `Command`
  - `bin`: this wraps the server from `src` into a binary. That's what we run to launch the site.
- `client`: this is where we'll build our Bonsai web app.

## The Backend

> **Note**
> Most of this is self-explanatory boilerplate, so feel free to skip/skim it, and go straight to the Bonsai part.

The goal of these tutorials is to teach you how to write Bonsai. However, frontend web UIs generally don't exist in a vacuum.
There's often a backend server that we want to communicate with; in our case, through RPC calls.
Also, web apps need to be served from somewhere, although that could be done as static files.
For an example of that, see the `snake_game` tutorial.

This project's server will have 2 jobs:

1. Serving content. This includes:
   1. HTML for the todo page, and for a "404 not found" page
   2. Static JS/CSS files, which Bonsai will compile from our frontend code.
2. Handling RPC requests from the frontend.

We'll implement (2) in chapter 2. For now, we'll see how (1) is implemented.

Let's start with the `mli`:

<!-- $MDX file=../../src/todo_list/0_hello_world/server/src/server.mli -->
```ocaml
open! Core

val command : Command.t
```

As mentioned previously, we'll package the logic for our server in a [`Core.command`](https://ocaml.org/p/core/v0.15.0/doc/Core/Command/index.html),
which in turn becomes the binary we've been using to run the server. Indeed, the entire source code of `server/bin` is:

<!-- $MDX file=../../src/todo_list/0_hello_world/server/bin/main.ml -->
```ocaml
open! Core

let () = Command_unix.run Server.command
```

Simple. Now, let's check out how `Server.command` is implemented.

### Server HTTP Logic

The core of our backend logic is the http handler function, which takes a `Cohttp.Request.t`, and returns a `Cohttp_async.Server.Response.t`:


<!-- $MDX file=../../src/todo_list/0_hello_world/server/src/server.ml,part=handler -->
```ocaml
let respond_string ~content_type ?flush ?headers ?status s =
  let headers = Cohttp.Header.add_opt headers "Content-Type" content_type in
  Cohttp_async.Server.respond_string ?flush ~headers ?status s

let handler ~body:_ _inet req =
  let path = Uri.path (Cohttp.Request.uri req) in
  match path with
  | "" | "/" | "/index.html" -> respond_string ~content_type:"text/html" html
  | "/main.js" ->
      respond_string ~content_type:"application/javascript"
        Embedded_files.main_dot_bc_dot_js
  | _ ->
      respond_string ~content_type:"text/html" ~status:`Not_found not_found_html
```

The interesting branch here is `"/main.js"`. As part of our web app's build process, our Bonsai frontend, is compiled into JS by `js_of_ocaml`, and made available to our backend via [ocaml-embed-file](https://opam.ocaml.org/packages/ocaml-embed-file/). See the [server dune file](../../src/todo_list/0_hello_world/server/src/dune) to see how this is done. The JS file's contents are then wrapped in the `Response` type by `respond_string`.

The `"" | "/" | "/index.html` and catch-all 404 paths work similarly.
Since all of the appearance, style, and functionality of our frontend will be defined in Bonsai,
all we need to do in the server-generated HTML is pull in the JS file, and define a root element
where Bonsai will "attach" itself. You'll see how this works in the next section.

<!-- $MDX file=../../src/todo_list/0_hello_world/server/src/server.ml,part=index_html -->
```ocaml
let html =
  {|
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <script defer src="main.js"></script>
    <title> TODO-List </title>
  </head>

  <body>
    <div id="app"></div>
  </body>
</html>
|}
```

### Serving the Handler

Now that we've written our HTTP handling logic, we need to get it to run.
To do this, we'll use the [`Async_rpc_websocket` library](https://opam.ocaml.org/packages/async_rpc_websocket/),
which packages an `http_handler` function and RPC implementations into a `Cohttp_async.Server`-compatible server.

For now, we'll leave the RPC implementation and connection initialization logic empty.
We'll come back to these in Chapter 2.

<!-- $MDX file=../../src/todo_list/0_hello_world/server/src/server.ml,part=server_wrapper -->
```ocaml
let initialize_connection _initiated_from _addr _inet connection = connection

let main ~port =
  let hostname = Unix.gethostname () in
  printf "Serving http://%s:%d/\n%!" hostname port;
  let%bind server =
    let http_handler () = handler in
    Rpc_websocket.Rpc.serve ~on_handler_error:`Ignore ~mode:`TCP
      ~where_to_listen:(Tcp.Where_to_listen.of_port port)
      ~http_handler
      ~implementations:
        (Rpc.Implementations.create_exn ~implementations:[]
           ~on_unknown_rpc:`Continue)
      ~initial_connection_state:initialize_connection ()
  in
  Cohttp_async.Server.close_finished server
```

Finally, all we need to do is wrap this async function that runs our server into
a `Core.Command.t`, as we saw at the start of this section:

<!-- $MDX file=../../src/todo_list/0_hello_world/server/src/server.ml,part=command -->
```ocaml
let command =
  Command.async ~summary:"Start server for todo-list"
    (let%map_open.Command port =
       flag "port"
         (optional_with_default 8080 int)
         ~doc:"port on which to serve"
     in
     fun () -> main ~port)
```

Now that we understand how to run a basic OCaml web backend to serve our frontend,
let's dive into Bonsai.

## Hello World in Bonsai

Most OCaml programs result in an .exe file that you run via the
command line. But Bonsai uses
[js_of_ocaml (jsoo)](https://github.com/ocsigen/js_of_ocaml) to produce a
JavaScript file with the extension `.bc.js` (the "bc" for "bytecode")
that is then included in an HTML page.

That's how the `Embedded_files.main_dot_bc_dot_js` file we serve for 
requests to `/main.js` is created.

Right now, we have 2 files:

- `app.ml` will define our top-level Bonsai components.
- `main.ml` will start Bonsai, attach the `app.ml` component to
  the page, and initialize communication with the server.

### Dune Config

We follow the Dune instructions for [building javascript
executables](https://dune.readthedocs.io/en/stable/jsoo.html).
In particular, `(modes js)` instructs Dune to compile our bytecode
to JavaScript, and the `js_of_ocaml-ppx` preprocessor lets us use
bindings for browser APIs.

<!-- $MDX file=../../src/todo_list/0_hello_world/client/dune -->
```dune
(executables
 (names main)
 (modes js)
 (libraries
  async_kernel
  async_js
  core_kernel.composition_infix
  core
  bonsai
  bonsai.web
  common
  virtual_dom
  virtual_dom.input_widgets)
 (preprocess
  (pps js_of_ocaml-ppx ppx_jane ppx_css)))
```

Once you mark a library or executable with `js_of_ocaml`, you are in
effect declaring that your only dependencies will also be
`js_of_ocaml`-compatible libraries. In particular, you're disallowed
from using libraries that won't work in a Javascript runtime, like
`Core_unix`.

### Our Hello World Code

Bonsai components are [incremental](https://blog.janestreet.com/introducing-incremental/)
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

For now though, all we want to do is display "Hello World".
Our top-level component in `app.ml` will just be an HTML text node,
wrapped in a `Computation.t` so that it's a Bonsai component:

<!-- $MDX file=../../src/todo_list/0_hello_world/client/app.ml -->
```dune
open! Core
open! Bonsai_web

let component = Computation.return (Vdom.Node.text "Hello world!")
```

We'll learn how to write more interesting HTML in the next chapter,
and build more powerful components after that.

Now that we have our top-level component, all that remains is to
start the Bonsai web app in `main.ml`, which will become the
`main.bc.js` executable:

<!-- $MDX file=../../src/todo_list/0_hello_world/client/main.ml -->
```dune
open! Core
open! Async_kernel
open! Bonsai_web

let run () =
  let (_ : _ Start.Handle.t) =
    Start.start Start.Result_spec.just_the_view ~bind_to_element_with_id:"app"
      App.component
  in
  return ()

let () = don't_wait_for (run ())
```

The `bind_to_element_with_id` tells Bonsai to attach itself to the `app` HTML element,
returned by the server, which we discussed earlier.

And that's "Hello World"!

In the [next chapter](./1_static_layout.md), we'll learn how to build and style components in Bonsai;
in other words, how to write HTML and CSS in OCaml.
