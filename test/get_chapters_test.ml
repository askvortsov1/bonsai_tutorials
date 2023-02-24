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
         ((root_dir ./fixtures/src/valid_project/0_intro)
          (files ((/.gitkeep ()))))))
       ((readme "")
        (source
         ((root_dir ./fixtures/src/valid_project/1_frontend)
          (files ((/.gitkeep ()))))))))) |}]
;;

let%expect_test "nonexistent project" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"does_not_exist" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("Tutorials directory for project does_not_exist is not a directory, or doesn't exist: ./fixtures/tutorials/does_not_exist"))) |}]
;;

let%expect_test "empty project" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"empty" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("Tutorials directory for project empty is not a directory, or doesn't exist: ./fixtures/tutorials/empty"))) |}]
;;

let%expect_test "project without source" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"missing_project_src" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("Source directory for project missing_project_src is not a directory, or doesn't exist: ./fixtures/src/missing_project_src"))) |}]
;;

let%expect_test "chapter without source" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"missing_chapter_src" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (chapters
     (Error
      ("File ./fixtures/src/missing_chapter_src/1_has_no_source_dir does not exist"))) |}]
;;

let%expect_test "missing chapter" =
  let chapters = get_chapters ~tutorials_dir ~src_dir ~project:"missing_chapter" in
  print_s [%message (chapters : Infra_src.Chapter.t list Or_error.t)];
  [%expect
    {|
    (missing_chapters (1 2))
    (chapters
     (Error
      ("Chapter #1 is missing. All chapters: 0_intro, 2_backend, 4_wormholes"))) |}]
;;
