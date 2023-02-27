open! Core
open Infra_src

(* let src_dir = "../src"
let tutorials_dir = "../tutorials"
let workbench_dir = "../workbench"
let serialize ~path:_ f = String.concat ~sep:"\n" f

let%expect_test "reset workbench" =
  let get_workbench () =
    Mem_fs.read_from_dir ~f:String.split_lines "../workbench/todo_list"
  in
  let prev_workbench = get_workbench () in
  let project = "todo_list" in
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
  [%expect {||}];
  let diff =
    let open Or_error.Let_syntax in
    let curr_workbench = get_workbench () in
    let%bind curr_workbench = curr_workbench
    and prev_workbench = prev_workbench in
    Or_error.return (Mem_fs.diff ~serialize prev_workbench curr_workbench)
  in
  print_s [%message (diff : string Map.M(String).t Or_error.t)];
  [%expect
    {|
    (files
     (Ok
      (./fixtures/read_env/file.ml ./fixtures/read_env/poem.txt
       ./fixtures/read_env/file/README.md
       ./fixtures/read_env/file/nested2/nested3/leaf
       ./fixtures/read_env/file/nested2/leaf
       "./fixtures/read_env/file/spaces in file name.txt"
       ./fixtures/read_env/dune))) |}]
;; *)
let tutorials_dir = "./fixtures/tutorials"
let src_dir = "./fixtures/src"
let diffs_dir = "./fixtures/diffs"

let%expect_test "save diffs" =
  let project = "valid_project" in
  let reset_0 = save_diffs ~tutorials_dir ~src_dir ~diffs_dir ~project in
  print_s [%message (reset_0 : unit Or_error.t)];
  [%expect {| (reset_0 (Ok ())) |}];
  let diffs_fs =
    Mem_fs.read_from_dir ~f:String.split_lines (Filename.concat diffs_dir project)
  in
  print_s [%message (diffs_fs : string list Mem_fs.t Or_error.t)];
  [%expect
    {|
    (diffs_fs
     (Ok
      ((root_dir fixtures/diffs/valid_project)
       (files
        ((/0_to_1.patch
          ("==== /.gitkeep ====" "" "" "==== /counter.ml ====" "-1,28 +1,37"
           "  open! Core" "-|open Bonsai_web" "-|open Bonsai.Let_syntax"
           "+|open! Import" +| "+|module Action = struct" "+|  type t ="
           "+|    | Incr" "+|    | Decr" "+|  [@@deriving sexp_of]" +|end +|
           "+|let apply_action ~inject:_ ~schedule_event:_ by model = function"
           "+|  | Action.Incr -> model + by" "+|  | Decr -> model - by" "+|;;" -|
           "-|(* $MDX part-begin=index_html *)" "-|module Model = struct"
           "-|  type t = unit Int.Map.t [@@deriving sexp, equal]" -|end -|
           "-|let add_counter_component =" "-|  let%sub add_counter_state =" +|
           "+|(* $MDX part-begin=index_html *)"
           "+|let component ~label ?(by = Value.return 1) () ="
           "+|  let%sub state_and_inject =" "-|    Bonsai.state_machine0"
           "-|      (module Model)" "-|      (module Unit)"
           "-|      ~default_model:Int.Map.empty"
           "-|      ~apply_action:(fun ~inject:_ ~schedule_event:_ model () ->"
           "-|        let key = Map.length model in"
           "-|        Map.add_exn model ~key ~data:())"
           "+|    Bonsai.state_machine1 (module Int) (module Action) ~default_model:0 ~apply_action by"
           "-|  in" "-|  let%arr state, inject = add_counter_state in"
           "-|  let view =" "-|    Vdom.Node.button"
           "-|      ~attr:(Vdom.Attr.on_click (fun _ -> inject ()))"
           "-|      [ Vdom.Node.text \"Add Another Counter\" ]" "+|  in"
           "+|  let%arr state, inject = state_and_inject" "+|  and by = by"
           "+|  and label = label in" "+|  let button op action ="
           "+|    N.button ~attr:(A.on_click (fun _ -> inject action)) [ N.textf \"%s%d\" op by ]"
           "+|  in" "+|  let view =" "+|    N.div"
           "+|      [ Vdom.Node.span [ N.textf \"%s: \" label ]"
           "+|      ; button \"-\" Decr"
           "+|      ; Vdom.Node.span [ N.textf \"%d\" state ]"
           "+|      ; button \"+\" Incr" "+|      ]" "    in" "-|  state, view"
           "+|  view, state" "  ;;" "  (* $MDX part-end *)" ""
           "==== /main.ml ====" "-1,6 +1,8" "  open Bonsai_web"
           "  open Bonsai_web_counters_example" "  "
           "+|let this_is_here_for_the_diff = \"What if sandworms were Camels?\""
           +| "  let (_ : _ Start.Handle.t) ="
           "    Start.start Start.Result_spec.just_the_view ~bind_to_element_with_id:\"app\" application"
           "  ;;"))))))) |}]
;;
