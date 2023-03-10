open! Core

type 'a t =
  { root_dir : string
  ; files : 'a Map.M(String).t
  }
[@@deriving sexp]

let to_file_list t = Map.to_alist t.files

let of_file_list root_dir files =
  match Map.of_alist (module String) files with
  | `Duplicate_key path -> Or_error.error_s [%message "Duplicate path" (path : string)]
  | `Ok files ->
    let rel_root_dir = Fs_util.relativize_path root_dir in
    Or_error.return { root_dir = rel_root_dir; files }
;;

let read_from_dir ?exclude root_dir =
  let open Or_error.Let_syntax in
  let%bind paths = Fs_util.ls_dir_rec ?exclude root_dir in
  paths
  |> List.map ~f:(fun path ->
       let contents = In_channel.read_all path in
       let rel_path = String.substr_replace_first path ~pattern:root_dir ~with_:"" in
       rel_path, contents)
  |> of_file_list root_dir
;;

let persist_to_fs ?(clear = false) t =
  let open Or_error.Let_syntax in
  let%bind files_to_clear =
    if clear && Sys_unix.file_exists_exn t.root_dir
    then Fs_util.ls_dir_rec t.root_dir
    else Or_error.return []
  in
  Or_error.try_with (fun () ->
    files_to_clear |> List.iter ~f:Sys_unix.remove;
    t.files
    |> Map.iteri ~f:(fun ~key ~data ->
         let path = Filename.concat t.root_dir key in
         Fs_util.write_all_deep path ~data))
;;

let map t ~f =
  let new_files = Map.mapi ~f:(fun ~key ~data -> f ~path:key data) t.files in
  { t with files = new_files }
;;

let rename t ~f =
  let renamed = Map.map_keys (module String) t.files ~f in
  match renamed with
  | `Duplicate_key path ->
    Or_error.error_s
      [%message "Multiple files have the same path after renaming" (path : string)]
  | `Ok x -> Or_error.return { t with files = x }
;;

let diff a b =
  Map.merge a.files b.files ~f:(fun ~key:_ element ->
    let operation =
      match element with
      | `Both (f_a, f_b) -> `Diff (f_a, f_b)
      | `Left f_a -> if String.is_empty f_a then `Deleted_empty else `Diff (f_a, "")
      | `Right f_b -> if String.is_empty f_b then `Created_empty else `Diff ("", f_b)
    in
    match operation with
    | `Diff (a, b) -> Some (Expect_test_patdiff.patdiff a b)
    | `Deleted_empty -> Some "(Deleted empty file)"
    | `Created_empty -> Some "(Created empty file)")
;;

let root_dir t = t.root_dir
let mount t new_root_dir = { t with root_dir = Fs_util.relativize_path new_root_dir }
let empty = { root_dir = "/dev/null"; files = Map.empty (module String) }
