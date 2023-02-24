open! Core

let classify_file path =
  match Sys_unix.file_exists path, Sys_unix.is_file path, Sys_unix.is_directory path with
  | `No, _, _ -> `Err (sprintf "File %s does not exist" path)
  | `Yes, `Yes, `No -> `File
  | `Yes, `No, `Yes -> `Directory
  | `Yes, `Yes, `Yes ->
    `Err
      (sprintf
         "File %s is both a file and directory, which... should be impossible..."
         path)
  | `Yes, `No, `No ->
    `Err (sprintf "File %s is neither a file or a directory... somehow..." path)
  | `Unknown, _, _ | _, `Unknown, _ | _, _, `Unknown ->
    `Err (sprintf "Error inspecting file %s. Check permissions." path)
;;

let ls_dir_rec ?exclude root_dir =
  let exclude =
    match exclude with
    | None -> fun _ -> false
    | Some regex -> fun f -> Re.execp regex f
  in
  let rec loop result = function
    | f :: fs ->
      let curr_files, curr_errors = result in
      if exclude f
      then loop result fs
      else (
        match classify_file f with
        | `File -> loop (f :: curr_files, curr_errors) fs
        | `Err err -> loop (curr_files, err :: curr_errors) fs
        | `Directory ->
          let dir_files =
            List.map ~f:(fun path -> Filename.concat f path) (Sys_unix.ls_dir f)
          in
          loop result (dir_files @ fs))
    | [] -> result
  in
  let file_names, errors = loop ([], []) [ root_dir ] in
  match errors with
  | [] -> Or_error.return file_names
  | _ -> Or_error.error_s [%message (errors : string list)]
;;

let write_all_deep path ~data =
  let dir = Filename.dirname path in
  Core_unix.mkdir_p dir;
  Out_channel.write_all path ~data
;;

let cwd = Core_unix.getcwd ()

let least_common_ancestor_abs a b =
  let parts x = Filename.parts (Filename.to_absolute_exn ~relative_to:cwd x) in
  let rec loop result = function
    | x :: xs, y :: ys when String.equal x y -> loop (x :: result) (xs, ys)
    | _, _ -> result
  in
  loop [] (parts a, parts b)
  |> List.rev
  |> List.fold ~init:Filename.dir_sep ~f:Filename.concat
;;

let relativize_path ?(relative_to = cwd) path =
  let abs =
    if Filename.is_absolute path then path else Filename.to_absolute_exn ~relative_to path
  in
  Filename.of_absolute_exn ~relative_to abs
;;
