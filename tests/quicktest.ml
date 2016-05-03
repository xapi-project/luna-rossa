

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

let echo fmt = Printf.ksprintf (fun msg -> print_endline msg) fmt

(** find the named server in the inventory *)
let find name servers =
  try  S.find name servers 
  with Not_found -> error "host '%s' is unknown" name 

(** [test] runs a single qucktest [subtest] on [server]. The quicktest
 * binary can be found at [path]. *)
let test server path subtest =
  let cmd = sprintf "sudo %s -single %s" path subtest in
    match S.ssh server cmd with
    | 0,  stdout   -> 
      ( echo "# quicktest (%-25s) finished successfully" subtest
      ; 0
      )
    | rc, stdout  -> 
      ( echo "# quicktest (%-25s) failed with exit code %d" subtest rc
      ; echo "%s" stdout
      ; rc
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
      |> List.map (test server path)
      |> List.for_all ((=) 0)


