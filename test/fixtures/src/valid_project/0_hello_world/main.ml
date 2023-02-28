open Bonsai_web

let (_ : _ Start.Handle.t) =
  Start.start
    Start.Result_spec.just_the_view
    ~bind_to_element_with_id:"app"
    Counter.component
;;
