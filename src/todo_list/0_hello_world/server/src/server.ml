open! Core
open! Async

let not_found_html =
  {|
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>404 Not Found</title>
  </head>
  <body>
    <h1>404 Not Found</h1>
  </body>
</html>
|}

(* $MDX part-begin=index_html *)
let html =
  {|
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <script defer src="main.js"></script>
    <title> TODO-List </title>
  </head>

  <body>
    <div id="app"></div>
  </body>
</html>
|}
(* $MDX part-end *)

(* $MDX part-begin=handler *)
let respond_string ~content_type ?flush ?headers ?status s =
  let headers = Cohttp.Header.add_opt headers "Content-Type" content_type in
  Cohttp_async.Server.respond_string ?flush ~headers ?status s

let handler ~body:_ _inet req =
  let path = Uri.path (Cohttp.Request.uri req) in
  match path with
  | "" | "/" | "/index.html" -> respond_string ~content_type:"text/html" html
  | "/main.js" ->
      respond_string ~content_type:"application/javascript"
        Embedded_files.main_dot_bc_dot_js
  | _ ->
      respond_string ~content_type:"text/html" ~status:`Not_found not_found_html
(* $MDX part-end *)

(* $MDX part-begin=server_wrapper *)
let initialize_connection _initiated_from _addr _inet connection = connection

let main ~port =
  let hostname = Unix.gethostname () in
  printf "Serving http://%s:%d/\n%!" hostname port;
  let%bind server =
    let http_handler () = handler in
    Rpc_websocket.Rpc.serve ~on_handler_error:`Ignore ~mode:`TCP
      ~where_to_listen:(Tcp.Where_to_listen.of_port port)
      ~http_handler
      ~implementations:
        (Rpc.Implementations.create_exn ~implementations:[]
           ~on_unknown_rpc:`Continue)
      ~initial_connection_state:initialize_connection ()
  in
  Cohttp_async.Server.close_finished server
(* $MDX part-end *)

(* $MDX part-begin=command *)
let command =
  Command.async ~summary:"Start server for todo-list"
    (let%map_open.Command port =
       flag "port"
         (optional_with_default 8080 int)
         ~doc:"port on which to serve"
     in
     fun () -> main ~port)
(* $MDX part-end *)
