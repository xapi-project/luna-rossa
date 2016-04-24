(** 
 * Read test configuration data from a JSON file
 *)

module Y = Yojson.Basic
module U = Yojson.Basic.Util
module M = Map.Make(String)
module S = Rossa_server

type t = string -> Yojson.Basic.json 

(** [lookup name map] finds a [Some value] in a map, or [None]
 *)
let lookup map name = M.find name map

(** add all tests to a map with the name as key *)
let to_map json =
  let name test     = test |> U.member "name" |> U.to_string in
  let tests         = json |> U.to_list in 
  let add map test  = M.add (name test) test map in
    List.fold_left add M.empty tests

(** [read file_json] reads a JSON file and returns a [lookup] function
	* that maps the name of a test to its entry in the JSON file 
	*)
let read file_json =
  Y.from_file file_json 
  |> U.member "tests" 
  |> to_map 
  |> lookup 

    
    






