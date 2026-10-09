# Stable local entry points. Future CI calls these targets rather than duplicating commands.

PYTHON      ?= python3.13
VENV        ?= .venv
VENV_PY     := $(VENV)/bin/python
VENV_STAMP  := $(VENV)/.installed
DOCKER      ?= /usr/bin/docker
IMAGE       ?= maops-p5-app
TAG         ?= local
BUILD_ID    ?= local-dev
SMOKE_PORT  ?= 18080

.DEFAULT_GOAL := help
.PHONY: help venv test run image smoke validate clean

help: ## List available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

# Stamp file (not the interpreter) marks success, so a failed install is retried.
$(VENV_STAMP): pyproject.toml
	$(PYTHON) -m venv $(VENV)
	$(VENV_PY) -m pip install --quiet --upgrade pip
	$(VENV_PY) -m pip install --quiet -e '.[dev]'
	@touch $@

venv: $(VENV_STAMP) ## Create the repository-local virtualenv with dev dependencies

test: $(VENV_STAMP) ## Run the automated test suite
	$(VENV_PY) -m pytest

run: $(VENV_STAMP) ## Run the service locally on PORT (default 8080)
	APP_BUILD_ID=$(BUILD_ID) $(VENV_PY) -m maops_p5_app

image: ## Build the container image IMAGE:TAG
	$(DOCKER) build --build-arg APP_BUILD_ID=$(BUILD_ID) -t $(IMAGE):$(TAG) .

smoke: ## Run IMAGE:TAG and probe /healthz and /info, then remove the container
	DOCKER=$(DOCKER) ./scripts/smoke-test.sh $(IMAGE):$(TAG) $(SMOKE_PORT) $(BUILD_ID)

validate: test image smoke ## Full local validation: tests, image build, container smoke test

clean: ## Remove the virtualenv and Python caches
	rm -rf $(VENV) .pytest_cache
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
