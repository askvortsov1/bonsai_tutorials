open! Core
module Chapter = Chapter
module Mem_fs = Mem_fs
module Fs_util = Fs_util

val reset_workbench
  :  make_backup:bool
  -> tutorials_dir:string
  -> src_dir:string
  -> workbench_dir:string
  -> project:string
  -> chapter_index:int
  -> unit Or_error.t

val save_diffs
  :  tutorials_dir:string
  -> src_dir:string
  -> diffs_dir:string
  -> project:string
  -> unit Or_error.t

module Private : sig
  (** [get_chapters tutorials_dir src_dir project] looks for all tutorial chapter
      files ({number}_{name}.md) in `tutorials_dir/project`, and matches them up
      with corresponding source code in `src_dir/project`.

      Exposed for testing, since this and the `mem_fs` contents encapsulate all
      filesystem interactions.
      
      It's a mess of nested matches and error handling, and there's probably a
      better way to implement it. *)
  val get_chapters
    :  tutorials_dir:string
    -> src_dir:string
    -> project:string
    -> Chapter.t list Or_error.t

  (** [project_backup_dir workbench_dir project] generates a backup directory name,
      based on the project name and the current time. Exposed as a util for testing. *)
  val project_backup_dir : workbench_dir:string -> project:string -> string
end
