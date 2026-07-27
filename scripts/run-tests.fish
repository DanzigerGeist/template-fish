#!/usr/bin/env fish
#
# Run every tests/*.test.fish suite through the vendored fishtape.
#
# fishtape is committed at tests/vendor/fishtape.fish rather than downloaded:
# it is a single 4 KB self-contained function that has not changed since
# January 2021, and sourcing a freshly-curled file into the shell that runs CI
# is a supply-chain risk with no upside. Vendoring also keeps `make test`
# offline and out of the developer's real fish config.

set -l root (dirname (status -f))/..
set -l runner $root/tests/vendor/fishtape.fish

if not test -f $runner
    echo "fishtape is missing from tests/vendor -- the repository is incomplete" >&2
    exit 1
end

set -l suites $root/tests/*.test.fish

if test (count $suites) -eq 0
    echo "no test suites found in tests/" >&2
    exit 1
end

source $runner
fishtape $suites
