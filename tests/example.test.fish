set -l root (dirname (status -f))/..
source $root/functions/example.fish
source $root/completions/example.fish

@test "prints the text" (
    example hello
) = hello

@test "joins multiple words into one operand" (
    example hello world
) = "hello world"

@test "upper-cases with -u" (
    example -u hello
) = HELLO

@test "repeats with -n" (
    example -n 3 hi | count
) = 3

@test "-n 0 prints nothing" (
    example -n 0 hi | count
) = 0

@test "options may follow the operand" (
    example hello -u
) = HELLO

@test "long options work" (
    example --upper --count 2 hi | count
) = 2

@test "a missing operand is a usage error" (
    example 2>/dev/null; echo $status
) = 2

@test "a non-numeric count is a usage error" (
    example -n abc hi 2>/dev/null; echo $status
) = 2

@test "an unknown option is a usage error" (
    example -Z hi 2>/dev/null; echo $status
) = 2

@test "usage errors go to stderr, not stdout" (
    example 2>/dev/null | count
) = 0

@test "text beginning with a dash works after --" (
    example -- -weird
) = -weird

@test "--help exits 0" (
    example --help >/dev/null 2>&1; echo $status
) = 0

@test "--help writes to stdout" (
    example --help 2>/dev/null | string match -q "*Usage:*"; echo $status
) = 0

@test "flag completions are registered" (
    complete -C "example -" | count
) -gt 0
