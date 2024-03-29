open! Core

type t = Position.t [@@deriving sexp, equal]

let list_of_t t = [ t ]

let spawn_random_exn ~rows ~cols ~invalid_pos =
  Position.random_pos ~rows ~cols ~invalid_pos |> Option.value_exn
;;

let cell_style a pos =
  if Position.equal a pos then Some (Css_gen.background_color (`Name "red")) else None
;;
