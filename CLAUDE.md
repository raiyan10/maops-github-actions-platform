# CLAUDE.md — MAOps P5

## Objective
P5 builds reusable CI/CD capability from a platform-engineering perspective. The application in
`src/` is a deliberately small workload; the pipeline platform is the project. Keep the app small.

## Working rules
- Architecture first: agree on the design before implementing a change.
- The user does all staging, commits, pushes, PRs, merges, tags and releases. Do not perform Git writes.
- Never modify released sibling MAOps projects. Work only inside this repository.
- Never use a self-hosted runner for untrusted PR workloads.
- Validate in small batches: change a little, run the relevant check, then continue.
- Preserve meaningful failures. Do not mask, skip, or `|| true` a failing check to get a pass. Report it.
- Do not claim production readiness.
- Use `/usr/bin/docker` for Docker operations.

## Stable validation commands
Run from the repo root. Set `PYTHON=` to a Python 3.13 interpreter if `python3.13` is not on PATH.
- `make test`: create `.venv` if needed and run pytest
- `make image [BUILD_ID=<id>]`: build `maops-p5-app:local`
- `make smoke [BUILD_ID=<id>]`: run the image, check `/healthz` and `/info` (build_id must match), remove the container
- `make validate`: test + image + smoke

## CI contract (Day 1)
- `.github/workflows/ci.yml`: `pull_request` → `main` and `push` → `main`; `ubuntu-24.04`; `contents: read`.
- CI calls `make test`, `make image`, `make smoke` with `BUILD_ID=${{ github.sha }}`. Change the Make
  targets, not the YAML, when validation logic changes.
- Actions are pinned to full commit SHAs. No publication, deployment or reusable workflows yet.
- Validate workflow changes with the `workflow-validation` skill.
