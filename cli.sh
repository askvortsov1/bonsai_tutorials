#!/usr/bin/env bash

opam exec -- dune build

cli="./_build/default/infra/bin/main.exe"

$cli "$@"
