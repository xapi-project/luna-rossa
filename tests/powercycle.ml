(* vim: set et sw=2 softtabstop=2 ts=2: *)

module U      = Yojson.Basic.Util
module S      = Rossa_server
module C      = Rossa_config
module X      = Rossa_xen
module CMD    = Cmdliner
module VM     = Xen_api_lwt_unix.VM
module E      = Api_errors

let return    = Xen_api_lwt_unix.return
let (>>=)     = Xen_api_lwt_unix.(>>=)
let sprintf   = Printf.sprintf
let pprintf   = Printf.printf


exception Error of string
let error fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt

(** [xs_write] writes a [value] to a Xen Store [path]. This
 * implementation uses SSH to do this.  *)
let xs_write server path value =
  let cmd = sprintf "xenstore write '%s' '%s'" path value in 
  match S.ssh server cmd with
  | 0 , _      -> return ()
  | rc, stdout -> X.fail "command [%s] failed with %d" cmd rc

(** [xs_testing] writes a value into "control/testing" in Xen Store for
 * [domid] on [server] *)
let xs_testing server domid value =
  xs_write 
    server 
    (sprintf "/local/domain/%Ld/control/testing" domid)
    value

(** find the named server in the inventory *)
let find name servers =
  try  S.find name servers 
  with Not_found -> error "host '%s' is unknown" name 

(** [log fmt] emit printf-style log message from a thread to stdout *)
let log fmt =
  Printf.kprintf (fun msg -> Lwt.return (print_endline @@ "# "^msg)) fmt

(** [ssh server cmd] executes [cmd] on [server] and fails in 
  * the case of an error *)
let ssh server cmd =
  match S.ssh server cmd with
  | 0 , stdout  -> ()
  | rc, stdout  -> error "executing [%s] failed with %d" cmd rc

(** [find_template] finds a template by [name] *)
let find_template rpc session name =
  X.find_template rpc session name >>= function
    | Some t -> return t
    | None   -> X.fail "can't find template %s" name

(** [create_vm] creates a VM using the kernel we have put into
 *  place during setup and returns the VM's handle from which it 
 *  can be started
 *)
let create_vm rpc session =
  let template  = "Other install media" in
  let kernel    = "/boot/guest/powercycle.xen.gz" in
  let clone     = "rossa-powercycle-vm" in
  let meg32     = Rossa_util.meg 32 in
  find_template rpc session template >>= fun (t,_) ->
  log "found template %s" template >>= fun () ->
  VM.clone rpc session t clone >>= fun vm ->
  VM.provision rpc session vm >>= fun _ -> 
  VM.set_PV_kernel rpc session vm kernel >>= fun () ->
  VM.set_HVM_boot_policy rpc session vm "" >>= fun () ->
  VM.set_memory_limits 
    ~rpc 
    ~session_id:session 
    ~self:vm 
    ~static_min:meg32 
    ~static_max:meg32 
    ~dynamic_min:meg32 
    ~dynamic_max:meg32 >>= fun () ->
  log "cloned '%s' to '%s'" template clone >>= fun () ->
  return vm

let powercycle server rpc session =
    create_vm rpc session >>= fun vm ->
    VM.start rpc session vm false false >>= fun () -> 
    Lwt.catch 
      (fun () ->
        log "VM started" >>= fun () ->
        VM.get_domid rpc session vm >>= fun domid ->
        log "VM domid is %Ld" domid >>= fun () ->
        Lwt_unix.sleep 5.0 >>= fun () ->
        VM.clean_shutdown rpc session vm >>= fun () ->
        log "VM shut down" >>= fun () ->
        VM.destroy rpc session vm >>= fun () ->
        log "VM destroyed" >>= fun () ->
        Lwt.return ())
    (function
      | E.Server_error("VM_BAD_POWER_STATE",_) ->
        log "caught exception (as expected) .. cleaning up" >>= fun () ->
        VM.destroy rpc session vm >>= fun () ->
        log "VM destroyed" >>= fun () ->
        Lwt.return ()
      | e -> Lwt.fail(e))


(** [join_by_nl] turns a JSON array of strings into a string where
 * the input strings are joined by newlines. We use this
 * for creating shell scripts from JSON arrays 
 * *)
let join_by_nl json =
  json 
  |> U.convert_each U.to_string 
  |> String.concat "\n"

(* [main] is the heart of this test *)
let main servers_json config_json  = 
  let servers   = S.read servers_json in
  let config    = C.read config_json "powercycle" in 
  let hostname  = config |> U.member "server" |> U.to_string in
  let server    = find hostname servers in
  let api       = S.api server in
  let root      = S.root server in
  let setup_sh  = config |> U.member "server-setup.sh"   |> join_by_nl in
  let cleanup_sh= config |> U.member "server-cleanup.sh" |> join_by_nl
  in
    try
      ( ssh server setup_sh 
      ; Lwt_main.run (X.with_session api root (powercycle server))
      ; ssh server cleanup_sh
      ; true
      )
    with
      _ -> false

