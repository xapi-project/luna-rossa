(** This module provides access to the Xen Servers that are available 
 *  for testing
 *)

exception Error of string

type api = string (* a URI like http://hostname *)
type user = 
  { username : string
  ; password : string 
  }

type t (* a Xen Server *)

val read: string -> t list
(** [read servers_json] read a file [servers_json] that describes 
    a set of servers that are available for testing *)

val find: string -> t list -> t (* Not_found *)
(** [find name ts] finds a server by name in a list of servers or raise
    [Not_found] *)


val name :  t -> string 
(** name of a server, it should be unique within a config file *)

val root :  t -> user 
(** credentials to access the Xen API on the server *)

val ssh :   t -> string -> int * string
(** [ssh t cmd] executes [cmd] in a shell on server [t]. The result
 * is the return code and the output from stdout of that execution.
 * Any return code different from 0 is considered a failure.
 *
 * This function raises an exception if the process on the server
 * gets unexpectedly killed.
 *)

val api :   t -> api
(** URI for the Xen API on this server *)


