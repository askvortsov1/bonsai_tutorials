#!/usr/bin/env bash

opam exec -- dune build

cli="./_build/default/infra/bin/main.exe"

$cli save-diffs todo_list
$cli reset-workbench todo_list

#cli save-diffs snake_game
#cli reset-workbench snake_game