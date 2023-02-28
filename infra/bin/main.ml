open! Core

module Shared = struct
  let default_diffs_dir = "./diffs"
  let default_src_dir = "./src"
  let default_tutorials_dir = "./tutorials"
  let default_workbench_dir = "./workbench"

  open Command.Param

  let diffs_dir_flag =
    flag
      "--diffs-dir"
      (optional_with_default default_diffs_dir string)
      ~doc:" alternate diffs directory"
  ;;

  let src_dir_flag =
    flag
      "--src-dir"
      (optional_with_default default_src_dir string)
      ~doc:" alternate tutorial source directory"
  ;;

  let tutorials_dir_flag =
    flag
      "--tutorials-dir"
      (optional_with_default default_tutorials_dir string)
      ~doc:" alternate tutorials directory"
  ;;

  let workbench_dir_flag =
    flag
      "--workbench-dir"
      (optional_with_default default_workbench_dir string)
      ~doc:" alternate workbench directory"
  ;;

  let project_arg = anon ("project" %: string)
end

let reset_workbench =
  Command.basic
    ~summary:
      "Reset the [project] workbench to the completed code for chapter #[chapter_index]."
    (let%map_open.Command make_backup =
       flag
         "--make-backup"
         no_arg
         ~doc:"back up your current workbench before resetting it"
     and src_dir = Shared.src_dir_flag
     and tutorials_dir = Shared.tutorials_dir_flag
     and workbench_dir = Shared.workbench_dir_flag
     and project = Shared.project_arg
     and chapter_index = anon (maybe_with_default 0 ("chapter_index" %: int)) in
     fun () ->
       Infra_src.reset_workbench
         ~make_backup
         ~src_dir
         ~tutorials_dir
         ~workbench_dir
         ~project
         ~chapter_index
       |> Or_error.ok_exn)
;;

let save_diffs =
  Command.basic
    ~summary:"Persist diffs between all chapters for [project]."
    (let%map_open.Command diffs_dir = Shared.diffs_dir_flag
     and src_dir = Shared.src_dir_flag
     and tutorials_dir = Shared.tutorials_dir_flag
     and project = Shared.project_arg in
     fun () ->
       Infra_src.save_diffs ~src_dir ~tutorials_dir ~diffs_dir ~project |> Or_error.ok_exn)
;;

let command =
  Command.group
    ~summary:"Infrastructure for Bonsai Tutorials"
    [ "reset-workbench", reset_workbench; "save-diffs", save_diffs ]
;;

let () = Command_unix.run command
