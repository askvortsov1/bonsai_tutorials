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
          \n\
          \n\
          \n==== /counter.ml ====\
          \n-1,28 +1,37\
          \n  open! Core\
          \n-|open Bonsai_web\
          \n-|open Bonsai.Let_syntax\
          \n+|open! Import\
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
          \n-|\
          \n-|(* $MDX part-begin=index_html *)\
          \n-|module Model = struct\
          \n-|  type t = unit Int.Map.t [@@deriving sexp, equal]\
          \n-|end\
          \n-|\
          \n-|let add_counter_component =\
          \n-|  let%sub add_counter_state =\
          \n+|\
          \n+|(* $MDX part-begin=index_html *)\
          \n+|let component ~label ?(by = Value.return 1) () =\
          \n+|  let%sub state_and_inject =\
          \n-|    Bonsai.state_machine0\
          \n-|      (module Model)\
          \n-|      (module Unit)\
          \n-|      ~default_model:Int.Map.empty\
          \n-|      ~apply_action:(fun ~inject:_ ~schedule_event:_ model () ->\
          \n-|        let key = Map.length model in\
          \n-|        Map.add_exn model ~key ~data:())\
          \n+|    Bonsai.state_machine1 (module Int) (module Action) ~default_model:0 ~apply_action by\
          \n-|  in\
          \n-|  let%arr state, inject = add_counter_state in\
          \n-|  let view =\
          \n-|    Vdom.Node.button\
          \n-|      ~attr:(Vdom.Attr.on_click (fun _ -> inject ()))\
          \n-|      [ Vdom.Node.text \"Add Another Counter\" ]\
          \n+|  in\
          \n+|  let%arr state, inject = state_and_inject\
          \n+|  and by = by\
          \n+|  and label = label in\
          \n+|  let button op action =\
          \n+|    N.button ~attr:(A.on_click (fun _ -> inject action)) [ N.textf \"%s%d\" op by ]\
          \n+|  in\
          \n+|  let view =\
          \n+|    N.div\
          \n+|      [ Vdom.Node.span [ N.textf \"%s: \" label ]\
          \n+|      ; button \"-\" Decr\
          \n+|      ; Vdom.Node.span [ N.textf \"%d\" state ]\
          \n+|      ; button \"+\" Incr\
          \n+|      ]\
          \n    in\
          \n-|  state, view\
          \n+|  view, state\
          \n  ;;\
          \n  (* $MDX part-end *)\
          \n\
          \n==== /main.ml ====\
          \n-1,6 +1,8\
          \n  open Bonsai_web\
          \n  open Bonsai_web_counters_example\
          \n  \
          \n+|let this_is_here_for_the_diff = \"What if sandworms were Camels?\"\
          \n+|\
          \n  let (_ : _ Start.Handle.t) =\
          \n    Start.start Start.Result_spec.just_the_view ~bind_to_element_with_id:\"app\" application\
          \n  ;;")))))) |}]
;;
