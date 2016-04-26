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
let error fmt = Printf.ksprintf (fun msg -> raise (Error msg)) fmt

(** find the named server in the inventory *)
let find name servers =
  try  S.find name servers 
  with Not_found -> error "host '%s' is unknown" name 

(** [test] runs a single qucktest [subtest] on [server]. The quicktest
 * binary can be found at [path]. *)
let test server path subtest =
  let cmd = S.ssh server "%s -single %s" path subtest in
  let open Yorick in
    match !?* (?|>) "%s" cmd with
    | _     , 0   -> 
        echo "# quicktest (%-25s) finished successfully" subtest
    | stdout, rc  -> 
      ( echo "# quicktest (%-25s) failed with exit code %d" subtest rc
      ; echo "%s" stdout
      )

(** [main file_json hostname] is the heart of this test. The two
  * parameters are JSON objects describing the run-time parameter
  * for the test. This function is called from [main_t].
  *)
let main servers_json config_json  = 
    let servers   = S.read servers_json in
    let config    = C.read config_json "quicktest" in 
    let hostname  = config |> U.member "server"   |> U.to_string in
    let path      = config |> U.member "path"     |> U.to_string in
    let server    = find hostname servers in (* path to binary *)
      config 
      |> U.member "subtests"
      |> U.convert_each U.to_string 
      |> List.iter (test server path)

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
