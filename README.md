# Bonsai Tutorials

Bonsai is an OCaml library and runtime for building frontend web apps.
In these tutorials, you'll learn Bonsai by building some simple example apps.

At the moment, we have 2 tutorials.

`todo_list` demonstrates a simple full-stack CRUD web app, entirely in OCaml. You'll learn:
- The basics of designing and building reusable, interactive Bonsai components
- Bonsai's RPC tools, and how they can be used for robust, type-safe communication between frontend and backend
- `Url_var`: a library for URLs and routing in Bonsai, which comes with a typed bi-directional router
- How to build, display, and access data from type-safe forms
- Bonsai's basic higher-order components:
  - `match%sub`, which evaluates one of several computations
  - `assoc`, which evaluates a dynamic number of computations in parallel

`snake` implements a simple version of the classic video game in Bonsai.
This tutorial focuses on Bonsai's state tools, and patterns for sharing state between components.
It'll also give you practice building interactive, reactive applications.

I recommend following the tutorials in this order. `todo_list` introduces a wide variety of concepts, while `snake_game` dives deeper into state.

Each tutorial is split into bite-sized chapter, along with what the code should look like by the end.

These tutorials assume familiarity with basic programming in OCaml, and use of the Dune build system.

## How to Use

The easiest way to follow these tutorials is to clone this repository, and work directly in the `workbench` folder.
Each tutorial comes with basic starter code, so you don't need to worry about setting up a project, or figuring out which dependencies you need.

The `tutorials` folder contains step-by-step instructions for each tutorial. You'll want to open these alongside the starter code.
As you work through the tutorials, we highly recommend typing out code instead of copying it. This will help you learn better, and
also give you a chance to play around inspect types by hovering.

`src` contains a copy of what the code should look like after every chapter of a tutorial. You can compare your code to it, or use it to track how the code evolves.

The first chapter of each tutorial is an explanation of the starter code and file structure. From there, you'll be building out the project one step at a time. Each chapter will introduce new concepts.
The goal of this tutorial is to teach you how to use Bonsai.
We won't cover much of the conceptual background, history, inner workings, or all of the available tools.
For that, you should read our [explanatory documentation](https://bonsai.red/). We recommend having it open, and will be linking to it frequently.


## Additional Resources

Here are a few useful references for understanding Bonsai. Some of these will be referenced throughout the tutorials.

* Bonsai's [public documentation](https://bonsai.red/), which provides background and explanation for Bonsai, with code examples. The guide goes hand-in-hand with these tutorials, and we'll reference it often.
* The [bonsai.mli](https://github.com/janestreet/bonsai/blob/master/src/bonsai.mli) file, which is a reference guide for Bonsai's public API.
* A [comparison of component implementations](https://github.com/TyOverby/composition-comparison/blob/main/readme.md) between Bonsai, Elm, and React. If you're more familiar with a different framework, these can help get started with Bonsai. They also showcase Bonsai's strength, flexibility, and tersity.
* Blog posts on [how to think about Bonsai components](https://gist.github.com/TyOverby/daf9a92db08d1c724f298bfb943f5a3e) and [higher-order components](https://gist.github.com/TyOverby/cf9b79bab1cf96369411c761c9406d95), as well as [tools for internal vs external state](https://gist.github.com/TyOverby/fa89d5c3ef9ef5830f0a5146da98ebd5).
* [Signals & Threads interview w/ Bonsai creator](https://signalsandthreads.com/building-a-ui-framework/)
* The second half of [this blog series](https://ceramichacker.com/blog/category/ocaml-webdev)
* [Tech talk on incremental computation](https://www.youtube.com/watch?v=G6a5G5i4gQU)
* [Bonsai History](https://github.com/janestreet/bonsai/blob/master/docs/blogs/history.md), with the most recent development [in a separate article](https://github.com/janestreet/bonsai/blob/master/docs/blogs/proc.md).
* [How to test Bonsai components](https://github.com/janestreet/bonsai/blob/master/docs/blogs/testing.md)

## Need to build:

- reset a workbench to a version of a tutorial
- generate diffs from each version to the next for manual review

For both, need to read in info:

- Get list of tutorials, and chapters within those projects
- Clear out MDX comment lines, since these will be in different places for different things, and shouldn't be in the starter code.
- Validate source is present for all in tutorials