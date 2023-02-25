open! Core
open Infra_src.Mem_fs
open Infra_src.Fs_util

let%expect_test "read from fs" =
  let fs = read_from_dir ~f:Fn.id "./fixtures/read_env" in
  print_s [%message (fs : string t Or_error.t)];
  [%expect
    {|
    (fs
     (Ok
      ((root_dir fixtures/read_env)
       (files
        ((/dune "") (/file.ml "let this_fixture = \"a mess\"")
         (/file/README.md "This file is intentionally left blank.")
         (/file/nested2/leaf "") (/file/nested2/nested3/leaf "")
         ("/file/spaces in file name.txt" "Hmm, OCaml in space...")
         (/poem.txt
           "Some kind words about Bonsai from Chat GPT:\
          \n\
          \nBonsai front-end shines\
          \nGraceful design, ease of use\
          \nWeb apps blossom bright.")))))) |}]
;;

let%expect_test "read from fs with exclude" =
  let fs =
    read_from_dir
      ~exclude:(Re.Posix.compile (Re.Posix.re "nested2"))
      ~f:Fn.id
      "./fixtures/read_env"
  in
  print_s [%message (fs : string t Or_error.t)];
  [%expect
    {|
    (fs
     (Ok
      ((root_dir fixtures/read_env)
       (files
        ((/dune "") (/file.ml "let this_fixture = \"a mess\"")
         (/file/README.md "This file is intentionally left blank.")
         ("/file/spaces in file name.txt" "Hmm, OCaml in space...")
         (/poem.txt
           "Some kind words about Bonsai from Chat GPT:\
          \n\
          \nBonsai front-end shines\
          \nGraceful design, ease of use\
          \nWeb apps blossom bright.")))))) |}]
;;

let files =
  [ "/file.txt", "O"
  ; "/file2.txt", "Caml"
  ; "/folder/nested/file.txt", "My"
  ; "/folder/nested/file2.txt", "Caml"
  ]
;;

let%expect_test "write to fs" =
  let root = "./fixtures/write" in
  write_all_deep (Filename.concat root "file.txt") ~data:"Something that's not O";
  let fs = of_file_list root files in
  let write_result = Or_error.bind fs ~f:(persist_to_fs ~f:Fn.id) in
  print_s [%message (write_result : unit Or_error.t)];
  [%expect {| (write_result (Ok ())) |}];
  let real_files = Infra_src.Fs_util.ls_dir_rec root in
  print_s [%message (real_files : string list Or_error.t)];
  [%expect
    {|
    (real_files
     (Ok
      (./fixtures/write/file.txt ./fixtures/write/file2.txt
       ./fixtures/write/folder/nested/file.txt
       ./fixtures/write/folder/nested/file2.txt))) |}];
  let contents =
    files
    |> List.map ~f:Tuple2.get1
    |> List.map ~f:(Filename.concat root)
    |> List.map ~f:In_channel.read_all
  in
  print_s [%message (contents : string list)];
  [%expect {| (contents (O Caml My Caml)) |}]
;;

let%expect_test "write to fs clear" =
  let root = "./fixtures/write" in
  write_all_deep (Filename.concat root "other_file.txt") ~data:"abc";
  write_all_deep (Filename.concat root "nested/pre-existing_file.txt") ~data:"123";
  let fs = of_file_list root files in
  let write_result = Or_error.bind fs ~f:(persist_to_fs ~f:Fn.id ~clear:false) in
  print_s [%message (write_result : unit Or_error.t)];
  [%expect {| (write_result (Ok ())) |}];
  let real_files = Infra_src.Fs_util.ls_dir_rec root in
  print_s [%message (real_files : string list Or_error.t)];
  [%expect
    {|
    (real_files
     (Ok
      (./fixtures/write/other_file.txt ./fixtures/write/file.txt
       ./fixtures/write/nested/pre-existing_file.txt ./fixtures/write/file2.txt
       ./fixtures/write/folder/nested/file.txt
       ./fixtures/write/folder/nested/file2.txt))) |}];
  let write_result = Or_error.bind fs ~f:(persist_to_fs ~f:Fn.id ~clear:true) in
  print_s [%message (write_result : unit Or_error.t)];
  [%expect {| (write_result (Ok ())) |}];
  let real_files = Infra_src.Fs_util.ls_dir_rec root in
  print_s [%message (real_files : string list Or_error.t)];
  [%expect
    {|
    (real_files
     (Ok
      (./fixtures/write/file.txt ./fixtures/write/file2.txt
       ./fixtures/write/folder/nested/file.txt
       ./fixtures/write/folder/nested/file2.txt))) |}]
;;
