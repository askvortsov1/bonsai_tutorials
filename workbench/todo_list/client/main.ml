open! Core
open! Async_kernel
open! Bonsai_web

let run () =
  let (_ : _ Start.Handle.t) =
    Start.start Start.Result_spec.just_the_view ~bind_to_element_with_id:"app"
      App.component
  in
  return ()

let () = don't_wait_for (run ())
