# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aleksy Rudy
#
# fisher copies only functions/, completions/, conf.d/ and themes/, so the
# repository LICENSE never reaches an installed user. Keep this header: for a
# single-function plugin it is the only notice they receive.
#
# This is a placeholder demonstrating the conventions the checks enforce.
# `make init NAME=yourname` renames it; then replace the body with your own.

function example --description 'Print text, optionally repeated and upper-cased'
    # Options are enumerated deliberately. argparse cannot forward unknown
    # flags correctly, because option arity is not inferable from the flag
    # alone, so an unrecognised option is a usage error rather than a surprise.
    argparse h/help u/upper 'n/count=' -- $argv
    or return

    if set -q _flag_help
        printf '%s\n' \
            'example - print text, optionally repeated and upper-cased' \
            '' \
            'Usage:' \
            '  example [-u] [-n COUNT] [--] TEXT' \
            '  example -h | --help' \
            '' \
            'Options:' \
            '  -u, --upper       Upper-case the text.' \
            '  -n, --count N     Print the text N times (default 1).' \
            '  -h, --help        Show this help and exit.' \
            '  --                End of options; use for TEXT beginning with "-".' \
            '' \
            'Exit status:' \
            '  0   text printed' \
            '  2   usage error (bad option, missing operand, bad count)'
        return 0
    end

    if not set -q argv[1]
        printf 'example: missing text operand\n' >&2
        printf 'Usage: example [-u] [-n COUNT] [--] TEXT\n' >&2
        return 2
    end

    set -l count 1
    if set -q _flag_count
        # Validate before use. `test -gt` on a non-numeric string is an error,
        # not a false, so the pattern check has to come first.
        if not string match -qr '^[0-9]+$' -- $_flag_count[-1]
            printf 'example: count must be a non-negative integer, got \'%s\'\n' $_flag_count[-1] >&2
            return 2
        end
        set count $_flag_count[-1]
    end

    set -l text (string join ' ' -- $argv)

    if set -q _flag_upper
        set text (string upper -- $text)
    end

    # A while loop rather than `for i in (seq $count)`: BSD seq (macOS) prints
    # "1\n0" for `seq 0` where GNU seq prints nothing, so the seq version
    # repeats twice when asked for zero. This is the single most common way a
    # fish plugin breaks across platforms -- prefer builtins to shelling out,
    # and when you must shell out, test on both OSes. The CI matrix does.
    set -l i 0
    while test $i -lt $count
        printf '%s\n' $text
        set i (math $i + 1)
    end
end
