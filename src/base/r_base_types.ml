class type ['a] list_ = object
  inherit ['a] R.s3 constraint 'a = < .. >
  method ty : 'a
  method length : int
  method subset2_s : 'b. string -> 'b
  method subset2_i : 'b. string -> 'b
end

class type ['a] data'frame  = object
  inherit ['a] list_
  method dim : int * int
end

