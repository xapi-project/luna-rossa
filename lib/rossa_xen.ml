(** This module provides functions on top of the Xen API that supoorts
 * writing test cases
 *)

module VM       = Xen_api_lwt_unix.VM
module Session  = Xen_api_lwt_unix.Session
module S        = Rossa_server

let make   = Xen_api_lwt_unix.make
let return = Xen_api_lwt_unix.return
let (>>=)  = Xen_api_lwt_unix.(>>=)

type origin =
  { system:     string
  ; version:    string
  }

let origin =
  { system  = "Rossa"
  ; version = "1.0"
  }

type session  = string
type rpc      = Rpc.call -> Rpc.response Lwt.t
type user     = Rossa_server.user   (* API credentials *)
type api      = Rossa_server.api    (* API end point *)  


(** [fail msg] makes a thread fail with a printf-style [msg] *) 
let fail fmt = Printf.kprintf (fun msg -> Lwt.fail (Failure msg)) fmt 

(** [find_template rpc session name] returns the first template
 * that has name [name] or fails with [Failure msg]
 *)
let find_template rpc session ~name =
  VM.get_all_records rpc session >>= fun vms ->
  let is_template = function
    | _,  { API.vM_name_label    = name
          ; API.vM_is_a_template = true 
          } -> true
    | _, _ -> false 
  in 
    match List.filter is_template vms with
    | []          -> fail "No template named '%s' found" name
    | (x,_) :: _  -> return x

(** [create_mirage_vm] creates a mirage VM from a suitable template
 *)
let create_mirage_vm rpc session ~template =
  let meg32 = Rossa_util.meg 32 in
  VM.clone rpc session template "mirage" >>= fun vm ->
  VM.provision rpc session vm >>= fun _ ->
  (* VM.set_PV_kernel rpc session vm path_to_kernel >>= fun () -> *)
  VM.set_HVM_boot_policy rpc session vm "" >>= fun () ->
  VM.set_memory_limits 
    ~rpc 
    ~session_id:session 
    ~self:vm 
    ~static_min:meg32 
    ~static_max:meg32 
    ~dynamic_min:meg32 
    ~dynamic_max:meg32 >>= fun () ->
  Lwt.return vm


(** [with_session api user f] executes [f rpc session] in the context of
 * a [session] created for [user] at [api]. [session] is guaranteed to be
  * closed afterwards.
  *)
let with_session api user f =
    let rpc = make api in 
    Session.login_with_password rpc 
      user.S.username user.S.password 
      origin.version origin.system
    >>= fun session ->
    Lwt.catch 
      (fun () ->
        f rpc session >>= fun result ->
        Session.logout rpc session >>= fun () ->
        return result)
      (fun e -> 
        Session.logout rpc session >>= fun () -> Lwt.fail e)

