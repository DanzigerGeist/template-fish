MAKEFLAGS += --no-print-directory
.SILENT:
.DEFAULT_GOAL := help

PLUGIN := $(notdir $(CURDIR))
# Everything fish_indent and fish -n are allowed to see. scripts/ is included
# on purpose: the CI helpers are fish too, and an unparseable helper would
# otherwise only fail once CI ran it. tests/vendor/ is excluded -- it is
# third-party code committed verbatim and is not ours to reformat.
SOURCES := $(wildcard functions/*.fish completions/*.fish conf.d/*.fish scripts/*.fish)
TESTS := $(wildcard tests/*.test.fish)

.PHONY: help init setup format check test security publish build benchmark docs update clean version
.PHONY: fmt-check syntax smoke

help: ## ❓ List available make targets
	@awk -F':.*##[ \t]*' '/^[A-Za-z0-9_.:-]+:.*##/ { printf "%-14s%s\n", $$1, $$2 }' $(MAKEFILE_LIST) | sort

# fish autoloads a function only when its file is named after it, so the
# placeholder cannot just be edited in place -- filename and definition must
# move together. Run this once, first.
init: ## 🌱 Rename the placeholder function (make init NAME=yourname)
	@test -n "$(NAME)" || { echo "usage: make init NAME=yourname" >&2; exit 1; }
	@fish scripts/init.fish example $(NAME)

setup: ## ⚙️ Setup repository
	@cog install-hook --all --overwrite

format: ## 🎨 Format code
	@fish_indent --write $(SOURCES) $(TESTS)

check: fmt-check syntax ## ✅ Run quality checks

test: ## 🧪 Run tests
	@fish scripts/run-tests.fish

security: ## 🔒 Run security checks
	@gitleaks dir --redact --verbose .
	@gitleaks git --redact --verbose .

# There is no registry: the git tag IS the release. CI owns tagging (cog bump
# on push to master); this target is the manual escape hatch and runs the same
# gates CI would before pushing anything users will fetch.
publish: check test security ## 🚀 Publish release tag
	@git push --follow-tags

build: ## 🧱 Run available build tasks
	@echo "Nothing to build: fisher installs fish plugins from source."

benchmark: ## ⏱️ Run benchmarks
	@echo "No benchmarks configured. fish ships no benchmark harness;"
	@echo "time a hot loop with a throwaway script if you need numbers."

docs: ## 📚 Generate docs
	@echo "Documentation lives in README.md and each function's --description."
	@fish -c 'for f in functions/*.fish; source $$f; end; functions -n | string split " "' 2>/dev/null || true

update: ## 🔄 Update dependencies
	@echo "No dependency manager: fishtape is vendored at tests/vendor/fishtape.fish."
	@echo "To bump it, replace that file and commit the reviewable diff."

clean: ## 🧹 Clean generated artifacts
	@echo "Nothing to clean: this repository generates no build artifacts."

version: ## 📦 Print package metadata
	@echo "$(PLUGIN) $$(git describe --tags --always --dirty 2>/dev/null || echo unreleased)"

smoke: ## 💨 Install via fisher into a throwaway HOME and load every function
	@fish scripts/smoke-test.fish

# Granular gates composed by `check`, deliberately kept out of `make help`,
# mirroring how template-go hides fmt-check/lint/vet.
#
# $(wildcard ...) rather than a raw glob: an unmatched literal glob reaching
# fish_indent errors with `Opening "conf.d/*.fish" failed` instead of no-opping.
fmt-check:
	@fish_indent --check $(SOURCES) $(TESTS)

syntax:
	@fish scripts/check-syntax.fish $(SOURCES) $(TESTS)
