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

val make : Yojson.Basic.json -> t list
(** [make] creates a list of servers from a JSON array *)

val name :  t -> string 
(** name of a server, it should be unique within a config file *)

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
(** JSON record for [t] from the configuraion description. This can be used
 * to pass additional information to tests. *)
