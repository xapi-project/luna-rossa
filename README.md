
# Luna Rossa - A Framework for Testing Xen Server

This is the prototype of a test framework inspired by Testarossa, another
framework for testing Xen Server. It's main ideas are:

* Luna Rossa provides a library for writing tests. Each module in the
  library is guarded by an interface.

* Luna Rossa doesn't deal with provisioning the test environment.
  Instead, it reads the _inventory_ of machines that tests can use from
  an `inventory.json` file, that describes it. In particular, Rossa does
  not know by itself about machine names, accounts, and other details
  about ther servers where tests are executed but learns about them from
  the `inventory.json` file.

This is work in progress.

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


