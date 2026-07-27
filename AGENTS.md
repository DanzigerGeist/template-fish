# AGENTS.md

Guidance for AI agents working in this repository.

## Project

A Fisher-compatible fish shell plugin. Functions in `functions/`, completions in `completions/`, tests in `tests/`,
CI helpers in `scripts/`. `tests/vendor/fishtape.fish` is the test runner, committed verbatim — third-party, do not
reformat.

**A fish plugin's shipped artifact is its source.** There is no build step, and fisher copies only `functions/`,
`completions/`, `conf.d/` and `themes/`. Everything else in the repository is for developers, never for users.

## Setup

`make setup` once, to install the Cog git hooks (commit-message validation, pre-commit `make check`, pre-push `check`
+ `test` + `security`). There is nothing to download — fishtape is committed.

The `example` function, its completions and its tests are **examples, not scaffolding**. Deleting or replacing them is
the expected first move; no gate looks for them by name. Every target discovers `*.fish` files, so new directories
(`conf.d/`, `themes/`) and additional functions are picked up with no configuration.

**fish autoloads a function only when its file in `functions/` is named after the function it defines.** Renaming a
file means renaming the `function` line with it, and by convention the matching `completions/` and `tests/` files too.

## Commands

- `make check`: formatting (`fish_indent --check`) and syntax (`fish --no-execute`)
- `make test`: the fishtape suite
- `make smoke`: install with a real fisher into a throwaway HOME and load every function
- `make security`: gitleaks over the working tree and the full history
- `make format`: apply formatting

## The toolchain is smaller than it looks

fish has **no linter** beyond `fish_indent` and **no coverage tool**. ShellCheck does not support fish. Do not invent
a gate to fill either gap, and do not add a tool that claims to: the honest substitute for coverage is `make smoke`,
which proves the shipped artifact installs and loads.

Two traps that have already caused real bugs in plugins built from this template:

- **`fish --no-execute` reads exactly one file.** `fish -n a.fish b.fish` parses `a.fish` and passes `b.fish` through
  as `$argv`, so a syntax error in any file after the first is silently ignored. `scripts/check-syntax.fish` gives
  every file its own invocation. Never collapse it back into one call.
- **fish resolves `$__fish_config_dir` once, at startup.** Exporting `HOME` or `XDG_CONFIG_HOME` from inside a running
  fish does **not** redirect fisher — it will write to the real `~/.config/fish`. The sandbox environment must be
  handed to a **child** fish via `env`; the assertion inside `scripts/smoke-test.fish` is the tripwire.

## Conventions

- **Conventional Commits**, enforced by the Cog `commit-msg` hook locally and commitlint in CI.
- **Enumerate options in `argparse`; never forward unknown flags.** Option arity is not inferable from a flag alone
  (`-p` takes no value, `-m` takes one), so pass-through parsing cannot be correct. An unrecognised option should be a
  usage error.
- **Re-emit options to external commands as POSIX short flags.** BSD/macOS coreutils have no long options, so
  forwarding the user's spelling verbatim breaks on macOS.
- **Never pass a bare relative path to `cd`.** fish's `cd` searches `$CDPATH` first and will silently land in an
  unrelated tree. Resolve against `$PWD` first.
- **Never pass `--` to `cd`.** fish 3.0's `cd` rejects it, and a user `cd` wrapper forwarding only `$argv[1]`
  degenerates to an argument-less `cd`, which means `$HOME`.
- Use `command foo` when a user's wrapper must not change behaviour; use the plain builtin when their hooks and
  history *should* still fire. The asymmetry is usually deliberate — comment it.
- **Exit-status convention**: `0` success, `2` usage error, `1` for a failure after the side effect succeeded, and the
  external command's own status when it is the thing that failed.
- Help goes to **stdout** and exits `0`. Errors go to **stderr**.
- **Version floor is fish 3.0.** `argparse` is 2.7.0, `set --append` is 3.0, `string match` is 2.3. `argparse
  --ignore-unknown` (3.1), `path resolve` (3.5) and `test -ef` (3.6) all raise the floor — check before using them.
- Formatting is whatever `fish_indent` produces. Its 4-space indent is not configurable.

## Boundaries

Always:

- Run `make check` and `make test` before committing, and add a test for any behaviour change.
- Keep each function self-contained. For a single-function plugin it is the only file most users will possess.
- Keep the SPDX header in every file under `functions/`. fisher never ships the repository `LICENSE`, so that header
  is the only notice an installed user receives.

Ask first:

- Adding a dependency of any kind. There are none, and fishtape is vendored precisely to keep it that way.
- Changing CI workflows or `cog.toml`.
- Changing a function's exit-status contract or option surface.

Never:

- **Remove the job-level `permissions:` blocks in the workflows.** The repository default for workflow permissions is
  `read`, so the release job cannot push without them, and the failure is a silent 403.
- Un-pin a third-party action from its SHA back to a floating tag.
- Remove the `is_template` guard in `release.yml`; it is what stops the template repository releasing itself.
- Commit secrets; gitleaks scans the working tree and the full history.
- Edit the version by hand or create tags manually; `cog bump` owns them.
- Skip, delete, or weaken failing tests, or bypass hooks with `--no-verify`.
- Reformat `tests/vendor/fishtape.fish`. It is upstream's bytes.
