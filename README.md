# Fish Plugin Template

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/DanzigerGeist/template-fish/actions/workflows/pr-checks.yml/badge.svg)](https://github.com/DanzigerGeist/template-fish/actions/workflows/pr-checks.yml)

A [Fisher](https://github.com/jorgebucaran/fisher)-compatible fish plugin template with the quality gates, git hooks
and CI already wired up. Write the function; the release plumbing is done.

## Features

- **Quality gates**: formatting (`fish_indent --check`) and syntax (`fish --no-execute`), each its own CI job
- **Tests**: [fishtape](https://github.com/jorgebucaran/fishtape) suite, runner vendored so `make test` works offline
- **Install smoke test**: installs with a real fisher into a throwaway HOME and loads every function — the gate that
  actually proves the shipped artifact works
- **Linux and macOS matrix**: fish plugins shell out to coreutils, and BSD and GNU disagree about option handling
- **Security scanning**: [gitleaks](https://github.com/gitleaks/gitleaks) over the working tree and full git history
- **Releases itself**: [Conventional Commits](https://www.conventionalcommits.org/) drive the version bump, tag,
  changelog and GitHub Release on merge to `master`, via [Cocogitto](https://docs.cocogitto.io/) hooks locally and
  commitlint in CI
- **Supply-chain hygiene**: every third-party action pinned by commit SHA, gitleaks installed as a checksum-verified
  binary, no dependency manager anywhere
- **AI-ready**: agent guidance in [`AGENTS.md`](AGENTS.md), imported by `CLAUDE.md`

## Prerequisites

| Tool | Purpose | macOS / Linux |
| ---- | ------- | ------------- |
| [fish](https://fishshell.com/) ≥ 3.0 | Runtime; `fish_indent` is the formatter | `brew install fish` |
| [Cocogitto](https://docs.cocogitto.io/) | Git hooks, versioning, changelog | `brew install cocogitto` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanning (`make security`) | `brew install gitleaks` |
| make _(optional)_ | Shorthand for the scripts | preinstalled |
| [gh](https://cli.github.com/) _(optional)_ | Creating a repository from the template | `brew install gh` |

## Quick Start

```sh
# 1. Create a new repository from the template
gh repo create my-plugin.fish --template danzigergeist/template-fish --clone
cd my-plugin.fish

# 2. Rename the placeholder function -- do this FIRST
make init NAME=myplugin

# 3. Install git hooks
make setup

# 4. Verify everything works
make check && make test && make smoke
```

Then replace the body of `functions/myplugin.fish` with your own, update `tests/myplugin.test.fish`, and set the owner
and repository name in `README.md`.

### Why `make init` exists

fish autoloads a function only when the file in `functions/` is **named after the function it defines**. A fish plugin
therefore cannot simply be cloned and edited — the filename and the definition have to move together, in
`functions/`, `completions/`, `tests/` and the docs. `make init` does all four. This is the one step the Deno and Go
templates do not need.

## Project Structure

```
.
├── functions/example.fish        # the plugin -- and the entire shipped artifact
├── completions/example.fish      # tab completions
├── tests/
│   ├── example.test.fish         # fishtape suite
│   └── vendor/fishtape.fish      # test runner, committed verbatim
├── scripts/
│   ├── init.fish                 # rename the placeholder
│   ├── check-syntax.fish         # one fish -n per file (see the trap below)
│   ├── run-tests.fish            # run every suite
│   └── smoke-test.fish           # fisher install into a sandbox HOME
├── .github/workflows/            # pr-checks.yml, release.yml
├── cog.toml                      # versioning, changelog, git hooks
├── Makefile                      # the command surface
└── AGENTS.md                     # conventions, for humans and agents
```

fisher copies only `functions/`, `completions/`, `conf.d/` and `themes/`. Everything else is for developers.

## Commands

| Command | Description |
| ------- | ----------- |
| `make init NAME=x` | Rename the placeholder function; run once, first |
| `make setup` | Install the Cog git hooks |
| `make check` | Formatting and syntax |
| `make test` | The fishtape suite |
| `make smoke` | Install via fisher into a throwaway HOME and load every function |
| `make security` | Secret scan of the tree and full history |
| `make format` | Apply formatting |
| `make publish` | Run every gate, then push the release tag |
| `make version` | Print plugin name and current tag |
| `make help` | List all targets |

## What fish does not have

Being honest about this is the point; the template ships no gate that pretends otherwise.

- **No linter.** ShellCheck does not support fish. `fish_indent` plus `fish --no-execute` is the entire static-analysis
  surface. The CI jobs are named `format` and `syntax`, not `lint`.
- **No coverage tool.** kcov instruments ELF binaries and would measure the fish interpreter, not your script.
  `make smoke` is the substitute: it proves the artifact works when obtained the way users obtain it, which coverage
  never does.
- **No dependency manager.** fishtape is committed at `tests/vendor/fishtape.fish` rather than fetched: it is a single
  4 KB self-contained function unchanged since 2021, and sourcing a freshly-curled file into the shell that runs CI is
  a supply-chain risk with no upside.

### Two traps worth knowing

**`fish --no-execute` reads exactly one file.** `fish -n a.fish b.fish` parses `a.fish` and passes `b.fish` through as
`$argv` — a syntax error in any file after the first is silently ignored. `scripts/check-syntax.fish` gives every file
its own invocation.

**fish resolves `$__fish_config_dir` once, at startup.** Exporting `HOME` from inside a running fish does *not*
redirect fisher; it will write to the real `~/.config/fish`. The sandbox environment must be handed to a child fish
via `env`, and `scripts/smoke-test.fish` asserts the isolation actually took effect before installing anything.

## CI/CD

### PR Checks

Every pull request runs [`pr-checks.yml`](.github/workflows/pr-checks.yml), one job per gate so a red check names its
own failure: `commits`, `format`, `syntax`, `test` (Linux + macOS), `smoke` (Linux + macOS), and `secrets`.

Three details that are easy to get wrong, and are already handled:

- The `commits` job is **skipped** on `workflow_dispatch` rather than run. commitlint resolves its commit range from
  the event payload, and a dispatch payload carries none — the job would lint nothing and still report success.
- `secrets` installs the gitleaks **binary** and runs `make security`, rather than using `gitleaks-action`, which has
  been proprietary-licensed since v2.0.0. Local and CI run the same tool, and the org-account licence caveat is moot.
- `smoke` installs from the **local path**, which makes zero `api.github.com` calls, so it is immune to the
  unauthenticated rate limit that shared runner IPs routinely exhaust.

### Releases

[`release.yml`](.github/workflows/release.yml) triggers on every push to `master`. When releasable commits are found:

```
feat: add an option     →  minor bump (0.1.0 → 0.2.0)
fix: handle empty input →  patch bump (0.2.0 → 0.2.1)
feat!: new option set   →  major bump (0.2.1 → 1.0.0)
```

CI bumps the version, tags it, creates a GitHub Release with a generated changelog, and verifies the new tag is
actually installable by a real fisher. Nothing is tagged unless the full check suite passes first.

**There is no registry.** fisher resolves `OWNER/REPO@vX.Y.Z` straight to the GitHub tarball for that tag, so the git
tag *is* the release — the same situation as Go modules. This is why `cog.toml` has no `pre_bump_hooks`: there is no
version file to rewrite.

The template repository itself never releases; the release jobs are guarded by `github.event.repository.is_template`.

### Before your first release

1. **Add a tag ruleset on `refs/tags/v*`** (restrict updates and deletions) *before* the first tag exists. fisher
   fetches a tag's tarball with no integrity check, so a force-moved tag silently changes what every pinned user gets.
2. If you enable branch protection on `master`, the release job's `git push` will be blocked. Prefer "allow specified
   actors to bypass" over a PAT — PAT pushes re-trigger the workflow and cost a second full matrix run.

## License

[MIT](LICENSE): free to use, modify, and distribute.
