MAKEFLAGS += --no-print-directory
.SILENT:
.DEFAULT_GOAL := help

PLUGIN := $(notdir $(CURDIR))

# Every fish file in the repository, discovered rather than enumerated, so a
# directory you add later (conf.d/, themes/, more scripts) is covered without
# editing this file. tests/vendor/ is excluded: it is third-party code committed
# verbatim and is not ours to reformat.
FISH_FILES := $(shell find . -name '*.fish' -not -path './tests/vendor/*' -not -path './.git/*' | sort)

.PHONY: help setup format check test security publish build benchmark docs update clean version
.PHONY: fmt-check syntax smoke

help: ## ❓ List available make targets
	@awk -F':.*##[ \t]*' '/^[A-Za-z0-9_.:-]+:.*##/ { printf "%-14s%s\n", $$1, $$2 }' $(MAKEFILE_LIST) | sort

setup: ## ⚙️ Setup repository
	@cog install-hook --all --overwrite

format: ## 🎨 Format code
	@fish_indent --write $(FISH_FILES)

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

update: ## 🔄 Update dependencies
	@echo "No dependency manager: fishtape is vendored at tests/vendor/fishtape.fish."
	@echo "To bump it, replace that file and commit the reviewable diff."

clean: ## 🧹 Clean generated artifacts
	@echo "Nothing to clean: this repository generates no build artifacts."

version: ## 📦 Print package metadata
	@echo "$(PLUGIN) $$(git describe --tags --always --dirty 2>/dev/null || echo unreleased)"

# Sources every .fish file it installs -- including any conf.d/ you add, whose
# top-level code runs. That is exactly what happens on a real `fisher install`,
# so this gate reproduces the user's experience rather than inventing a risk.
# HOME and XDG_CONFIG_HOME are redirected to a temporary directory; writes to
# absolute paths outside it are NOT contained. In CI the runner is ephemeral.
smoke: ## 💨 Install via fisher into a throwaway HOME and load every function
	@fish scripts/smoke-test.fish

# Granular gates composed by `check`, deliberately kept out of `make help`,
# mirroring how template-go hides fmt-check/lint/vet.
fmt-check:
	@fish_indent --check $(FISH_FILES)

# Per-file by necessity: `fish --no-execute` parses only its FIRST argument and
# cannot take a directory at all (`fish -n somedir` exits 127, "Is a directory").
syntax:
	@fish scripts/check-syntax.fish $(FISH_FILES)
