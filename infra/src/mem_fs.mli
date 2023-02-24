open! Core

(** An in-memory representation of the files recursively contained in
    a directory. Allows us to cleanly manipulate and modify files
    for tutorials, and only interact with the actual filesystem at the
    start and end.
    
    It's intended for relatively small files / file sets, where all files
    are used, so async or lazy file loading are unnecessary.

    I've also only implemented the operators needed for this library instead
    of trying to satisfy a general "filesystem" interface.
    *)

type 'a t [@@deriving sexp]

(** [read_from_dir ?exclude ~f root_dir] recursively reads all files in [root_dir]
     into a `t`, passing them through a deserialization function `f`.
     Paths can be excluded via the optional `?exclude` argument. *)
val read_from_dir : ?exclude:Re.re -> f:(string -> 'a) -> string -> 'a t Or_error.t

(** [persist_to_fs t ~f] writes all files in the in-memory filesystem to the real
    unix filesystem, creating any needed subdirectories if they don't exist.
    Files will be serialized to strings by the serialization function `f`. *)
val persist_to_fs : 'a t -> f:('a -> string) -> unit

(** [merge a b] combines 2 `Mem_fs.t` instances. The new root_dir will be the lowest
    shared ancestor of `a` and `b`.
    In the event of duplicate file contents, that in `b` will be used. *)
val merge : 'a t -> 'a t -> 'a t

(** [map t ~f] applies `f` to every file in `t`. *)
val map : 'a t -> f:(path:string -> contents:'a -> 'b) -> 'b t

(** [root_dir t] gets the root directory of t. *)
val root_dir : 'a t -> string

(** [with_root_dir t] returns `t` with a new root directory. *)
val with_root_dir : 'a t -> string -> 'a t

(** [to_file_list t] returns a list of (path, serialized_file) tuples. *)
val to_file_list : 'a t -> (string * 'a) list

(** [to_file_list root_dir files] constructs a Mem_fs from a root directory
    and a list of (path, serialized_file) tuples. *)
val of_file_list : string -> (string * 'a) list -> 'a t Or_error.t

(** [empty] returns an empty Mem_fs.t. Writing and merging with it is a no-op. *)
val empty: 'a t
