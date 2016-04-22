
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

(** [ssh t cmd] return a shell command as a string. Executing the shell
 * command locally leads to the execution of [cmd] on [t]. 
 * Caveat: this is fragile because of quoting issues and we need a
 * better wa here.
 *)

let ssh  t cmd = String.concat " " (t.ssh @ [cmd])

(** parse a server object fron the JSON inventory *)
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

(** [inventory filename] reads the inventory into a [t list] value
 *)
let make json = 
  json |> U.to_list |> List.map server 


