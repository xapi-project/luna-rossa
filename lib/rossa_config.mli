(** 
  * Read test configuration data from a JSON file
  *)

type t = string -> Yojson.Basic.json  (* Not_found *)
(** [t] is a lookup function that return the configuation for a named
 *  test as a JSON value 
 *)

val read: string -> t
(** [read file] reads a configuration from a JSON file. This can raise
 * exceptions in the case of errors.
 *)
