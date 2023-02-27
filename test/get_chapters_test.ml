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
         ((root_dir fixtures/src/valid_project/0_hello_world)
          (files
           ((/counter.ml
              "open! Core\
             \nopen Bonsai_web\
             \n\
             \n(* $MDX part-begin=hello_world *)\
             \nlet component = Computation.return (Vdom.Node.text \"Hello World\")\
             \n(* $MDX part-end *)")
            (/main.ml
              "open Bonsai_web\
             \n\
             \nlet (_ : _ Start.Handle.t) =\
             \n  Start.start\
             \n    Start.Result_spec.just_the_view\
             \n    ~bind_to_element_with_id:\"app\"\
             \n    Counter.component\
             \n;;\
             \n"))))))
       ((readme "")
        (source
         ((root_dir fixtures/src/valid_project/1_raw_state)
          (files
           ((/counter.ml
              "open! Core\
             \nopen! Import\
             \n\
             \n(* $MDX part-begin=loose_state *)\
             \nlet component ~label () =\
             \n  let%sub count, set_count = Bonsai.state (module Int) (module Action) ~default_model:0 in\
             \n  let%arr count = count\
             \n  and set_count = set_count\
             \n  and label = label in\
             \n  let view =\
             \n    Vdom.Node.(\
             \n      div\
             \n        [ span [ textf \"%s: \" label ]\
             \n        ; button ~attr:(Vdom.Attr.on_click (fun _ -> set_count (count - 1))) [ text \"-\" ]\
             \n        ; span [ textf \"%d\" count ]\
             \n        ; button ~attr:(Vdom.Attr.on_click (fun _ -> set_count (count + 1))) [ text \"+\" ]\
             \n        ])\
             \n  in\
             \n  view, state\
             \n;;\
             \n(* $MDX part-end *)\
             \n")
            (/main.ml
              "open Bonsai_web\
             \nopen Bonsai_web_counters_example\
             \n\
             \nlet this_is_here_for_the_diff = \"What if sandworms were Camels?\"\
             \n\
             \nlet (_ : _ Start.Handle.t) =\
             \n  Start.start\
             \n    Start.Result_spec.just_the_view\
             \n    ~bind_to_element_with_id:\"app\"\
             \n    Counter.component\
             \n;;\
             \n")
            (/new.ml "let this_file_was_created = \"to test diffs\""))))))
       ((readme "")
        (source
         ((root_dir fixtures/src/valid_project/2_state_machine)
          (files
           ((/counter.ml
              "open! Core\
             \nopen! Import\
             \nopen Bonsai_web\
             \nopen Bonsai.Let_syntax\
             \n\
             \nmodule Action = struct\
             \n  type t =\
             \n    | Incr\
             \n    | Decr\
             \n  [@@deriving sexp_of]\
             \nend\
             \n\
             \nlet apply_action ~inject:_ ~schedule_event:_ by model = function\
             \n  | Action.Incr -> model + by\
             \n  | Decr -> model - by\
             \n;;\
             \n\
             \n(* $MDX part-begin=index_html *)\
             \nlet component ~label ?(by = Value.return 1) () =\
             \n  let module N = Vdom.Node in\
             \n  let module A = Vdom.Attr in\
             \n  let%sub state_and_inject =\
             \n    Bonsai.state_machine1 (module Int) (module Action) ~default_model:0 ~apply_action by\
             \n  in\
             \n  let%arr state, inject = state_and_inject\
             \n  and by = by\
             \n  and label = label in\
             \n  let button op action =\
             \n    N.button ~attr:(A.on_click (fun _ -> inject action)) [ N.textf \"%s%d\" op by ]\
             \n  in\
             \n  let view =\
             \n    N.div\
             \n      [ N.span [ N.textf \"%s: \" label ]\
             \n      ; button \"-\" Decr\
             \n      ; N.span [ N.textf \"%d\" state ]\
             \n      ; button \"+\" Incr\
             \n      ]\
             \n  in\
             \n  view, state\
             \n;;\
             \n(* $MDX part-end *)\
             \n")
            (/main.ml
              "open Bonsai_web\
             \nopen Bonsai_web_counters_example\
             \n\
             \nlet (_ : _ Start.Handle.t) =\
             \n  Start.start\
             \n    Start.Result_spec.just_the_view\
             \n    ~bind_to_element_with_id:\"app\"\
             \n    Counter.component\
             \n;;\
             \n"))))))))) |}]
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
