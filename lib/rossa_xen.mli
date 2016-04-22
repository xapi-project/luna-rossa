
type session  = string
type rpc      = Rpc.call -> Rpc.response Lwt.t
type user     = Rossa_server.user
type api      = Rossa_server.api

val with_session : api -> user -> (rpc -> string -> 'a Lwt.t) -> 'a Lwt.t
(** [with_session api user f] executes [f rpc session] in the context of
 * a [session] created for [user] at [api]. [session] is guaranteed to be
  * closed afterwards. The result is the one returned by [f].
  *)

val find_template : rpc -> session -> name: string -> API.vM_t option Lwt.t
(** [find_template rpc session name] returns the first template
  * that has name [name].
  *)

val create_mirage_vm : rpc -> session -> template:string -> string Lwt.t
(** [create_mirage_vm] creates a unikernel VM from a template and 
  * returns a handle for it
  *)
