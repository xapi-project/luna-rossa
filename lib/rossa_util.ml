
(** [meg n] = n*2^20 *)
let meg n = Int64.(mul 1024L @@ mul 1024L @@ of_int n)


(** [seq n] return a list of length [n] >=0 with members 1 .. [n]. *)
let seq n = 
  let rec loop lst = function
  | 0 -> lst
  | n -> loop (n::lst) (n-1)
  in 
    loop [] n



