open! Core
open! Bonsai_web
open Common

(* This is here temporarily until we move it to the server. *)
let global_tasks =
  let open Month in
  Value.return
    [
      {
        Task.title = "Buy groceries";
        completed_on = Some (Date.create_exn ~y:2022 ~m:Feb ~d:10);
        due_date = Date.create_exn ~y:2023 ~m:Feb ~d:8;
        description =
          {|
            Going to make creme brulee! I need:
            - Heavy cream
            - Vanilla extract
            - Eggs
            - Sugar
          |};
      };
      {
        Task.title = "Create a Bonsai tutorial";
        completed_on = None;
        due_date = Date.create_exn ~y:2023 ~m:Aug ~d:28;
        description =
          {|
            Bonsai is awesome and I want to help make it easier to learn!
          |};
      };
      {
        Task.title = "Study for complex analysis exam";
        completed_on = None;
        due_date = Date.create_exn ~y:2023 ~m:Feb ~d:15;
        description =
          {|
            I should go through homeworks again, and solve exercise textbook problems.
          |};
      };
    ]

let component = Tasks.component ~tasks:global_tasks
