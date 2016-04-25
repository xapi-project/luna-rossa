(* vim: set et sw=2 softtabstop=2 ts=2: *)

module U      = Yojson.Basic.Util
module S      = Rossa_server
module C      = Rossa_config
module CMD    = Cmdliner

let printf    = Printf.printf
let sprintf   = Printf.sprintf
let fprintf   = Printf.fprintf
let eprintf   = Printf.eprintf

exception Error of string
let error fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt

(** find the named server in the inventory *)
let find name servers =
  try  S.find name servers 
  with Not_found -> error "host '%s' is unknown" name 


(** [main file_json hostname] is the heart of this test. The two
  * parameters are JSON objects describing the run-time parameter
  * for the test. This function is called from [main_t].
  *)
let main servers_json config_json  = 
    let servers   = S.read servers_json in
    let config    = C.read config_json "quicktest" in 
    let hostname  = config |> U.member "server" |> U.to_string in
    let qtest     = config |> U.member "path"   |> U.to_string in
    let server    = find hostname servers in (* path to binary *)
    let open Yorick in
      match !?* (?|>) "%s" (S.ssh server qtest) with
      | _     , 0   -> 
          echo "quicktest finished successfully"
      | stdout, rc  -> 
        ( echo "quicktest failed with exit code %d" rc
        ; echo "%s" stdout
        )


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
  let doc = "run on-board quicktest on a Xen Server" in
  let man = 
    [ `S "DESCRIPTION"
    ; `P "Run the on-board quicktest test suite on a server."
    ; `S "BUGS"
    ; `P "Report bug on the github issue tracker" 
    ] 
  in
  CMD.Term.info "quicktest" ~version:"1.0" ~doc ~man
    
let () = 
  match CMD.Term.eval (main_t, info) with 
  | `Error _  -> exit 1 
  | _         -> exit 0
