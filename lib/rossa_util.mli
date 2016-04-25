val finally: ('a -> 'b) -> 'a -> ('c -> unit) -> 'c -> 'b
(** [finally f x fin y] computes [f x] for the result and carries out
		[fin y] as a side effect afterwards, even in the presence of an
		exception from [f x]. *)

val meg : int -> int64
(** [meg n] = n*2^20 *)

val seq : int -> int list
(** [seq n] return a list of length [n] >=0 with members 1 .. [n]. We
    use this for the construction of host names. *)

