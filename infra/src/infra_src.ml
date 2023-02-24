open! Core
module Chapter = Chapter
module Mem_fs = Mem_fs
module Fs_util = Fs_util

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
end

let serialize = String.concat ~sep:"\n"

let reset_workbench ?(preserve_archive=false) ~tutorials_dir ~src_dir ~workbench_dir ~project ~chapter_index =
  let open Or_error.Let_syntax in
  let%bind all_chapters = Private.get_chapters ~tutorials_dir ~src_dir ~project in
  match List.nth all_chapters chapter_index with
  | None -> let max_chapter = (List.length all_chapters) - 1 in
    Or_error.error_s [%message "Requested 0-indexed chapter does not exist" (chapter_index: int) (max_chapter: int)]
  | Some chapter ->
    let workbench_proj_dir = Filename.concat workbench_dir project in
    let%bind backup =
      if preserve_archive then
        let%bind curr = Mem_fs.read_from_dir ~f:String.split_lines workbench_proj_dir in
        let now = Time_ns.now () in
        let now_str = Time_ns.to_string_abs_trimmed ~zone:Time.Zone.utc now in
        let backup_dir = Filename.concat workbench_dir (sprintf "%s-backup-%s" project now_str) in
        Or_error.return (Mem_fs.with_root_dir curr backup_dir)
      else Or_error.return Mem_fs.empty
    in 
    let source = Mem_fs.with_root_dir chapter.source workbench_proj_dir in
    Mem_fs.persist_to_fs ~f:serialize source;
    Mem_fs.persist_to_fs ~f:serialize backup;
    Or_error.return ()


(* let save_diffs ~tutorials_dir ~src_dir ~diffs_dir ~project = *)
(* Pull in all chapters in the project *)
(* Chapter.clean () *)
(* validate that all chapters have corresponding docs and vice versa *)
(* Generate diffs from chapter to chapter *)
(* Write diffs to files *)
