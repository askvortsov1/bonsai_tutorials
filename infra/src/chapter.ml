open! Core

type t =
  { readme : string
  ; source : string Mem_fs.t
  }
[@@deriving sexp]

let mdx_prefix = "(* $MDX"

let remove_consecutive_empty_line l =
  let rec loop result l =
    match l with
    | "" :: "" :: tl -> loop result ("" :: tl)
    | x :: tl -> loop (x :: result) tl
    | [] -> List.rev result
  in
  loop [] l
;;

let clean chapter =
  let clean_mdx ~path contents =
    if String.is_empty contents
    then contents
    else
      contents
      |> String.split_lines
      |> List.filter ~f:(fun l ->
           l |> String.lstrip |> String.is_prefix ~prefix:mdx_prefix |> not)
      |> (let extension = Tuple2.get2 (Filename.split_extension path) in
          if Option.mem extension "ml" ~equal:String.equal
          then remove_consecutive_empty_line
          else Fn.id)
      |> String.concat ~sep:"\n"
      |> fun x -> if String.is_suffix ~suffix:"\n" x then x else x ^ "\n"
  in
  let trim_opam_suffix =
    let opam_regex = Re.compile (Re.Posix.re "([a-zA-Z_-])[0-9]*\\.opam") in
    Re.replace opam_regex ~f:(fun g -> sprintf "%s.opam" (Re.Group.get g 1))
  in
  let open Or_error.Let_syntax in
  let%bind cleaned_source =
    chapter.source |> Mem_fs.map ~f:clean_mdx |> Mem_fs.rename ~f:trim_opam_suffix
  in
  return { chapter with source = cleaned_source }
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
