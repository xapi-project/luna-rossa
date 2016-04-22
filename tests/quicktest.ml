
module U    = Yojson.Basic.Util
module S    = Rossa_server
module CMD  = Cmdliner

let printf    = Printf.printf
let sprintf   = Printf.sprintf
let fprintf   = Printf.fprintf
let eprintf   = Printf.eprintf

exception Error of string
let error fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt


(** all hosts available for testing *)
let inventory json =
  S.inventory json |> List.map (fun server -> S.name server, server)

(** find the named host in the inventory *)
let find_host name inventory =
  try List.assoc name inventory with 
  | Not_found -> error "host '%s' is unknown" name 

(** [quicktest_path host] returns the path to quicktest on the server. This
 * information is expected to be found in the JSON record
 *)
let quicktest_path host = 
  S.json host |> U.member "xen" |> U.member "quicktest" |> U.to_string

(* [main file_json hostname] is the heart of this test *)
let main file_json hostname = 
    let host = inventory file_json |> find_host hostname in
    let qt   = quicktest_path host in
    let open Yorick in
    match !?* (?|>) "%s" (S.ssh host qt) with
    | _     , 0   -> 
        echo "quicktest finished successfully"
    | stdout, rc  -> 
      ( echo "quicktest failed with exit code %d" rc
      ; echo "%s" stdout
      )

let json_arg =
  let doc = "JSON file describing server inventory" in
  CMD.Arg.(required 
    & pos 0 (some file) None 
    & info [] ~docv:"INVENTORY" ~doc)
 
let name_arg =
  let doc = "Name of server in the inventory where quicktest is executed" in
  CMD.Arg.(required 
    & pos 1 (some string) None 
    & info [] ~docv:"NAME" ~doc)
    
let main_t = CMD.Term.(const main $ json_arg $ name_arg)

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
