(* vim: set sw=2 ts=2 et *)

module Y  = Yojson.Basic
module U  = Yojson.Basic.Util


exception Error of string
let fail fmt = Printf.kprintf (fun msg -> raise (Error msg)) fmt 

type user =
  { username:   string
  ; password:   string
  }

type api = string

(** Xen Sever host *)
type t = 
  { name:   string
  ; ssh:    string list
  ; api:    string
  ; root:   user
  ; json:   Y.json
  }

let name t = t.name
let api  t = t.api
let root t = t.root
let json t = t.json

(** [wait pid] wait for process [pid] to terminate *)
let wait pid = match Unix.waitpid [] pid with
  | (_,Unix.WEXITED k)	  -> k
  | (_,Unix.WSIGNALED _)  -> fail "child %d unexpectedly signaled" pid
  | (_,Unix.WSTOPPED _)	  -> fail "child %d unexpectedly stopped" pid

  (** [exec cmd args] executes [cmd] with [arguments] as a new process.
   * [cmd] is searched along the current PATH. [argumens] are *not*
   * interpreted by a shell.
   *)
let exec cmd args =
  let execv = cmd::args |> Array.of_list in
  let buf = Buffer.create (5*80) in
  let rstdout, stdout = Unix.pipe () in
  let stdin  , stderr = Unix.stdin, Unix.stderr in
    let () = Unix.set_close_on_exec rstdout in
    let rc = wait (Unix.create_process cmd execv stdin stdout stderr) in
    let () = Unix.close stdout in
    let stdout = Unix.in_channel_of_descr rstdout in
      begin 
        try while true do Buffer.add_channel buf stdout 1 done
        with End_of_file -> close_in stdout
      end;
      rc, Buffer.contents buf


let ssh t arg =
  match t.ssh with
    | []        -> fail "no ssh command found in JSON server record"
    | cmd::args -> exec cmd (args@[arg])

(** parse a server object from the JSON inventory *)
let server json =
  let name = json |> U.member "name"|> U.to_string  in
  let ssh  = json |> U.member "ssh" |> U.to_list |> List.map U.to_string in
  let xen  = json |> U.member "xen" in
  let api  = xen  |> U.member "api" |> U.to_string in
  let user = xen  |> U.member "user"|> U.to_string in
  let pw   = xen  |> U.member "password" |> U.to_string in
    { name = name
    ; ssh  = ssh
    ; api  = api
    ; json = json
    ; root =  { username = user
              ; password = pw
              }
    }

(** [read file_json] reads the server configuration from a JSON file
  * and returns them as a [t list] value.
  *)
let read file_json =
  Y.from_file file_json 
  |> U.member "servers" 
  |> U.to_list 
  |> List.map server 


(** [find name ts] finds a server by name in a list of servers
  *)
let find name ts = List.find (fun t -> t.name = name) ts 
