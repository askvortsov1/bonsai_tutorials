open! Core
open Infra_src.Fs_util

let%expect_test "ls_dir_rec" =
  let files = ls_dir_rec "./fixtures/read_env" in
  print_s [%message (files : string list Or_error.t)];
  [%expect
    {|
    (files
     (Ok
      (./fixtures/read_env/dune ./fixtures/read_env/file.ml
       ./fixtures/read_env/file/README.md ./fixtures/read_env/file/nested2/leaf
       ./fixtures/read_env/file/nested2/nested3/leaf
       "./fixtures/read_env/file/spaces in file name.txt"
       ./fixtures/read_env/poem.txt))) |}]
;;

let%expect_test "write_all_deep" =
  let path = "./fixtures/write/arbitrarily_nested/and/more/and/were/done.txt" in
  write_all_deep path ~data:"Hidden Treasure";
  let contents = In_channel.read_all path in
  print_s [%message (contents : string)];
  [%expect {| (contents "Hidden Treasure") |}]
;;

let%expect_test "least_common_ancestor_abs" =
  let same_dir = least_common_ancestor_abs "/path/to/dir/x.txt" "/path/to/dir/y.txt" in
  print_s [%message same_dir];
  [%expect {| /path/to/dir |}];
  let flat_and_nested =
    least_common_ancestor_abs "/path/x.txt" "/path/to/dir/with/some/more/y.txt"
  in
  print_s [%message flat_and_nested];
  [%expect {| /path |}];
  let both_deep =
    least_common_ancestor_abs
      "/path/that/goes/to/another/dir/x.txt"
      "/path/to/dir/with/some/more/y.txt"
  in
  print_s [%message both_deep];
  [%expect {| /path |}];
  let no_shared =
    least_common_ancestor_abs "/left/lose/your/horse.txt" "/right/lose/your/head.txt"
  in
  print_s [%message no_shared];
  [%expect {| / |}]
;;

let%expect_test "relativize_path" =
  let abs = relativize_path "/root/to/something" in
  print_s [%message abs];
  [%expect {| ../../../../../../../../../root/to/something |}];
  let rel_below = relativize_path "./fixtures/something" in
  print_s [%message rel_below];
  [%expect {| fixtures/something |}];
  let rel_above = relativize_path "../src/something_else" in
  print_s [%message rel_above];
  [%expect {| ../src/something_else |}]
;;
