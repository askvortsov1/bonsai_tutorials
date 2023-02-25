open! Core
open Infra_src.Private

let tutorials_dir = "./fixtures/tutorials"
let src_dir = "./fixtures/src"

let%expect_test "valid project" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"valid_project" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Ok
      (((readme "")
        (source
         ((root_dir fixtures/src/valid_project/0_intro) (files ((/.gitkeep ()))))))
       ((readme "")
        (source
         ((root_dir fixtures/src/valid_project/1_frontend)
          (files ((/.gitkeep ()))))))))) |}]
;;

let%expect_test "nonexistent project" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"does_not_exist" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("Tutorials directory is not a directory, doesn't exist, or couldn't be accessed"
       (tutorials_proj_dir ./fixtures/tutorials/does_not_exist)
       (project does_not_exist)))) |}]
;;

let%expect_test "empty project" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"empty" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("Tutorials directory is not a directory, doesn't exist, or couldn't be accessed"
       (tutorials_proj_dir ./fixtures/tutorials/empty) (project empty)))) |}]
;;

let%expect_test "project without source" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"missing_project_src" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("Source directory is not a directory, doesn't exist, or couldn't be accessed"
       (tutorials_proj_dir ./fixtures/tutorials/missing_project_src)
       (project missing_project_src)))) |}]
;;

let%expect_test "chapter without source" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"missing_chapter_src" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      (errors
       ("File ./fixtures/src/missing_chapter_src/1_has_no_source_dir does not exist")))) |}]
;;

let%expect_test "missing chapter" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"missing_chapter" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("Chapter is missing" (missing_chapter 1)
       (chapter_names
        (((i 0) (name intro) (src_dirname 0_intro) (readme_name 0_intro.md))
         ((i 2) (name backend) (src_dirname 2_backend)
          (readme_name 2_backend.md))
         ((i 4) (name wormholes) (src_dirname 4_wormholes)
          (readme_name 4_wormholes.md))))))) |}]
;;
