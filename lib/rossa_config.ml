(** 
 * Read configuration data from a JSON file
 *)

module Y = Yojson.Basic
module U = Yojson.Basic.Util
module M = Map.Make(String)
module S = Rossa_server


type t =
  { servers:  Rossa_server.t list
  ; test:     string -> Yojson.Basic.json 
  }

(** [lookup name map] finds a [Some value] in a map, or [None]
 *)
let lookup map name = M.find name map

let to_map json =
  let name test     = test |> U.member "name" |> U.to_string in
  let tests         = json |> U.to_list in 
  let add map test  = M.add (name test) test map in
    List.fold_left add M.empty tests

let read file_json =
  let json    = Y.from_file file_json in
  let servers = json |> U.member "servers" |> S.make in
  let map     = json |> U.member "tests" |> to_map in
    { servers = servers
    ; test    = lookup map
    }

    
    






