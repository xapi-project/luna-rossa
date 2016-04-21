(** This module provides access to the Xen Servers that are available 
 *  for testing
 *)

exception Error of string

type api = string
type user = 
  { username : string
  ; password : string 
  }

type t (* A Xen Server *)

val inventory : string -> t list
(** [inventory "file.json"] reads the inventory of available servers
  * from file.json 
  *)

val name :  t -> string 
(** unique within the servers available *)

val root :  t -> user 
(** credentials to access the Xen API on the server *)

val ssh :   t -> string list
(** Execute a shell command on the server *)

val api :   t -> api
(** URI for the Xen API on this server *)

