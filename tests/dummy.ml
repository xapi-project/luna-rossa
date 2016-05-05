(* This is a template for adding new tests *)

module U      = Yojson.Basic.Util
module S      = Rossa_server
module C      = Rossa_config

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


let test servers hostname =
  let cmd     = sprintf "date --rfc-2822" in
  let server  = find hostname servers in 
    match S.ssh server cmd with
    | 0,  stdout   -> 
      ( echo "# success: %s: %s" hostname stdout
      ; 0
      )
    | rc, stdout  -> 
      ( echo "# failure: %s failed with exit code %d" hostname rc
      ; echo "%s" stdout
      ; rc
      )

(** [main file_json hostname] is the heart of this test. The two
  * parameters are JSON objects describing the run-time parameter
  * for the test. This function is called from [lunarossa.ml]
  *)
let main servers_json config_json  = 
    let servers   = S.read servers_json in
    let config    = C.read config_json "dummy" in 
    let hostnames = config 
      |> U.member "servers" |> U.convert_each U.to_string in
      hostnames
      |> List.map (test servers)
      |> List.for_all ((=) 0)   (* return true for success *)


