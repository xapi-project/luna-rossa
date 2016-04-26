(* vim: set et sw=2 softtabstop=2 ts=2: *)

module U      = Yojson.Basic.Util
module S      = Rossa_server
module C      = Rossa_config
module X      = Rossa_xen
module CMD    = Cmdliner
module VM     = Xen_api_lwt_unix.VM

let return    = Xen_api_lwt_unix.return
let (>>=)     = Xen_api_lwt_unix.(>>=)

exception Error of string
let error fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt

(** [xs_write] writes a [value] to a Xen Store [path]. This
 * implementation uses SSH to do this.  *)
let xs_write server path value =
  let cmd = S.ssh server "xenstore write '%s' '%s'" path value in 
    Yorick.(?| cmd)

(** find the named server in the inventory *)
let find name servers =
  try  S.find name servers 
  with Not_found -> error "host '%s' is unknown" name 

(** [log fmt] emit printf-style log message from a thread to stdout *)
let log fmt =
  Printf.kprintf (fun msg -> Lwt.return (print_endline @@ "# "^msg)) fmt

(** [finf_template] finds a template by [name] *)
let find_template rpc session name =
  X.find_template rpc session name >>= function
    | Some t -> return t
    | None   -> X.fail "can't find template %s" name

let powercycle template rpc session =
  let clone = "rossa-mirage-vm" in
  let meg32 = Rossa_util.meg 32 in
  find_template rpc session template >>= fun (t,_) ->
  log "found template %s" template >>= fun () ->
  VM.clone rpc session t clone >>= fun vm ->
  VM.provision rpc session vm >>= fun _ ->
  VM.set_memory_limits 
    ~rpc 
    ~session_id:session 
    ~self:vm 
    ~static_min:meg32 
    ~static_max:meg32 
    ~dynamic_min:meg32 
    ~dynamic_max:meg32 >>= fun () ->
  log "cloned '%s' to '%s'" template clone >>= fun () ->
  VM.start rpc session vm false false >>= fun () -> 
  log "VM started" >>= fun () ->
  (* VM.suspend rpc session vm >>= fun () ->
   * log "VM suspended" >>= fun () ->
   * VM.resume rpc session vm true true >>= fun () ->
   * log "VM resumed" >>= fun () ->
   *)
  VM.clean_shutdown rpc session vm >>= fun () ->
  log "VM shut down" >>= fun () ->
  VM.destroy rpc session vm >>= fun () ->
  log "VM destroyed" >>= fun () ->
  Lwt.return ()

(* [main] is the heart of this test *)
let main servers_json config_json  = 
  let servers   = S.read servers_json in
  let config    = C.read config_json "powercycle" in 
  let hostname  = config |> U.member "server" |> U.to_string in
  let template  = config |> U.member "vm" |> U.to_string in
  let server    = find hostname servers in
  let api       = S.api server in
  let root      = S.root server in
    Lwt_main.run (X.with_session api root (powercycle template))

let servers =
  let doc = "JSON file describing Xen Servers available for testing." in
  CMD.Arg.(value
    & opt file "etc/servers.json" 
    & info ["s"; "servers"] ~docv:"servers.json" ~doc)
 
let config =
  let doc = "JSON file describing test configurations." in
  CMD.Arg.(value
    & opt file "etc/tests.json"
    & info ["c"; "config"] ~docv:"tests.json" ~doc)
   
let main_t = CMD.Term.(const main $ servers $ config)

let info =
  let doc = "Start a Mirage VM and powercycle it" in
  let man = 
    [ `S "DESCRIPTION"
    ; `P "Start a VM and go through a powercycle with it."
    ; `S "BUGS"
    ; `P "Report bug on the github issue tracker" 
    ] 
  in
  CMD.Term.info "powercycle" ~version:"1.0" ~doc ~man
    
let () = 
  match CMD.Term.eval (main_t, info) with 
  | `Error _  -> exit 1 
  | _         -> exit 0
