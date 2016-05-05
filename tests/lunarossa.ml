(* vim: set sw=2 ts=2 et: *)

(** This module provide the "main" function for Luna Rossa. It handles
    command line options and help.

    Each test is implemented as a sub command. To add a new test, add it
    to the list [CMD.cmds] below and provide a function that handles its
    options. See [CMD.quicktest] as an example. The test itself is
    implemented in [Quicktest.main] and is called from [CMD.quicktest].
    *)

module C = Cmdliner

(** This implements the [help] subcommand. It is the only command
    that is implemented inside this module. Each test command should
    reside in its own module *)

let help_main man_format cmds = function
  | None -> `Help (`Pager, None) (* help about the program. *)
  | Some topic ->
    let topics = "copyright" :: cmds in
    let conv, _ = C.Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
    match conv topic with
    | `Error e -> `Error (false, e)
    | `Ok t when t = "topics" -> List.iter print_endline topics; `Ok true
    | `Ok t when List.mem t cmds -> `Help (man_format, Some t)
    | `Ok t -> (* only reached when we add topics above *)
        let page = (topic, 7, "", "", ""), 
            [`S "OTHER"
            ;`P "Here is room for online help texts"
            ] 
        in
            `Ok ( C.Manpage.print man_format Format.std_formatter page
                ; true
                )

(** module CMD holds all functions that implement and document
    (sub) commands and options *)

module CMD = struct
  (** option -s *)
  let servers =
    let doc = "JSON file describing Xen Servers available for testing." in
      C.Arg.(value
          & opt file "etc/servers.json" 
          & info ["s"; "servers"] ~docv:"servers.json" ~doc)

  (** option -c *)
  let config =
    let doc = "JSON file describing test configurations." in
      C.Arg.(value
          & opt file "etc/tests.json"
          & info ["c"; "config"] ~docv:"tests.json" ~doc)

  (** option --suite *)
  let suite =
    let doc = "Name of test suite" in
      C.Arg.(value
          & opt string "all"
          & info ["t"; "suite"] ~docv:"suite" ~doc)


  (** topic for help *)
  let topic =
    let doc = "Help topic" in
      C.Arg.(value
          & pos 0 (some string) None
          & info [] ~docv:"TOPIC" ~doc)

  let help =
    let doc = "help for lunarossa sub commands" in
    let man = 
      [ `S "DESCRIPTION"
      ; `P "provide help for a sub command"
      ; `S "BUGS"
      ; `P "Report bug on the github issue tracker" 
      ] 
    in
      ( C.Term.(ret 
        (const help_main $ man_format $ choice_names $ topic))
      , C.Term.info "help" ~version:"1.0" ~doc ~man
      )

  (** [lunarossa] is the outermost and default command *)
  let lunarossa =
    let doc = "a test suite for XenServer" in
    let man = 
      [`S "MORE HELP"
      ;`P "Use `$(mname) $(i,COMMAND) --help' for help on a single command."
      ;`Noblank
      ] 
    in
      ( C.Term.(ret 
        (const (fun _ -> `Help (`Pager, None)) $ const () ))
      , C.Term.info "lunarossa" ~version:"1.0" ~doc ~man
      )

  (* tests are implemented as sub commands on the command line. Add them
  here *)

  let quicktest =
    let doc = "run on-board quicktest on a Xen Server" in
    let man = 
      [ `S "DESCRIPTION"
      ; `P "Run the on-board quicktest test suite on a server."
      ; `S "BUGS"
      ; `P "Report bug on the github issue tracker" 
      ] 
    in
      ( C.Term.(const Quicktest.main $ servers $ config)
      , C.Term.info "quicktest" ~version:"1.0" ~doc ~man
      )

  let powercycle =
    let doc = "start a Mirage VM and powercycle it" in
    let man = 
      [ `S "DESCRIPTION"
      ; `P "Start a VM and go through a powercycle with it."
      ; `S "BUGS"
      ; `P "Report bug on the github issue tracker" 
      ] 
    in
      ( C.Term.(const Powercycle.main $ servers $ config $ suite)
      , C.Term.info "powercycle" ~version:"1.0" ~doc ~man
      )

  (** This is a template for adding new tests *)
  let dummy =
    let doc = "Run a dummy test" in
    let man = 
      [ `S "DESCRIPTION"
      ; `P "Executes a date command on a list of servers. This list
            is provided in the 'servers' array in tests.json" 
      ; `S "BUGS"
      ; `P "Report bug on the github issue tracker" 
      ] 
    in
      ( C.Term.(const Dummy.main $ servers $ config)
      , C.Term.info "dummy" ~version:"1.0" ~doc ~man
      )


  (** add any additional test here *)
  let cmds = 
    [ help
    ; quicktest
    ; powercycle
    ; dummy
    ] 
end

let () = 
  match C.Term.eval_choice CMD.lunarossa CMD.cmds with 
  | `Ok(true)   -> exit 0 (* all tests passed *)
  | `Ok(false)  -> exit 1 (* some test failed *)
  | `Error _    -> exit 2 (* unexpected error *)
  | _           -> exit 3 (* Version, Help    *)
