open! Core

type t =
  { readme : string
  ; source : string list Mem_fs.t
  }
[@@deriving sexp]

let mdx_prefix = "(* $MDX"

let clean chapter =
  let clean ~path:_ contents =
    contents |> List.filter ~f:(fun l -> not (String.is_prefix ~prefix:mdx_prefix l))
  in
  { chapter with source = Mem_fs.map ~f:clean chapter.source }
;;

module Name = struct
  type t =
    { i : int
    ; name : string
    ; src_dirname : string
    ; readme_name : string
    }
  [@@deriving sexp, typed_fields]

  let resolve readme_name =
    let chapter_regex =
      Re.Posix.compile (Re.Posix.re "(([0-9]+)_([a-zA-Z0-9_]+))\\.md")
    in
    let open Option.Let_syntax in
    let%bind g = Re.exec_opt chapter_regex readme_name in
    let%bind i_str, name, src_dirname =
      Option.map3
        (Re.Group.get_opt g 2)
        (Re.Group.get_opt g 3)
        (Re.Group.get_opt g 1)
        ~f:Tuple3.create
    in
    let i = Int.of_string i_str in
    Some { i; name; src_dirname; readme_name }
  ;;
end
