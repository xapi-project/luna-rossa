
(** 
 * Read configuration data from a JSON file
 *)

type t =
  { servers:  Rossa_server.t list
  ; test:     string -> Yojson.Basic.json  (* Not_found *)
  }

val read: string -> t
(** [read file] reads a configuration from a JSON file. This can raise
 * exceptions in the case of errors *)
