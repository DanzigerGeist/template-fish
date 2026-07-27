#!/usr/bin/env fish
#
# Install this plugin with a real fisher, into a throwaway HOME, and prove every
# function it ships is defined afterwards.
#
# This is the highest-value gate in the repository: it is the only one that
# exercises the artifact the way users actually obtain it. fish has no coverage
# tooling, so proving the shipped thing installs and loads is the substitute.
#
# WHAT THIS EXECUTES, AND WHAT IS CONTAINED.
#
# This script does not call your functions -- it only asserts each one is
# defined. But `fisher install` itself sources every .fish file it copies
# (fisher.fish:199-200): functions/ merely get defined, completions/ run their
# `complete` calls, and any conf.d/ file has its top-level code executed and an
# `<name>_install` event emitted. That is not something this gate adds; it is
# byte-for-byte what happens on a real user's machine, and the code is your own.
#
# Contained: $HOME, $XDG_CONFIG_HOME, $XDG_DATA_HOME -- so universal variables,
# fisher's state and anything written under $HOME land in a temp dir that is
# deleted on exit. NOT contained: writes to absolute paths elsewhere on disk. If
# you add a conf.d/ that touches the wider filesystem, prefer running this gate
# in CI only, where the runner is ephemeral.
#
# THE ISOLATION FOOTGUN -- read before editing.
#
# fish resolves $__fish_config_dir ONCE, at startup. Exporting HOME or
# XDG_CONFIG_HOME from *inside* an already-running fish does NOT redirect
# fisher: it will happily write to the real ~/.config/fish. The sandbox
# environment must therefore be handed to a CHILD fish via `env`, which is what
# happens below. The assertion inside the child is the tripwire for a
# regression; do not remove it.

set -l root (realpath (dirname (status -f))/..)
set -l sandbox (mktemp -d)

# Pinned: `main` is a moving target and this file gets piped straight into
# `source`. Bump deliberately, never implicitly.
set -l fisher_version 4.4.8

# Every function the plugin ships, derived rather than hardcoded, so this gate
# keeps working after `make init` renames things.
set -l names (basename -s .fish $root/functions/*.fish)

if test (count $names) -eq 0
    echo "smoke: no functions to test" >&2
    exit 1
end

function __smoke_cleanup --on-event fish_exit --inherit-variable sandbox
    test -n "$sandbox"; and rm -rf $sandbox
end

echo "smoke: sandbox HOME = $sandbox"
echo "smoke: expecting functions: $names"

# stdin is redirected from /dev/null: fisher reads from it, and a gate that can
# block waiting for input is a gate that hangs CI instead of failing it.
env \
    HOME=$sandbox \
    XDG_CONFIG_HOME=$sandbox/.config \
    XDG_DATA_HOME=$sandbox/.local/share \
    PLUGIN_ROOT=$root \
    PLUGIN_NAMES="$names" \
    FISHER_VERSION=$fisher_version \
    fish -c '
        # Tripwire: prove we are not about to write to the real config before
        # fisher gets the chance. $__fish_config_dir is resolved at startup, so
        # if this passes, the isolation genuinely took effect.
        if not string match -q -- "$HOME/*" $__fish_config_dir
            echo "smoke: NOT ISOLATED -- config dir is $__fish_config_dir, refusing to run" >&2
            exit 1
        end

        mkdir -p $__fish_config_dir/functions $__fish_config_dir/completions

        curl -fsSL "https://raw.githubusercontent.com/jorgebucaran/fisher/$FISHER_VERSION/functions/fisher.fish" | source
        or begin
            echo "smoke: could not fetch fisher $FISHER_VERSION" >&2
            exit 1
        end

        # Install from the local path, not from a ref. A path install makes
        # zero api.github.com calls, so this gate stays offline-capable and is
        # immune to the 60-req/hour unauthenticated rate limit that shared CI
        # runner IPs routinely exhaust.
        fisher install $PLUGIN_ROOT
        or begin
            echo "smoke: fisher could not install $PLUGIN_ROOT" >&2
            exit 1
        end

        for name in (string split " " -- $PLUGIN_NAMES)
            functions -q $name
            or begin
                echo "smoke: $name is not defined after install" >&2
                exit 1
            end
        end

        echo "smoke: installed; all functions defined"
    ' </dev/null
or exit 1
