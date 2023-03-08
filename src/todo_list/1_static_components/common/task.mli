open! Core

module Completion_status : sig
  type t = Todo | Completed of Date.t [@@deriving sexp, bin_io, variants]
end

type t = {
  id : int;
  title : string;
  description : string;
  due_date : Date.t;
  completion_status : Completion_status.t;
}
[@@deriving sexp, bin_io, fields]
