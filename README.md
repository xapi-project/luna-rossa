
# Luna Rossa - A Framework for Testing Xen Server

This is the evolution of the Testarossa framework for testing Xen
Server. The main new ideas are:

* Luna Rossa provides a library for writing tests. Each module in the
  library is guarded by an interface.

* Luna Rossa doesn't deal with provisioning the test environment. 
  Instead, it reads the _inventory_ of machines that tests can use from
  an `servers.json` file, that describes it. In particular, Rossa does
  not know by itself about machine names, accounts, and other details
  about ther servers where tests are executed but learns about them from
  the `servers.json` file. See the `etc/` directory.

* Luna Rosa tries to make configuarations for tests explicit by reading
  them from a JSON file `tests.json`. See the `etc/` directory.

* We give up OCamlScript in favor of pure OCaml and gain one less
  dependency, mroe type safety and support from types in the editor
  during development.

# Build Dependencies

Luna Rossa is implemented in OCaml. OCaml's package manager Opam is
essential for building Luna Rossa.

    $ opam install xen-api-client yojson
    $ opam install oasis

# Building

The build process is supported by Oasis which generates a Makefile and a
configure script:

    $ oasis setup -setup-update dynamic
    $ ./configure
    $ make


