open! Core

type t = {
  completed_on : Date.t option;
  due_date : Date.t;
  title : string;
  description : string;
}
[@@deriving sexp, bin_io, fields]
