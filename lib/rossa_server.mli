(** This module provides access to the Xen Servers that are available 
 *  for testing
 *)

exception Error of string

type api = string
type user = 
  { username : string
  ; password : string 
  }

type t (* a Xen Server *)

val inventory : string -> t list
(** [inventory "file.json"] reads the inventory of available servers
  * from file.json 
  *)

val name :  t -> string 
(** unique within the servers available *)

val root :  t -> user 
(** credentials to access the Xen API on the server *)

val ssh :   t -> string -> string
(** [ssh t cmd] return a shell command as a string. Executing the shell
 * command locally leads to the execution of [cmd] on [t]. 
 * Caveat: this is fragile because of quoting issues and we need a
 * better wa here.
 *)

val api :   t -> api
(** URI for the Xen API on this server *)

val json:   t -> Yojson.Basic.json
(** JSON record for [t] from the inventory description. This can be used
 * to pass additional information to tests. *)
