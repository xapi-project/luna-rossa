
module U    = Yojson.Basic.Util
module S    = Rossa_server
module C    = Rossa_config
module CMD  = Cmdliner

let printf    = Printf.printf
let sprintf   = Printf.sprintf
let fprintf   = Printf.fprintf
let eprintf   = Printf.eprintf

exception Error of string
let error fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt

(** find the named host in the inventory *)
let find_host name hosts =
  try  List.find (fun h -> S.name h = name) hosts 
  with 
    Not_found -> error "host '%s' is unknown" name 


(* [main file_json hostname] is the heart of this test *)
let main config_file  = 
    let config    = C.read config_file in 
    let config'   = config.C.test "quicktest" in
    let hostname  = config' |> U.member "host" |> U.to_string in
    let qt =      = config' |> U.member "path" |> U.to_string in
    let host      = find_host hostname config.C.servers in
    let open Yorick in
      match !?* (?|>) "%s" (S.ssh host qt) with
      | _     , 0   -> 
          echo "quicktest finished successfully"
      | stdout, rc  -> 
        ( echo "quicktest failed with exit code %d" rc
        ; echo "%s" stdout
        )

let json_arg =
  let doc = "JSON file describing configuration" in
  CMD.Arg.(required 
    & pos 0 (some file) None 
    & info [] ~docv:"config.json" ~doc)
   
let main_t = CMD.Term.(const main $ json_arg)

let info =
  let doc = "Run quicktest on a Xen Server" in
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
