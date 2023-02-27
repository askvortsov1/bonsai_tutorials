open Bonsai_web
open Bonsai_web_counters_example

let this_is_here_for_the_diff = "What if sandworms were Camels?"

let (_ : _ Start.Handle.t) =
  Start.start Start.Result_spec.just_the_view ~bind_to_element_with_id:"app" application
;;
