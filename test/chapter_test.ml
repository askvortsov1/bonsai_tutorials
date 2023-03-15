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
  let make_singleton_fs path file =
    let%bind source = Infra_src.Mem_fs.of_file_list "" [ path, file ] in
    let%bind cleaned = clean { readme = ""; source } in
    Or_error.return cleaned
  in
  let mdx_contents_with_newlines =
    {| something
let x = 10
(* $MDX part-begin=y *)
let y = 15


let q = x + y
(* $MDX part-end *)

(* $MDX part-begin=z *)
let z = 100
(* $MDX part-end *)|}
  in
  let not_ml_file = make_singleton_fs "" mdx_contents_with_newlines in
  print_s [%message (not_ml_file : t Or_error.t)];
  [%expect
    {|
    (not_ml_file
     (Ok
      ((readme "")
       (source
        ((root_dir .)
         (files
          ((""
             " something\
            \nlet x = 10\
            \nlet y = 15\
            \n\
            \n\
            \nlet q = x + y\
            \n\
            \nlet z = 100\
            \n")))))))) |}];
  let ml_file = make_singleton_fs "file.ml" mdx_contents_with_newlines in
  print_s [%message (ml_file : t Or_error.t)];
  [%expect
    {|
    (ml_file
     (Ok
      ((readme "")
       (source
        ((root_dir .)
         (files
          ((file.ml
             " something\
            \nlet x = 10\
            \nlet y = 15\
            \n\
            \nlet q = x + y\
            \n\
            \nlet z = 100\
            \n")))))))) |}]
;;
