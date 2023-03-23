open! Core

type t =
  | Up
  | Down
  | Right
  | Left
[@@deriving sexp, equal]
