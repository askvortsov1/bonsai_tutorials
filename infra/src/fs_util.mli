open! Core

(** [ls_dir_rec ?exclude root] recursively lists all files inside a directory,
    and all nested subdirectories, excluding those matched by the regex [exclude].
    File paths are returned in alphabetical order to guaruntee determinism for tests. *)
val ls_dir_rec : ?exclude:Re.re -> string -> string list Or_error.t

(** [write_all_deep] has the same behavior as [Out_channel], except that if the
    requested file is in a non-existent directory, [write_all_deep] will create
    all necessary nested directories in addition to writing the file. *)
val write_all_deep : string -> data:string -> unit

(** [least_common_ancestor_abs a b] returns the deepest directory containing
    both `a` and `b`, as an absolute path. *)
val least_common_ancestor_abs : string -> string -> string

(** [relativize_path path] takes a path, which may be absolute or relative, and
    makes it relative. By default, it will make it relative to `Sys_unix.getcwd`. *)
val relativize_path : ?relative_to:string -> string -> string
