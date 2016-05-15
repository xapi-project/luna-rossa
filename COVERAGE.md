
# Coverage Analysis

This project can be compiled for coverage analysis using [bisect_ppx]. By
default, this is not done. To compile for coverage analysis, do:

    make coverage
    make 

The `coverage` target adds the rules in `_tags.coverage` to the `_tags`
file, which in turn causes all code to be compiled for coverage
analysis. The `_tags.coverage` file could be tweaked to control which
files get instrumented.

## Execution and Logging

During program execution, the lunarossa binary writes coverage data to

    /tmp/bisect-lunarossa-*.out

This can be overridden by setting the `BISECT_FILE` environment
variable, which is otherwise set at startup using the code in
`profiling/coverage.ml`;

## Analysis

See the [bisect_ppx] documentation for details but try from the
top-level directory:

    bisect-ppx-report -I _build -html coverage /tmp/bisect-lunarossa-*.out

This creates an HTML document in [coverage/](./coverage].


[bisect_ppx]:	https://github.com/aantron/bisect_ppx




