#!/usr/bin/env fish
#
# Rename the placeholder function throughout the repository.
#
# fish autoloads a function only when the file in functions/ is named after the
# function it defines, so a fish plugin cannot simply be cloned and edited: the
# filename and the definition have to move together, in four places. That is
# what this script exists for, and it is why this template needs an `init` step
# where the Deno and Go templates do not.

set -l old $argv[1]
set -l new $argv[2]

if test -z "$new"
    echo "usage: fish scripts/init.fish OLD_NAME NEW_NAME" >&2
    exit 1
end

if not string match -qr '^[a-zA-Z_][a-zA-Z0-9_-]*$' -- $new
    echo "init: '$new' is not a usable fish function name" >&2
    exit 1
end

set -l root (dirname (status -f))/..

if not test -f $root/functions/$old.fish
    echo "init: functions/$old.fish does not exist -- already renamed?" >&2
    exit 1
end

if test -e $root/functions/$new.fish
    echo "init: functions/$new.fish already exists" >&2
    exit 1
end

# Move first, then rewrite contents: git mv keeps the rename visible in history.
for dir in functions completions tests
    set -l suffix ""
    test $dir = tests; and set suffix ".test"

    set -l from $root/$dir/$old$suffix.fish
    set -l to $root/$dir/$new$suffix.fish

    if test -f $from
        command mv $from $to
        echo "renamed $dir/$old$suffix.fish -> $dir/$new$suffix.fish"
    end
end

# Whole-word replacement only, so a name that is a substring of another word is
# left alone.
#
# AGENTS.md is deliberately NOT rewritten: its mentions of the placeholder
# describe this rename step itself, which by definition has already happened.
for file in $root/functions/*.fish $root/completions/*.fish $root/tests/*.test.fish $root/README.md
    test -f $file; or continue
    set -l before (cat $file | string collect)
    set -l after (string replace -ra '\b'$old'\b' $new -- $before | string collect)

    if test "$before" != "$after"
        printf '%s\n' $after >$file
        # Path, not basename: functions/x.fish and completions/x.fish share one.
        echo "updated "(string replace -- $root/ '' $file)
    end
end

echo
echo "Renamed $old -> $new. Next:"
echo "  1. Replace the function body in functions/$new.fish with your own."
echo "  2. Update the tests in tests/$new.test.fish."
echo "  3. Set the repository name and owner in README.md."
echo "  4. Run: make check && make test && make smoke"
