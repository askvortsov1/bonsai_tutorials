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
