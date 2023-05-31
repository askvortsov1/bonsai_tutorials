open! Core
open! Async_kernel
open! Bonsai_web

(* $MDX part-begin=tasks *)
(* This is here temporarily until we move it to the server. *)
let global_tasks =
  let open Month in
  Value.return
    [ { Common.Task.title = "Buy groceries"
      ; id = 0
      ; completion_status = Completed (Date.create_exn ~y:2022 ~m:Feb ~d:10)
      ; due_date = Date.create_exn ~y:2023 ~m:Feb ~d:8
      ; description =
          {|
            Going to make creme brulee! I need:
            - Heavy cream
            - Vanilla extract
            - Eggs
            - Sugar
          |}
      }
    ; { title = "Create a Bonsai tutorial"
      ; id = 1
      ; completion_status = Todo
      ; due_date = Date.create_exn ~y:2023 ~m:Aug ~d:28
      ; description =
          {|
            Bonsai is awesome and I want to help make it easier to learn!
          |}
      }
    ; { title = "Study for MATH502 exam"
      ; id = 2
      ; completion_status = Todo
      ; due_date = Date.create_exn ~y:2023 ~m:Feb ~d:15
      ; description =
          {|
            I should go through homeworks again, and solve textbook exercises.
          |}
      }
    ]
;;

(* $MDX part-end *)

(* $MDX part-begin=with_tasks *)

let () = Bonsai_web.Start.start (App.component ~tasks:global_tasks)

(* $MDX part-end *)
