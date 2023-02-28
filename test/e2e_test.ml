open! Core
open Infra_src

let tutorials_dir = "./fixtures/tutorials"
let src_dir = "./fixtures/src"
let workbench_dir = "./fixtures/workbench"
let diffs_dir = "./fixtures/diffs"

let%expect_test "reset workbench invalid project" =
  let project = "nonexistent_project" in
  let reset_0 =
    reset_workbench
      ~make_backup:false
      ~tutorials_dir
      ~src_dir
      ~workbench_dir
      ~project
      ~chapter_index:0
  in
  print_s [%message (reset_0 : unit Or_error.t)];
  [%expect
    {|
    (reset_0
     (Error
      ("Tutorials directory is not a directory, doesn't exist, or couldn't be accessed"
       (tutorials_proj_dir ./fixtures/tutorials/nonexistent_project)
       (project nonexistent_project)))) |}]
;;

let%expect_test "reset workbench invalid chapter" =
  let project = "nonexistent_chapter" in
  let reset_5 =
    reset_workbench
      ~make_backup:false
      ~tutorials_dir
      ~src_dir
      ~workbench_dir
      ~project
      ~chapter_index:5
  in
  print_s [%message (reset_5 : unit Or_error.t)];
  [%expect
    {|
    (reset_5
     (Error
      ("Tutorials directory is not a directory, doesn't exist, or couldn't be accessed"
       (tutorials_proj_dir ./fixtures/tutorials/nonexistent_chapter)
       (project nonexistent_chapter)))) |}]
;;

let%expect_test "reset workbench" =
  let project = "valid_project" in
  let reset_0 =
    reset_workbench
      ~make_backup:false
      ~tutorials_dir
      ~src_dir
      ~workbench_dir
      ~project
      ~chapter_index:0
  in
  print_s [%message (reset_0 : unit Or_error.t)];
  [%expect {| (reset_0 (Ok ())) |}];
  let curr_workbench = Mem_fs.read_from_dir (Filename.concat workbench_dir project) in
  print_s [%message (curr_workbench : string Mem_fs.t Or_error.t)];
  [%expect
    {|
    (curr_workbench
     (Ok
      ((root_dir fixtures/workbench/valid_project)
       (files
        ((/counter.ml
           "open! Core\
          \nopen Bonsai_web\
          \n\
          \nlet component = Computation.return (Vdom.Node.text \"Hello World\")\
          \n")
         (/main.ml
           "open Bonsai_web\
          \n\
          \nlet (_ : _ Start.Handle.t) =\
          \n  Start.start\
          \n    Start.Result_spec.just_the_view\
          \n    ~bind_to_element_with_id:\"app\"\
          \n    Counter.component\
          \n;;\
          \n")
         (/valid_project.opam "opam-version: \"2.0\"\n")))))) |}]
;;

let%expect_test "save diffs invalid project" =
  let project = "this_project_doesn't_exist" in
  let result = save_diffs ~tutorials_dir ~src_dir ~diffs_dir ~project in
  print_s [%message (result : unit Or_error.t)];
  [%expect
    {|
    (result
     (Error
      ("Tutorials directory is not a directory, doesn't exist, or couldn't be accessed"
       (tutorials_proj_dir ./fixtures/tutorials/this_project_doesn't_exist)
       (project this_project_doesn't_exist)))) |}]
;;

let%expect_test "save diffs" =
  let project = "valid_project" in
  let result = save_diffs ~tutorials_dir ~src_dir ~diffs_dir ~project in
  print_s [%message (result : unit Or_error.t)];
  [%expect {| (result (Ok ())) |}];
  let diffs_fs = Mem_fs.read_from_dir (Filename.concat diffs_dir project) in
  print_s [%message (diffs_fs : string Mem_fs.t Or_error.t)];
  [%expect
    {|
    (diffs_fs
     (Ok
      ((root_dir fixtures/diffs/valid_project)
       (files
        ((/0_to_1.patch
           "==== /.gitkeep ====\
          \n(Created empty file)\
          \n\
          \n==== /counter.ml ====\
          \n-1,4 +1,19\
          \n  open! Core\
          \n-|open Bonsai_web\
          \n+|open! Import\
          \n  \
          \n-|let component = Computation.return (Vdom.Node.text \"Hello World\")\
          \n+|let component ~label () =\
          \n+|  let%sub count, set_count = Bonsai.state (module Int) (module Action) ~default_model:0 in\
          \n+|  let%arr count = count\
          \n+|  and set_count = set_count\
          \n+|  and label = label in\
          \n+|  let view =\
          \n+|    Vdom.Node.(\
          \n+|      div\
          \n+|        [ span [ textf \"%s: \" label ]\
          \n+|        ; button ~attr:(Vdom.Attr.on_click (fun _ -> set_count (count - 1))) [ text \"-\" ]\
          \n+|        ; span [ textf \"%d\" count ]\
          \n+|        ; button ~attr:(Vdom.Attr.on_click (fun _ -> set_count (count + 1))) [ text \"+\" ]\
          \n+|        ])\
          \n+|  in\
          \n+|  view, state\
          \n+|;;\
          \n\
          \n==== /main.ml ====\
          \n-1,8 +1,11\
          \n  open Bonsai_web\
          \n+|open Bonsai_web_counters_example\
          \n+|\
          \n+|let this_is_here_for_the_diff = \"What if sandworms were Camels?\"\
          \n  \
          \n  let (_ : _ Start.Handle.t) =\
          \n    Start.start\
          \n      Start.Result_spec.just_the_view\
          \n      ~bind_to_element_with_id:\"app\"\
          \n      Counter.component\
          \n  ;;\
          \n\
          \n==== /new.ml ====\
          \n-1,0 +1,1\
          \n+|let this_file_was_created = \"to test diffs\"\
          \n")
         (/1_to_2.patch
           "==== /.gitkeep ====\
          \n(Deleted empty file)\
          \n\
          \n==== /counter.ml ====\
          \n-1,19 +1,39\
          \n  open! Core\
          \n  open! Import\
          \n+|open Bonsai_web\
          \n+|open Bonsai.Let_syntax\
          \n+|\
          \n+|module Action = struct\
          \n+|  type t =\
          \n+|    | Incr\
          \n+|    | Decr\
          \n+|  [@@deriving sexp_of]\
          \n+|end\
          \n+|\
          \n+|let apply_action ~inject:_ ~schedule_event:_ by model = function\
          \n+|  | Action.Incr -> model + by\
          \n+|  | Decr -> model - by\
          \n+|;;\
          \n-|let component ~label () =\
          \n-|  let%sub count, set_count = Bonsai.state (module Int) (module Action) ~default_model:0 in\
          \n+|\
          \n+|let component ~label ?(by = Value.return 1) () =\
          \n+|  let module N = Vdom.Node in\
          \n+|  let module A = Vdom.Attr in\
          \n+|  let%sub state_and_inject =\
          \n+|    Bonsai.state_machine1 (module Int) (module Action) ~default_model:0 ~apply_action by\
          \n+|  in\
          \n-|  let%arr count = count\
          \n-|  and set_count = set_count\
          \n+|  let%arr state, inject = state_and_inject\
          \n+|  and by = by\
          \n-|  and label = label in\
          \n-|  let view =\
          \n-|    Vdom.Node.(\
          \n-|      div\
          \n-|        [ span [ textf \"%s: \" label ]\
          \n+|  and label = label in\
          \n+|  let button op action =\
          \n+|    N.button ~attr:(A.on_click (fun _ -> inject action)) [ N.textf \"%s%d\" op by ]\
          \n+|  in\
          \n+|  let view =\
          \n+|    N.div\
          \n+|      [ N.span [ N.textf \"%s: \" label ]\
          \n-|        ; button ~attr:(Vdom.Attr.on_click (fun _ -> set_count (count - 1))) [ text \"-\" ]\
          \n-|        ; span [ textf \"%d\" count ]\
          \n+|      ; button \"-\" Decr\
          \n+|      ; N.span [ N.textf \"%d\" state ]\
          \n-|        ; button ~attr:(Vdom.Attr.on_click (fun _ -> set_count (count + 1))) [ text \"+\" ]\
          \n-|        ])\
          \n+|      ; button \"+\" Incr\
          \n+|      ]\
          \n    in\
          \n    view, state\
          \n  ;;\
          \n\
          \n==== /main.ml ====\
          \n-1,11 +1,9\
          \n  open Bonsai_web\
          \n  open Bonsai_web_counters_example\
          \n  \
          \n-|let this_is_here_for_the_diff = \"What if sandworms were Camels?\"\
          \n-|\
          \n  let (_ : _ Start.Handle.t) =\
          \n    Start.start\
          \n      Start.Result_spec.just_the_view\
          \n      ~bind_to_element_with_id:\"app\"\
          \n      Counter.component\
          \n  ;;\
          \n\
          \n==== /new.ml ====\
          \n-1,1 +1,0\
          \n-|let this_file_was_created = \"to test diffs\"\
          \n\
          \n==== /valid_project.opam ====\
          \n-1,1 +1,2\
          \n  opam-version: \"2.0\"\
          \n+|synopsis: \"Oops, forgot to add this\"\
          \n")))))) |}]
;;
