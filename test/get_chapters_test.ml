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
         ((root_dir fixtures/src/valid_project/0_intro)
          (files
           ((/counter.ml
             ("open! Core" "open Bonsai_web" "open Bonsai.Let_syntax" ""
              "(* $MDX part-begin=index_html *)" "module Model = struct"
              "  type t = unit Int.Map.t [@@deriving sexp, equal]" end ""
              "let add_counter_component =" "  let%sub add_counter_state ="
              "    Bonsai.state_machine0" "      (module Model)"
              "      (module Unit)" "      ~default_model:Int.Map.empty"
              "      ~apply_action:(fun ~inject:_ ~schedule_event:_ model () ->"
              "        let key = Map.length model in"
              "        Map.add_exn model ~key ~data:())" "  in"
              "  let%arr state, inject = add_counter_state in" "  let view ="
              "    Vdom.Node.button"
              "      ~attr:(Vdom.Attr.on_click (fun _ -> inject ()))"
              "      [ Vdom.Node.text \"Add Another Counter\" ]" "  in"
              "  state, view" ";;" "(* $MDX part-end *)"))
            (/main.ml
             ("open Bonsai_web" "open Bonsai_web_counters_example" ""
              "let (_ : _ Start.Handle.t) ="
              "  Start.start Start.Result_spec.just_the_view ~bind_to_element_with_id:\"app\" application"
              ";;")))))))
       ((readme "")
        (source
         ((root_dir fixtures/src/valid_project/1_frontend)
          (files
           ((/.gitkeep ())
            (/counter.ml
             ("open! Core" "open! Import" "" "module Action = struct"
              "  type t =" "    | Incr" "    | Decr" "  [@@deriving sexp_of]" end
              ""
              "let apply_action ~inject:_ ~schedule_event:_ by model = function"
              "  | Action.Incr -> model + by" "  | Decr -> model - by" ";;" ""
              "(* $MDX part-begin=index_html *)"
              "let component ~label ?(by = Value.return 1) () ="
              "  let%sub state_and_inject ="
              "    Bonsai.state_machine1 (module Int) (module Action) ~default_model:0 ~apply_action by"
              "  in" "  let%arr state, inject = state_and_inject" "  and by = by"
              "  and label = label in" "  let button op action ="
              "    N.button ~attr:(A.on_click (fun _ -> inject action)) [ N.textf \"%s%d\" op by ]"
              "  in" "  let view =" "    N.div"
              "      [ Vdom.Node.span [ N.textf \"%s: \" label ]"
              "      ; button \"-\" Decr"
              "      ; Vdom.Node.span [ N.textf \"%d\" state ]"
              "      ; button \"+\" Incr" "      ]" "  in" "  view, state" ";;"
              "(* $MDX part-end *)"))
            (/main.ml
             ("open Bonsai_web" "open Bonsai_web_counters_example" ""
              "let this_is_here_for_the_diff = \"What if sandworms were Camels?\""
              "" "let (_ : _ Start.Handle.t) ="
              "  Start.start Start.Result_spec.just_the_view ~bind_to_element_with_id:\"app\" application"
              ";;")))))))))) |}]
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
