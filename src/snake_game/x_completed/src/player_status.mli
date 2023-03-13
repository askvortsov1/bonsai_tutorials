open! Core

module Inactive_reason : sig
  type t =
    | Not_started
    | Ate_self
    | Out_of_bounds
  [@@deriving sexp, equal]
end

type t =
  | Playing
  | Inactive of Inactive_reason.t
[@@deriving sexp, equal]
