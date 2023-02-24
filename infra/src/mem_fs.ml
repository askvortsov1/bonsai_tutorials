open! Core

type 'a t =
  { root_dir : string
  ; files : 'a Map.M(String).t
  }
[@@deriving sexp]

let to_file_list t = Map.to_alist t.files

let of_file_list root_dir files =
  match Map.of_alist (module String) files with
  | `Duplicate_key key -> Or_error.error_s [%message "Duplicate key" (key : string)]
  | `Ok files ->
    let rel_root_dir = Fs_util.relativize_path root_dir in
    Or_error.return { root_dir = rel_root_dir; files }
;;

let read_from_dir ?exclude ~f root_dir =
  let open Or_error.Let_syntax in
  let%bind paths = Fs_util.ls_dir_rec ?exclude root_dir in
  paths
  |> List.map ~f:(fun path ->
       let deserialized = f (In_channel.read_all path) in
       let rel_path = String.substr_replace_first path ~pattern:root_dir ~with_:"" in
       rel_path, deserialized)
  |> of_file_list root_dir
;;

let persist_to_fs t ~f =
  t.files
  |> Map.map ~f
  |> Map.iteri ~f:(fun ~key ~data ->
       let path = Filename.concat t.root_dir key in
       Fs_util.write_all_deep path ~data)
;;

let cwd = Sys_unix.getcwd ()

let merge a b =
  let absolutize_paths t =
    let abs_root = Filename.to_absolute_exn ~relative_to:cwd t.root_dir in
    let abs_files =
      t.files |> Map.to_alist |> List.map ~f:(fun (k, v) -> Filename.concat abs_root k, v)
    in
    abs_root, abs_files
  in
  let (root_a, files_a), (root_b, files_b) = absolutize_paths a, absolutize_paths b in
  let common_root = Fs_util.least_common_ancestor_abs root_a root_b in
  let files = List.append files_a files_b in
  let files_map =
    files
    |> List.map ~f:(fun (k, v) -> Fs_util.relativize_path ~relative_to:common_root k, v)
    |> Map.of_alist_reduce (module String) ~f:(fun _ x -> x)
  in
  let rel_common_root = Fs_util.relativize_path common_root in
  { root_dir = rel_common_root; files = files_map }
;;

let map t ~f =
  let new_files = Map.mapi ~f:(fun ~key ~data -> f ~path:key ~contents:data) t.files in
  { t with files = new_files }
;;

let root_dir t = t.root_dir

let with_root_dir t new_root_dir =
  { t with root_dir = Fs_util.relativize_path new_root_dir }
;;

let empty = { root_dir = "/"; files = Map.empty (module String) }
