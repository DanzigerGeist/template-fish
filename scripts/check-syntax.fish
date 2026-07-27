#!/usr/bin/env fish
#
# Parse-check every file given as an argument.
#
# `fish --no-execute` reads exactly ONE script file: `fish -n a.fish b.fish`
# parses a.fish and passes b.fish through as $argv, so a syntax error in any
# file after the first is silently ignored. Every file therefore gets its own
# invocation.
#
# Note this is a parser, not a semantic checker: it will not catch an unknown
# command or a misspelled builtin.

set -l failed 0

for file in $argv
    if not fish --no-execute $file
        echo "syntax: $file" >&2
        set failed 1
    end
end

if test $failed -ne 0
    echo "syntax check failed" >&2
    exit 1
end

echo "syntax ok: "(count $argv)" file(s)"
