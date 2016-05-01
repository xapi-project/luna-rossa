<!-- vim: set ts=4 sw=4 et: -->


# Luna Rossa - Testing Xen Server

Luna Rossa is a suite of tests for testing Xen Server. Usually it is
driven by [Testarossa](https://github.com/xapi-project/testarossa/) that
provisions the servers that are available for testing. However, Luna
Rossa is designed to work independently and to make assumptions about
its environment explicit.

* Luna Rossa provides a library (in `lib/`) for writing tests whose code
    resides in `tests/`. Currently each test is compiled into an individual
    binary but the plan is to combine them into one binary as this makes
    installing the binaries easier.

* Luna Rossa doesn't deal with provisioning the test environment. 
  Instead, it reads the inventory of machines that tests can use from
  a `servers.json` file that describes it. In particular, Luna Rossa
  does not know by itself about machine names, accounts, and other
  details about the servers where tests are executed but learns about
  them from the `servers.json` file. See the `etc/` directory.

* Luna Rosa tries to make configurations for tests explicit by reading
  them from a JSON file `tests.json`. See the `etc/` directory.

---

_This is work in progress_

---

# Build Dependencies

Luna Rossa is implemented in OCaml. OCaml's package manager Opam is
essential for building Luna Rossa.

    opam install xen-api-client yojson
    opam install oasis

# Building

The build process is supported by Oasis which generates a Makefile and a
configure script:

    oasis setup -setup-update dynamic
    ./configure
    make

# Running Tests

Each test binary can be invoked with `--help`. A binary takes two JSON
files: `servers.json` informs it about the server(s) to use for testing
and `tests.json` can be used to customise tests. You should start with
the one provided in `etc/`.

        quicktest -s servers.json -c etc/tests.json
        powercycle -s servers.json -c etc/tests.json

* `quicktest` - executes the `quicktest` binary on a host with 
  a number of sub tests.

* `powercycle` - goes through a powercycle with a custom kernel.

# Configuration Files

## servers.json

The purpose of `servers.json` is to inform Luna Rossa about the
servers that are available for testing. Each server has a record like
this:

    {
      "name": "host1",
      "ssh": [
        "ssh",
        "-t",
        "-q",
        "root@dt87"
      ],
      "xen": {
        "api": "http://dt87",
        "user": "root",
        "password": "xenroot"
      }
    }

* `name` assigns a name to the server that is used from the `tests.json`
    file. 

* `xen` describes the API endpoint and credentials for the Xen Server
    running on that host.

* `ssh` constructs a command to execute shell commands server. This is a
    list of strings that are passed to a `execvp` system call and hence,
    arguments are not interpreted by a shell. Luna Rossa executes a command
    on the host by passing the shell command as a final additional
    parameter. Given the example above, to execute `ls` on the server
    `host1`. Luna Rossa would create a process with these parameters:

        ssh -t -q root@dt87 ls

    Luna Rossa expects that the execution of these commands require no
    user interaction and it is the responsibility of the environment to
    set up SSH accounts accordingly. Any exit code different from 0 is
    taken as a failure.

The `name` _host1_ is used to reference the server from the `tests.json`
file. The `xen` member identifies the API endpoint of Xen on that host
and the credentials to use it. The 

## tests.json

In the `tests.json` file each test can store parameters in a JSON object
whose meaning depend on the individual test. The goal is to avoid
putting sensitive information into test cases directly.

Member `server` typically refers to the host to be used for testing and
must match a named server in the `servers.json` file.

    {
      "name": "powercycle",
      "server": "host1",
      "server-setup.sh": [
        "set -e",
        "GH=\"https://github.com/xapi-project\"",
        "VM=\"$GH/xen-test-vm/releases/download/0.0.5/test-vm.xen.gz\"",
        "cd /boot/guest",
        "curl --fail -s -L \"$VM\" > powercycle.xen.gz"
      ],
      "server-cleanup.sh": [
        "set -e",
        "rm -f /boot/guest/powercycle.xen.gz"
      ]
    }


# Security

## Root Access to Hosts

Luna Rossa can makes SSH connections into hosts. What account is used
for this is configured through the `servers.json` file. Typically access
will be a root account or an account that has `sudo` rights. 

## Custom Kernel Used by the Powercycle Test

The `powercycle` requires to run the custom [Xen Test
VM](https://github.com/xapi-project/xen-test-vm) as a guest on a Xen
Server. It downloads it the kernel and boots it. You can find the script
that does it in the `tests.json` file. Obviously running a custom kernel
is a security risk.


