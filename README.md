# MAOps P5 — GitHub Actions CI/CD Platform

P5 is about building reusable CI/CD capability. This repository currently contains the
**Day 1 foundation**: a deliberately small HTTP workload and a single CI workflow that tests,
builds and smoke-tests it. Nothing is published or deployed.

## Application

A Python 3.13 service using only the standard library (`http.server`), so it has no runtime
dependencies. `pytest` is the only development dependency.

| Endpoint       | Response                                                              |
| -------------- | --------------------------------------------------------------------- |
| `GET /healthz` | `{"status": "ok"}`                                                    |
| `GET /info`    | `{"service": "maops-p5-app", "version": "0.1.0", "build_id": "..."}`  |

Anything else returns 404 (unknown path) or 405 (a method other than GET).

| Variable       | Default     | Purpose                                         |
| -------------- | ----------- | ----------------------------------------------- |
| `APP_BUILD_ID` | `local-dev` | Source/build identity reported by `/info`       |
| `PORT`         | `8080`      | Listen port                                     |
| `HOST`         | `0.0.0.0`   | Listen address                                  |

Layout:

```
src/maops_p5_app/   package (server.py holds the routing and HTTP handler)
tests/              unit tests for routing plus in-process HTTP tests
scripts/            smoke-test.sh, which runs the container smoke test
Dockerfile          python:3.13-slim, non-root, APP_BUILD_ID build arg
Makefile            stable local commands
```

## Local validation

Requires Python 3.13, Docker and curl. Set `PYTHON` if `python3.13` is not on your `PATH`.

```sh
make test                      # create .venv (first run) and run pytest
make image BUILD_ID=$(git rev-parse --short HEAD)   # build maops-p5-app:local
make smoke BUILD_ID=<same id>  # run the container, probe /healthz and /info, remove it
make validate                  # test + image + smoke
make run                       # run locally on :8080
make clean                     # remove .venv and caches
```

The default Docker binary is `/usr/bin/docker`; override it with `DOCKER=...`.

## Continuous integration

`.github/workflows/ci.yml` runs on pull requests targeting `main` and on pushes to `main`:

- GitHub-hosted `ubuntu-24.04` runner, 15-minute job timeout, Python 3.13.
- Token permissions: `contents: read` only. Checkout does not persist credentials. No secrets.
- Steps call the Make interface: `make test`, `make image`, `make smoke`. Any failure fails the job.
- `BUILD_ID` is `github.sha` (the PR merge commit, or the pushed `main` commit); the smoke test
  checks `/info` reports it.
- pip downloads are cached by `actions/setup-python`, keyed on `pyproject.toml`.
- Superseded PR runs are cancelled; every `main` push is validated.
- The image is built and tested on the runner only. It is not pushed anywhere.

This is a demonstration workload. It is not production-ready.
