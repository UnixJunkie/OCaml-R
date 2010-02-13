module Stub = struct

  (*   Information about the content of R standard library:
    *  http://stat.ethz.ch/R-manual/R-patched/doc/html/packages.html *)

  (*   Information about the R base package:
    *  http://stat.ethz.ch/R-manual/R-patched/library/base/html/00Index.html *)

  let sample = R.symbol "sample"

  let lapply = R.symbol "lapply"

  let tilde = R.symbol "~"

end

let sample (x : 'a list R.t) size ?replace ?(prob: float list option) () : 'a list R.t =
  (* Note that size may be left out in this R function. This
     behaviour does not fit the R.arg behaviour, nor does it
     fit the R.opt behaviour (since the argument should be
     named. This type of argument has to be worked out... *)
  R.eval Stub.sample [
    (R.arg (fun x -> x)             x)      ;
    (R.arg R.int                    size)   ;
    (R.opt R.bool         "replace" replace);
    (R.opt R.floats       "prob"    prob)   ]

let lapply (x : 'a list R.t) (func : 'b R.t) : 'c list R.t =
  (* It would be nice to solve once and for all the typing of
     R.t values by using the 'private' keyword to access the
     underlying R.sexp value by subtyping, and by using
     polymorphic variants for the parametrised typing of R.t. *)
  (* There is a ... in the args of lapply, for params passed
     to the function 'func'. Might be intelligent to wrap it up. *)
  R.eval Stub.lapply [
    (R.arg (fun x -> x) x)    ;
    (R.arg (fun x -> x) func) ]

let tilde (x : 'a R.t) (y : 'a R.t) : 'c R.t =
  R.eval Stub.tilde [
    (R.arg (fun x -> x) x)    ;
    (R.arg (fun x -> x) y)    ]
