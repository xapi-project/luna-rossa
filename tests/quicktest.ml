

module CMD  = Cmdliner

let main host = ()

let name_arg =
  let doc = "Name of server in the inventory where quicktest is executed" in
  CMD.Arg.(value & pos 0 string "" & info [] ~docv:"NAME" ~doc)
    
let main_t = CMD.Term.(pure main $ name_arg)

let info =
  let doc = "Run quicktest on a Xen Server" in
  let man = [ `S "BUGS"; `P "Report bug on the github issue tracker" ] in
  CMD.Term.info "quicktest" ~version:"1.0" ~doc ~man
    
let () = 
  match CMD.Term.eval (main_t, info) with 
  | `Error _  -> exit 1 
  | _         -> exit 0
