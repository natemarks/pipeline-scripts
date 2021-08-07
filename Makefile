# .PHONY: shellcheck static bump git_pull_ff_only clean-venv help
.DEFAULT_GOAL := help
VERSION := 0.0.0
COMMIT_HASH := $(shell git rev-parse --short HEAD)
CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
MAIN_BRANCH := main
BUMP_TYPE := patch

help:           ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


clean-venv:
	rm -rf .venv
	python3 -m venv .venv
	( \
       source .venv/bin/activate; \
       pip install --upgrade pip setuptools; \
    )

git_pull_ff_only: ## if there is a merge required, ail out
	git pull --ff-only

bump:  static clean-venv git_pull_ff_only ## bump version in main branch

ifeq ($(CURRENT_BRANCH), $(MAIN_BRANCH))
	( \
	   source .venv/bin/activate; \
	   pip install bump2version; \
	   bump2version $(BUMP_TYPE); \
	)
else
	@echo "UNABLE TO BUMP - not on Main branch"
	$(info Current Branch: $(CURRENT_BRANCH), main: $(MAIN_BRANCH))
endif


shellcheck: ## Run static code checks
	@echo Run shellcheck against scripts/
	shellcheck scripts/*.sh

static: shellcheck
