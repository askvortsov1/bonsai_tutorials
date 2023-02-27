open! Core
module Chapter = Chapter
module Mem_fs = Mem_fs
module Fs_util = Fs_util

let serialize = String.concat ~sep:"\n"

module Private = struct
  let get_chapters ~tutorials_dir ~src_dir ~project =
    let tutorials_proj_dir = Filename.concat tutorials_dir project in
    let src_proj_dir = Filename.concat src_dir project in
    match
      Sys_unix.is_directory tutorials_proj_dir, Sys_unix.is_directory src_proj_dir
    with
    | `No, _ | `Unknown, _ ->
      Or_error.error_s
        [%message
          "Tutorials directory is not a directory, doesn't exist, or couldn't be accessed"
            (tutorials_proj_dir : string)
            (project : string)]
    | _, `No | _, `Unknown ->
      Or_error.error_s
        [%message
          "Source directory is not a directory, doesn't exist, or couldn't be accessed"
            (tutorials_proj_dir : string)
            (project : string)]
    | `Yes, `Yes ->
      let chapter_names_raw = Sys_unix.ls_dir tutorials_proj_dir in
      let chapter_names =
        chapter_names_raw
        |> List.filter_map ~f:Chapter.Name.resolve
        |> List.stable_sort ~compare:(fun a b -> Int.compare a.i b.i)
      in
      let chapter_nums = List.map chapter_names ~f:Chapter.Name.Typed_field.(get I) in
      let missing_chapters =
        List.map2_exn
          (List.init (List.length chapter_nums) ~f:Fn.id)
          chapter_nums
          ~f:Tuple2.create
        |> List.filter ~f:(fun (i, j) -> not (phys_equal i j))
        |> List.map ~f:Tuple2.get1
      in
      (match missing_chapters with
       | missing_chapter :: _ ->
         Or_error.error_s
           [%message
             "Chapter is missing"
               (missing_chapter : int)
               (chapter_names : Chapter.Name.t list)]
       | [] ->
         chapter_names
         |> List.map ~f:(fun { src_dirname; readme_name; _ } ->
              let readme_path = Filename.concat tutorials_proj_dir readme_name in
              let readme = In_channel.read_all readme_path in
              let source_path = Filename.concat src_proj_dir src_dirname in
              let source = Mem_fs.read_from_dir source_path ~f:String.split_lines in
              Or_error.map source ~f:(fun source -> { Chapter.readme; source }))
         |> Or_error.all)
  ;;

  let project_backup_dir ~workbench_dir ~project =
    let now = Time_ns.now () in
    let now_str = Time_ns.to_string_abs_trimmed ~zone:Time.Zone.utc now in
    Filename.concat workbench_dir (sprintf "%s-backup-%s" project now_str)
  ;;
end

let reset_workbench
  ~make_backup
  ~tutorials_dir
  ~src_dir
  ~workbench_dir
  ~project
  ~chapter_index
  =
  let open Or_error.Let_syntax in
  let%bind all_chapters = Private.get_chapters ~tutorials_dir ~src_dir ~project in
  match List.nth all_chapters chapter_index with
  | None ->
    let max_chapter = List.length all_chapters - 1 in
    Or_error.error_s
      [%message
        "Requested 0-indexed chapter does not exist"
          (chapter_index : int)
          (max_chapter : int)]
  | Some chapter ->
    let workbench_proj_dir = Filename.concat workbench_dir project in
    let%bind backup =
      if make_backup
      then (
        let%bind curr = Mem_fs.read_from_dir ~f:String.split_lines workbench_proj_dir in
        let backup_dir = Private.project_backup_dir ~workbench_dir ~project in
        Or_error.return (Mem_fs.mount curr backup_dir))
      else Or_error.return Mem_fs.empty
    in
    let source = Mem_fs.mount chapter.source workbench_proj_dir in
    let source_write = Mem_fs.persist_to_fs ~clear:true ~f:serialize source
    and backup_write = Mem_fs.persist_to_fs ~clear:make_backup ~f:serialize backup in
    Or_error.all_unit [ source_write; backup_write ]
;;

let gen_diffs chapters =
  let rec loop result (chapters : Chapter.t list) =
    match chapters with
    | a :: b :: cs ->
      let diff =
        Mem_fs.diff ~serialize:(fun ~path:_ x -> serialize x) a.source b.source
      in
      loop (diff :: result) (b :: cs)
    | _ :: [] | [] -> result
  in
  List.rev (loop [] chapters)
;;

let serialize_chapter_diffs diff =
  diff
  |> Map.to_alist
  |> List.map ~f:(fun (path, diff) -> sprintf "==== %s ====\n%s" path diff)
  |> String.concat ~sep:"\n\n"
;;

let save_diffs ~tutorials_dir ~src_dir ~diffs_dir ~project =
  let open Or_error.Let_syntax in
  let%bind all_chapters = Private.get_chapters ~tutorials_dir ~src_dir ~project in
  let diffs_proj_dir = Filename.concat diffs_dir project in
  let%bind diffs_fs =
    gen_diffs all_chapters
    |> List.map ~f:serialize_chapter_diffs
    |> List.mapi ~f:(fun i x -> sprintf "%d_to_%d.patch" i (i + 1), x)
    |> Mem_fs.of_file_list diffs_proj_dir
  in
  Mem_fs.persist_to_fs ~clear:true ~f:Fn.id diffs_fs
;;
