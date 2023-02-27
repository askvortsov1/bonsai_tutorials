open! Core
open Infra_src.Chapter

let%expect_test "Name.resolve" =
  let valid = Name.resolve "0_hello_world.md" in
  print_s [%message (valid : Name.t option)];
  [%expect
    {|
    (valid
     (((i 0) (name hello_world) (src_dirname 0_hello_world)
       (readme_name 0_hello_world.md)))) |}];
  let double_digit = Name.resolve "23_HasSomeUppercase.md" in
  print_s [%message (double_digit : Name.t option)];
  [%expect
    {|
    (double_digit
     (((i 23) (name HasSomeUppercase) (src_dirname 23_HasSomeUppercase)
       (readme_name 23_HasSomeUppercase.md)))) |}];
  let no_num = Name.resolve "_HasSomeUppercase.md" in
  print_s [%message (no_num : Name.t option)];
  [%expect {| (no_num ()) |}];
  let no_sep = Name.resolve "102HasSomeUppercase.md" in
  print_s [%message (no_sep : Name.t option)];
  [%expect {| (no_sep ()) |}];
  let no_name = Name.resolve "106_.md" in
  print_s [%message (no_name : Name.t option)];
  [%expect {| (no_name ()) |}];
  let only_num = Name.resolve "106.md" in
  print_s [%message (only_num : Name.t option)];
  [%expect {| (only_num ()) |}];
  let no_ext = Name.resolve "2_backend" in
  print_s [%message (no_ext : Name.t option)];
  [%expect {| (no_ext ()) |}]
;;

let%expect_test "clean mdx" =
  let open Or_error.Let_syntax in
  let clean_chapter_with_mdx =
    let with_mdx_lines =
      {| something
(* $MDX part-begin="x)
something else
(* $MDX part-end) |}
    in
    let%bind source = Infra_src.Mem_fs.of_file_list "" [ "", with_mdx_lines ] in
    let%bind cleaned = clean { readme = ""; source } in
    Or_error.return cleaned
  in
  print_s [%message (clean_chapter_with_mdx : t Or_error.t)];
  [%expect
    {|
    (clean_chapter_with_mdx
     (Ok
      ((readme "")
       (source ((root_dir .) (files ((""  " something\
                                         \nsomething else")))))))) |}]
;;
