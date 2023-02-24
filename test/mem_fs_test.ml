open! Core
open Infra_src.Mem_fs

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
  let fs = of_file_list root files in
  (match fs with
   | Ok x -> persist_to_fs ~f:Fn.id x
   | Error err -> print_s [%message (err : Error.t)]);
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

let%expect_test "merge" =
  let root = "./fixtures/merged" in
  let fs = of_file_list root files in
  let merged_fs =
    let open Or_error.Let_syntax in
    let%bind fs1 = fs in
    let fs2 = with_root_dir fs1 "./fixtures/alt/subdir" in
    Ok (merge fs1 fs2)
  in
  print_s [%message (merged_fs : string t Or_error.t)];
  [%expect
    {|
    (merged_fs
     (Ok
      ((root_dir fixtures)
       (files
        ((alt/subdir/file.txt O) (alt/subdir/file2.txt Caml)
         (alt/subdir/folder/nested/file.txt My)
         (alt/subdir/folder/nested/file2.txt Caml) (merged/file.txt O)
         (merged/file2.txt Caml) (merged/folder/nested/file.txt My)
         (merged/folder/nested/file2.txt Caml)))))) |}]
;;
